import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/notification_model.dart';
import '../models/user_role.dart';
import 'firestore_paths.dart';

/// Persists in-app notifications in Firestore + optional FCM hooks.
class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _db;
  final Uuid _uuid;

  Future<void> notifyUser({
    required String userId,
    required String message,
    String type = 'general',
  }) async {
    final id = _uuid.v4();
    final n = AppNotification(
      notificationId: id,
      userId: userId,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
      type: type,
    );
    await _db.collection(FirestorePaths.notifications).doc(id).set(
          n.toFirestore(),
        );
  }

  Future<void> notifySectorOfficers({
    required String sectorId,
    required String message,
    String type = 'general',
  }) async {
    final officers = await _db
        .collection(FirestorePaths.users)
        .where('role', isEqualTo: UserRole.sectorOfficer.value)
        .where('sectorId', isEqualTo: sectorId)
        .get();

    for (final doc in officers.docs) {
      await notifyUser(userId: doc.id, message: message, type: type);
    }
  }

  Stream<List<AppNotification>> streamForUser(String userId) {
    return _db
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
      (snap) {
        final list = snap.docs
            .map(
              (d) => AppNotification.fromFirestore(d.data(), d.id),
            )
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
          );
        return list;
      },
    );
  }

  Future<void> markRead(String notificationId) async {
    await _db
        .collection(FirestorePaths.notifications)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllRead(String userId) async {
    final snap = await _db
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
