import 'package:cloud_firestore/cloud_firestore.dart';

import 'complaint_status.dart';
import 'complaint_type.dart';

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
    this.type = ComplaintType.complaint,
    this.priority = ComplaintPriority.medium,
    this.location,
    this.isAnonymous = false,
    this.category,
    this.tags = const [],
    this.sentimentScore,
    this.attachmentUrls = const [],
    this.updatedAt,
    this.escalatedAt,
    this.satisfaction = SatisfactionRating.none,
    this.reopenCount = 0,
  });

  final String complaintId;
  final String title;
  final String description;
  final String studentId;
  final String sectorId;
  final ComplaintStatus status;
  final DateTime createdAt;
  final String? studentName;
  final ComplaintType type;
  final ComplaintPriority priority;
  final String? location;
  final bool isAnonymous;
  final String? category;
  final List<String> tags;
  final double? sentimentScore;
  final List<String> attachmentUrls;
  final DateTime? updatedAt;
  final DateTime? escalatedAt;
  final SatisfactionRating satisfaction;
  final int reopenCount;

  Map<String, dynamic> toFirestore() {
    return {
      'complaintId': complaintId,
      'title': title,
      'description': description,
      'studentId': studentId,
      'sectorId': sectorId,
      'status': status.value,
      'type': type.value,
      'priority': priority.value,
      'isAnonymous': isAnonymous,
      'tags': tags,
      'attachmentUrls': attachmentUrls,
      'satisfaction': satisfaction.value,
      'reopenCount': reopenCount,
      'createdAt': Timestamp.fromDate(createdAt),
      if (location != null) 'location': location,
      if (category != null) 'category': category,
      if (sentimentScore != null) 'sentimentScore': sentimentScore,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (escalatedAt != null) 'escalatedAt': Timestamp.fromDate(escalatedAt!),
    };
  }

  factory Complaint.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    String? studentName,
  }) {
    return Complaint(
      complaintId: data['complaintId'] as String? ?? id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      sectorId: data['sectorId'] as String? ?? '',
      status: ComplaintStatus.fromString(data['status'] as String?),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      studentName: studentName,
      type: ComplaintType.fromString(data['type'] as String?),
      priority: ComplaintPriority.fromString(data['priority'] as String?),
      location: data['location'] as String?,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      category: data['category'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      sentimentScore: (data['sentimentScore'] as num?)?.toDouble(),
      attachmentUrls:
          (data['attachmentUrls'] as List<dynamic>?)?.cast<String>() ??
              const [],
      updatedAt: _parseDate(data['updatedAt']),
      escalatedAt: _parseDate(data['escalatedAt']),
      satisfaction:
          SatisfactionRating.fromString(data['satisfaction'] as String?),
      reopenCount: data['reopenCount'] as int? ?? 0,
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
    DateTime? updatedAt,
    DateTime? escalatedAt,
    SatisfactionRating? satisfaction,
    int? reopenCount,
    List<String>? tags,
    double? sentimentScore,
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
      type: type,
      priority: priority,
      location: location,
      isAnonymous: isAnonymous,
      category: category,
      tags: tags ?? this.tags,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      attachmentUrls: attachmentUrls,
      updatedAt: updatedAt ?? this.updatedAt,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      satisfaction: satisfaction ?? this.satisfaction,
      reopenCount: reopenCount ?? this.reopenCount,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    return null;
  }
}
