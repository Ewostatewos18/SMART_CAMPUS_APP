import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/notification_model.dart';
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

  /// Push a row into `notifications` for the given user.
  Future<void> notifyUser({
    required String userId,
    required String message,
  }) async {
    final id = _uuid.v4();
    final n = AppNotification(
      notificationId: id,
      userId: userId,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
    );
    await _db.collection(FirestorePaths.notifications).doc(id).set(
          n.toFirestore(),
        );
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
              (d) =>
                  AppNotification.fromFirestore(d.data(), d.id),
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
}
