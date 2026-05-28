import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/account_status.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'firestore_paths.dart';

/// Admin: list and update user profiles.
class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<AppUser>> streamAllUsers() {
    return _db.collection(FirestorePaths.users).snapshots().map(
          (snap) => snap.docs.map(AppUser.fromDoc).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
        );
  }

  Future<void> updateUserRole({
    required String userId,
    required UserRole role,
    String? sectorId,
  }) async {
    final data = <String, dynamic>{
      'role': role.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (role == UserRole.sectorOfficer) {
      if (sectorId == null || sectorId.isEmpty) {
        throw ArgumentError('Sector is required for sector officers.');
      }
      data['sectorId'] = sectorId;
    } else {
      data['sectorId'] = FieldValue.delete();
    }
    await _db.collection(FirestorePaths.users).doc(userId).update(data);
  }

  Future<void> updateAccountStatus({
    required String userId,
    required AccountStatus status,
  }) async {
    await _db.collection(FirestorePaths.users).doc(userId).update({
      'accountStatus': status.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<AppUser>> streamPendingUsers() {
    return _db
        .collection(FirestorePaths.users)
        .where('accountStatus', isEqualTo: AccountStatus.pending.value)
        .snapshots()
        .map(
          (snap) => snap.docs.map(AppUser.fromDoc).toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }
}
