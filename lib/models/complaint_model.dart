import 'package:cloud_firestore/cloud_firestore.dart';

import 'complaint_status.dart';

/// Maps to the `complaints` collection.
class Complaint {
  const Complaint({
    required this.complaintId,
    required this.title,
    required this.description,
    required this.studentId,
    required this.sectorId,
    required this.status,
    required this.createdAt,
    this.studentName,
  });

  final String complaintId;
  final String title;
  final String description;
  final String studentId;
  final String sectorId;
  final ComplaintStatus status;
  final DateTime createdAt;
  final String? studentName;

  Map<String, dynamic> toFirestore() {
    return {
      'complaintId': complaintId,
      'title': title,
      'description': description,
      'studentId': studentId,
      'sectorId': sectorId,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Complaint.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    String? studentName,
  }) {
    final raw = data['createdAt'];
    DateTime created;
    if (raw is Timestamp) {
      created = raw.toDate();
    } else {
      created = DateTime.now();
    }
    return Complaint(
      complaintId: data['complaintId'] as String? ?? id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      sectorId: data['sectorId'] as String? ?? '',
      status: ComplaintStatus.fromString(data['status'] as String?),
      createdAt: created,
      studentName: studentName,
    );
  }

  factory Complaint.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? studentName,
  }) {
    return Complaint.fromFirestore(
      doc.data() ?? {},
      doc.id,
      studentName: studentName,
    );
  }

  Complaint copyWith({
    ComplaintStatus? status,
    String? studentName,
  }) {
    return Complaint(
      complaintId: complaintId,
      title: title,
      description: description,
      studentId: studentId,
      sectorId: sectorId,
      status: status ?? this.status,
      createdAt: createdAt,
      studentName: studentName ?? this.studentName,
    );
  }
}
