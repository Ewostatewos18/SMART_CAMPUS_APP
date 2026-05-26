import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps to the `responses` collection.
class ComplaintResponse {
  const ComplaintResponse({
    required this.responseId,
    required this.complaintId,
    required this.officerId,
    required this.message,
    required this.createdAt,
    this.authorName,
    this.authorRole,
    this.authorLabel,
  });

  final String responseId;
  final String complaintId;
  final String officerId;
  final String message;
  final DateTime createdAt;
  final String? authorName;
  final String? authorRole;
  final String? authorLabel;

  String get displayAuthor =>
      authorLabel ?? authorName ?? (authorRole != null ? authorRole! : 'Staff');

  Map<String, dynamic> toFirestore() {
    return {
      'responseId': responseId,
      'complaintId': complaintId,
      'officerId': officerId,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      if (authorName != null) 'authorName': authorName,
      if (authorRole != null) 'authorRole': authorRole,
    };
  }

  factory ComplaintResponse.fromFirestore(Map<String, dynamic> data, String id) {
    final raw = data['createdAt'];
    DateTime created;
    if (raw is Timestamp) {
      created = raw.toDate();
    } else {
      created = DateTime.now();
    }
    return ComplaintResponse(
      responseId: data['responseId'] as String? ?? id,
      complaintId: data['complaintId'] as String? ?? '',
      officerId: data['officerId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: created,
      authorName: data['authorName'] as String?,
      authorRole: data['authorRole'] as String?,
    );
  }
}
