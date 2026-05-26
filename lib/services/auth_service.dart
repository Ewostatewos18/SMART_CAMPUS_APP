import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../models/user_role.dart';
import 'firestore_paths.dart';

/// Email/password auth + user profile in Firestore.
class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Stream<AppUser?> userProfileStream(String uid) {
    return _db.collection(FirestorePaths.users).doc(uid).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return AppUser.fromDoc(doc);
      },
    );
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  /// Students only — staff roles must be assigned by admin.
  Future<AppUser> registerStudent({
    required String name,
    required String email,
    required String password,
    String? department,
    String? studentId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final user = AppUser(
      userId: uid,
      name: name.trim(),
      email: email.trim(),
      role: UserRole.student,
      department: department?.trim(),
      studentId: studentId?.trim(),
      createdAt: DateTime.now(),
    );
    await _db.collection(FirestorePaths.users).doc(uid).set(user.toFirestore());

    try {
      await cred.user!.sendEmailVerification();
    } catch (_) {}

    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final profile = await getUserProfile(cred.user!.uid);
    if (profile == null) {
      throw StateError(
        'Account exists in Authentication but profile is missing in Firestore.',
      );
    }
    return profile;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? department,
    String? studentId,
    String? profileImageUrl,
    UserRole? role,
    String? sectorId,
    String? fcmToken,
  }) async {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (department != null) map['department'] = department;
    if (studentId != null) map['studentId'] = studentId;
    if (profileImageUrl != null) map['profileImageUrl'] = profileImageUrl;
    if (role != null) map['role'] = role.value;
    if (sectorId != null) map['sectorId'] = sectorId;
    if (fcmToken != null) map['fcmToken'] = fcmToken;
    if (map.isEmpty) return;
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
