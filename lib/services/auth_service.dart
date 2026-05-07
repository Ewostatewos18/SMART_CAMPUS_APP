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

  /// Watch the signed-in user's profile document.
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

  /// Creates Auth user and `users/{uid}` document in a batch.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? sectorId,
  }) async {
    if (role == UserRole.sectorOfficer &&
        (sectorId == null || sectorId.isEmpty)) {
      throw ArgumentError('Sector officers must have a sector assigned.');
    }
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final user = AppUser(
      userId: uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
      sectorId: role == UserRole.sectorOfficer ? sectorId : null,
    );
    await _db.collection(FirestorePaths.users).doc(uid).set(user.toFirestore());
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

  Future<void> updateProfile({
    required String uid,
    String? name,
    UserRole? role,
    String? sectorId,
  }) async {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (role != null) map['role'] = role.value;
    if (sectorId != null) map['sectorId'] = sectorId;
    if (map.isEmpty) return;
    await _db.collection(FirestorePaths.users).doc(uid).update(map);
  }
}
