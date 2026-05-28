import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/services/firestore_bootstrap.dart';
import '../core/utils/bdu_email_validator.dart';
import '../features/auth/models/registration_result.dart';
import '../firebase_options.dart';
import '../models/account_status.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'firestore_paths.dart';

/// Email/password auth + Firestore profiles with web persistence.
class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance {
    _configurePersistence();
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const _secondaryAppName = 'SmartCampusAdminProvisioner';

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> _configurePersistence() async {
    if (kIsWeb) {
      try {
        await _auth.setPersistence(Persistence.LOCAL);
      } catch (e) {
        debugPrint('Auth persistence: $e');
      }
    }
  }

  /// Normalizes login email (BDU students + lowercase for staff).
  static String normalizeLoginEmail(String raw) {
    final trimmed = raw.trim();
    final bdu = BduEmailValidator.normalize(trimmed);
    if (BduEmailValidator.isValid(bdu)) return bdu;
    return trimmed.toLowerCase();
  }

  Stream<AppUser?> userProfileStream(String uid) {
    return _db.collection(FirestorePaths.users).doc(uid).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return AppUser.fromDoc(doc);
      },
    );
  }

  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final ref = _db.collection(FirestorePaths.users).doc(uid);
      final doc = await FirestoreBootstrap.getDocument(ref);
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw StateError(FirestoreBootstrap.permissionMessage());
      }
      if (e.code == 'unavailable' ||
          (e.message ?? '').toLowerCase().contains('offline')) {
        throw StateError(FirestoreBootstrap.offlineMessage());
      }
      rethrow;
    }
  }

  /// Finds a profile saved under a wrong document id (same email).
  Future<AppUser?> _findProfileByEmail(String email) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.users)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return AppUser.fromDoc(snap.docs.first);
    } on FirebaseException catch (e) {
      debugPrint('findProfileByEmail: ${e.code}');
      return null;
    }
  }

  /// Ensures users/{uid} exists after Auth sign-in (fixes orphan / wrong-id profiles).
  Future<AppUser> resolveProfileForLogin(User fbUser) async {
    final uid = fbUser.uid;
    final email = normalizeLoginEmail(fbUser.email ?? '');

    AppUser? profile = await getUserProfile(uid);

    if (profile == null && email.isNotEmpty) {
      final byEmail = await _findProfileByEmail(email);
      if (byEmail != null) {
        final now = DateTime.now();
        final repaired = byEmail.copyWith(
          email: email,
          accountStatus: byEmail.role == UserRole.student
              ? AccountStatus.approved
              : byEmail.accountStatus,
          updatedAt: now,
        );
        final migrated = AppUser(
          userId: uid,
          name: repaired.name,
          email: email,
          role: repaired.role,
          sectorId: repaired.sectorId,
          department: repaired.department,
          studentId: repaired.studentId,
          year: repaired.year,
          section: repaired.section,
          phone: repaired.phone,
          position: repaired.position,
          officeInfo: repaired.officeInfo,
          profileImageUrl: repaired.profileImageUrl,
          isActive: true,
          accountStatus: repaired.role == UserRole.student
              ? AccountStatus.approved
              : repaired.accountStatus,
          createdAt: repaired.createdAt ?? now,
          updatedAt: now,
        );
        await _db
            .collection(FirestorePaths.users)
            .doc(uid)
            .set(migrated.toFirestore());
        profile = migrated;
        debugPrint('Repaired profile: copied email match to users/$uid');
      }
    }

    if (profile == null) {
      final now = DateTime.now();
      final isStudent = BduEmailValidator.isValid(email);
      final studentId = BduEmailValidator.extractStudentId(email);
      profile = AppUser(
        userId: uid,
        name: fbUser.displayName?.trim().isNotEmpty == true
            ? fbUser.displayName!.trim()
            : (studentId != null ? 'Student $studentId' : 'Smart Campus User'),
        email: email.isNotEmpty ? email : (fbUser.email ?? ''),
        role: isStudent ? UserRole.student : UserRole.student,
        studentId: studentId,
        isActive: true,
        accountStatus: AccountStatus.approved,
        createdAt: now,
        updatedAt: now,
      );
      await _db
          .collection(FirestorePaths.users)
          .doc(uid)
          .set(profile.toFirestore());
      debugPrint('Created missing profile at users/$uid');
    }

    if ((profile.role == UserRole.student || profile.role == UserRole.admin) &&
        profile.accountStatus == AccountStatus.pending) {
      await _db.collection(FirestorePaths.users).doc(uid).update({
        'accountStatus': AccountStatus.approved.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      profile = profile.copyWith(accountStatus: AccountStatus.approved);
    }

    return profile;
  }

  void _ensureCanSignIn(AppUser profile) {
    if (!profile.isActive) {
      throw StateError(
        'This account has been deactivated. Contact an administrator.',
      );
    }
    switch (profile.accountStatus) {
      case AccountStatus.pending:
        throw StateError(
          profile.role == UserRole.admin
              ? 'Your admin account is not active yet. Try logging in again.'
              : 'Your account is pending approval. An administrator will activate it soon.',
        );
      case AccountStatus.rejected:
        throw StateError(
          'Your registration was rejected. Contact the Student Union.',
        );
      case AccountStatus.approved:
        break;
    }
  }

  Future<void> _writeUserProfile({
    required UserRole role,
    required String uid,
    required AppUser user,
    required DateTime now,
  }) async {
    final userRef = _db.collection(FirestorePaths.users).doc(uid);

    await FirestoreBootstrap.configure();

    // Write profile directly — no pre-read (reads often fail with "client is offline" on web).
    await userRef.set(user.toFirestore());

    if (role == UserRole.student) {
      final sid = user.studentId!;
      final sidRef = _db.collection(FirestorePaths.studentIds).doc(sid);
      try {
        await sidRef.set({
          'userId': uid,
          'createdAt': Timestamp.fromDate(now),
        });
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied' || e.code == 'already-exists') {
          debugPrint('student_ids skipped: ${e.code}');
        } else if (e.code == 'unavailable' ||
            (e.message ?? '').toLowerCase().contains('offline')) {
          debugPrint('student_ids skipped (offline); profile saved.');
        } else {
          rethrow;
        }
      }
    }
  }

  /// Self-service registration. Signs out immediately so user must log in.
  Future<RegistrationResult> registerAccount({
    required UserRole role,
    required String name,
    required String email,
    required String password,
    String? phone,
    String? studentId,
    String? department,
    String? year,
    String? section,
    String? sectorId,
    String? position,
    String? officeInfo,
    String? adminCode,
    String? profileImageUrl,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Full name is required.');
    }

    late final String normalizedEmail;
    late final AccountStatus status;

    if (role == UserRole.student) {
      normalizedEmail = BduEmailValidator.normalize(email);
      if (!BduEmailValidator.isValid(normalizedEmail)) {
        throw ArgumentError(
          'Use your BDU email (e.g. ${AppConstants.studentEmailExample}).',
        );
      }
      final sid = (studentId ?? BduEmailValidator.extractStudentId(normalizedEmail))
          ?.trim();
      if (sid == null || sid.isEmpty) {
        throw ArgumentError('Student ID is required.');
      }
      status = AccountStatus.approved;
    } else {
      normalizedEmail = email.trim().toLowerCase();
      if (!normalizedEmail.contains('@')) {
        throw ArgumentError('Enter a valid email address.');
      }
      if (role == UserRole.admin) {
        if (adminCode?.trim() != AppConstants.adminRegistrationCode) {
          throw ArgumentError('Invalid administrator registration code.');
        }
      }
      if (role == UserRole.sectorOfficer &&
          (sectorId == null || sectorId.isEmpty)) {
        throw ArgumentError('Select an assigned sector.');
      }
      // Admin verified with registration code — can sign in immediately.
      status = role == UserRole.admin
          ? AccountStatus.approved
          : AccountStatus.pending;
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final uid = cred.user!.uid;
    final now = DateTime.now();

    final user = AppUser(
      userId: uid,
      name: trimmedName,
      email: normalizedEmail,
      role: role,
      phone: phone?.trim(),
      department: department?.trim(),
      studentId: role == UserRole.student
          ? (studentId ?? BduEmailValidator.extractStudentId(normalizedEmail))
              ?.trim()
          : null,
      year: year?.trim(),
      section: section?.trim(),
      sectorId: role == UserRole.sectorOfficer ? sectorId : null,
      position: position?.trim(),
      officeInfo: officeInfo?.trim(),
      profileImageUrl: profileImageUrl,
      isActive: true,
      accountStatus: status,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _writeUserProfile(
        role: role,
        uid: uid,
        user: user,
        now: now,
      );
      try {
        await cred.user!.sendEmailVerification();
      } catch (_) {}
    } on FirebaseException catch (e) {
      await cred.user?.delete();
      if (e.code == 'permission-denied') {
        throw StateError(
          'Could not save your profile. Deploy Firestore rules: '
          'firebase deploy --only firestore:rules',
        );
      }
      if (e.code == 'unavailable' ||
          (e.message ?? '').toLowerCase().contains('offline')) {
        throw StateError(FirestoreBootstrap.offlineMessage());
      }
      rethrow;
    } catch (e) {
      await cred.user?.delete();
      rethrow;
    }

    await _auth.signOut();

    return RegistrationResult(
      email: normalizedEmail,
      role: role,
      accountStatus: status,
    );
  }

  /// Admin creates staff accounts without signing out (secondary Firebase app).
  Future<AppUser> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? sectorId,
  }) async {
    if (role == UserRole.student) {
      throw ArgumentError('Use student registration for students.');
    }
    if (role == UserRole.sectorOfficer &&
        (sectorId == null || sectorId.isEmpty)) {
      throw ArgumentError('Sector officers require a sector.');
    }

    FirebaseApp? secondaryApp;
    try {
      secondaryApp = Firebase.app(_secondaryAppName);
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: _secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final now = DateTime.now();

    final user = AppUser(
      userId: uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
      sectorId: role == UserRole.sectorOfficer ? sectorId : null,
      isActive: true,
      accountStatus: AccountStatus.approved,
      createdAt: now,
      updatedAt: now,
    );

    await _db.collection(FirestorePaths.users).doc(uid).set(user.toFirestore());
    await secondaryAuth.signOut();
    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = normalizeLoginEmail(email);

    final cred = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    await cred.user?.reload();
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      throw StateError('Sign-in succeeded but session was not restored.');
    }

    final profile = await resolveProfileForLogin(fbUser);

    try {
      _ensureCanSignIn(profile);
    } catch (e) {
      await signOut();
      rethrow;
    }

    return profile;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(
      email: normalizeLoginEmail(email),
    );
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? department,
    String? studentId,
    String? year,
    String? section,
    String? profileImageUrl,
    UserRole? role,
    String? sectorId,
    String? fcmToken,
    bool? isActive,
    AccountStatus? accountStatus,
  }) async {
    final map = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (name != null) {
      map['name'] = name;
      map['fullName'] = name;
    }
    if (department != null) map['department'] = department;
    if (studentId != null) map['studentId'] = studentId;
    if (year != null) map['year'] = year;
    if (section != null) map['section'] = section;
    if (profileImageUrl != null) {
      map['profileImageUrl'] = profileImageUrl;
      map['photoUrl'] = profileImageUrl;
    }
    if (role != null) map['role'] = role.value;
    if (sectorId != null) map['sectorId'] = sectorId;
    if (fcmToken != null) map['fcmToken'] = fcmToken;
    if (isActive != null) map['isActive'] = isActive;
    if (accountStatus != null) map['accountStatus'] = accountStatus.value;
    await _db.collection(FirestorePaths.users).doc(uid).update(map);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('Not signed in.');
    }
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }
}
