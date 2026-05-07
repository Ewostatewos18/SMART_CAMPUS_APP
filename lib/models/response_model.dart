import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps to the `responses` collection.
class ComplaintResponse {
  const ComplaintResponse({
    required this.responseId,
    required this.complaintId,
    required this.officerId,
    required this.message,
    required this.createdAt,
    this.authorLabel,
  });

  final String responseId;
  final String complaintId;
  final String officerId;
  final String message;
  final DateTime createdAt;
  final String? authorLabel;

  Map<String, dynamic> toFirestore() {
    return {
      'responseId': responseId,
      'complaintId': complaintId,
      'officerId': officerId,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
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
    );
  }

  ComplaintResponse copyWith({String? authorLabel}) {
    return ComplaintResponse(
      responseId: responseId,
      complaintId: complaintId,
      officerId: officerId,
      message: message,
      createdAt: createdAt,
      authorLabel: authorLabel ?? this.authorLabel,
    );
  }
}
