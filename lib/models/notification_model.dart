import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps to the `notifications` collection.
class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.userId,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.type = 'general',
  });

  final String notificationId;
  final String userId;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final String type;

  Map<String, dynamic> toFirestore() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'message': message,
      'isRead': isRead,
      'type': type,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    final raw = data['createdAt'];
    DateTime? created;
    if (raw is Timestamp) {
      created = raw.toDate();
    }
    return AppNotification(
      notificationId: data['notificationId'] as String? ?? id,
      userId: data['userId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: created,
      type: data['type'] as String? ?? 'general',
    );
  }
}
