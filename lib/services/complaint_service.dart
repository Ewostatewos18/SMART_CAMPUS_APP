import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/services/smart_analysis_service.dart';
import '../models/complaint_model.dart';
import '../models/complaint_status.dart';
import '../models/complaint_type.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'firestore_paths.dart';
import 'notification_service.dart';

/// CRUD and streams for complaints, responses, and escalation.
class ComplaintService {
  ComplaintService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    SmartAnalysisService? smartAnalysis,
    Uuid? uuid,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _notifications = notificationService ?? NotificationService(),
        _smart = smartAnalysis ?? const SmartAnalysisService(),
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _db;
  final NotificationService _notifications;
  final SmartAnalysisService _smart;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _complaints =>
      _db.collection(FirestorePaths.complaints);

  CollectionReference<Map<String, dynamic>> get _responses =>
      _db.collection(FirestorePaths.responses);

  CollectionReference<Map<String, dynamic>> get _escalationLogs =>
      _db.collection(FirestorePaths.escalationLogs);

  Future<String> submitComplaint({
    required String studentId,
    required String title,
    required String description,
    required String sectorId,
    ComplaintType type = ComplaintType.complaint,
    ComplaintPriority priority = ComplaintPriority.medium,
    String? location,
    bool isAnonymous = false,
    List<String> attachmentUrls = const [],
  }) async {
    final analysis = _smart.analyze(
      title: title,
      description: description,
      sectorId: sectorId,
    );

    if (analysis.isLikelySpam) {
      throw ArgumentError(
        'Your submission looks incomplete or spam-like. Please add more detail.',
      );
    }

    final existing = await _findDuplicate(analysis.duplicateFingerprint);
    if (existing != null) {
      throw ArgumentError(
        'A similar complaint was already submitted. Check your existing tickets.',
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final effectivePriority = priority == ComplaintPriority.medium
        ? analysis.suggestedPriority
        : priority;
    final effectiveType =
        type == ComplaintType.complaint ? analysis.suggestedType : type;

    final complaint = Complaint(
      complaintId: id,
      title: title.trim(),
      description: description.trim(),
      studentId: studentId,
      sectorId: sectorId,
      status: ComplaintStatus.submitted,
      createdAt: now,
      updatedAt: now,
      type: effectiveType,
      priority: effectivePriority,
      location: location?.trim(),
      isAnonymous: isAnonymous,
      category: analysis.suggestedCategory,
      tags: analysis.suggestedTags,
      sentimentScore: analysis.sentimentScore,
      attachmentUrls: attachmentUrls,
    );

    await _complaints.doc(id).set({
      ...complaint.toFirestore(),
      'duplicateFingerprint': analysis.duplicateFingerprint,
    });

    await _notifications.notifyUser(
      userId: studentId,
      message:
          'Your ${effectiveType.displayName.toLowerCase()} "${title.trim()}" was submitted successfully.',
      type: 'complaint_submitted',
    );

    if (effectivePriority == ComplaintPriority.emergency ||
        effectivePriority == ComplaintPriority.high) {
      await _notifications.notifySectorOfficers(
        sectorId: sectorId,
        message:
            'High-priority ${effectiveType.displayName.toLowerCase()}: "${title.trim()}"',
        type: 'priority_alert',
      );
    }

    return id;
  }

  Future<String?> _findDuplicate(String fingerprint) async {
    final snap = await _complaints
        .where('duplicateFingerprint', isEqualTo: fingerprint)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Stream<List<Complaint>> streamForStudent(String studentId) {
    return _complaints.where('studentId', isEqualTo: studentId).snapshots().map(
      (snap) => _sortNewest(
        snap.docs.map((d) => Complaint.fromDoc(d)).toList(),
      ),
    );
  }

  Stream<List<Complaint>> streamForSector(String sectorId) {
    return _complaints.where('sectorId', isEqualTo: sectorId).snapshots().map(
      (snap) => _sortNewest(
        snap.docs.map((d) => Complaint.fromDoc(d)).toList(),
      ),
    );
  }

  Stream<List<Complaint>> streamAll() {
    return _complaints.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => Complaint.fromDoc(d)).toList(),
        );
  }

  Stream<List<Complaint>> streamEscalated() {
    return _complaints
        .where('status', isEqualTo: ComplaintStatus.escalated.value)
        .snapshots()
        .map(
          (snap) => _sortNewest(
            snap.docs.map((d) => Complaint.fromDoc(d)).toList(),
          ),
        );
  }

  Stream<List<Complaint>> streamFiltered({
    ComplaintStatus? status,
    String? sectorId,
    ComplaintPriority? priority,
    ComplaintType? type,
  }) {
    Query<Map<String, dynamic>> query = _complaints;
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }
    if (sectorId != null) {
      query = query.where('sectorId', isEqualTo: sectorId);
    }
    if (priority != null) {
      query = query.where('priority', isEqualTo: priority.value);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.value);
    }
    return query.snapshots().map(
          (snap) => _sortNewest(
            snap.docs.map((d) => Complaint.fromDoc(d)).toList(),
          ),
        );
  }

  List<Complaint> _sortNewest(List<Complaint> list) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Complaint?> getComplaint(String complaintId) async {
    final doc = await _complaints.doc(complaintId).get();
    if (!doc.exists) return null;
    return Complaint.fromDoc(doc);
  }

  Stream<Complaint?> streamComplaint(String complaintId) {
    return _complaints.doc(complaintId).snapshots().map(
          (d) => d.exists ? Complaint.fromDoc(d) : null,
        );
  }

  Future<Complaint?> getComplaintWithStudentName(String complaintId) async {
    final c = await getComplaint(complaintId);
    if (c == null) return null;
    final userDoc =
        await _db.collection(FirestorePaths.users).doc(c.studentId).get();
    final name = userDoc.data()?['name'] as String?;
    return c.copyWith(studentName: name);
  }

  Stream<List<Complaint>> streamWithStudentNames(
    Stream<List<Complaint>> source,
  ) async* {
    await for (final list in source) {
      final enriched = await Future.wait(
        list.map((c) async {
          if (c.studentName != null) return c;
          final doc =
              await _db.collection(FirestorePaths.users).doc(c.studentId).get();
          final name = doc.data()?['name'] as String?;
          return c.copyWith(studentName: name);
        }),
      );
      yield enriched;
    }
  }

  Stream<List<ComplaintResponse>> streamResponses(String complaintId) {
    return _responses
        .where('complaintId', isEqualTo: complaintId)
        .snapshots()
        .map(
      (snap) {
        final list = snap.docs
            .map((d) => ComplaintResponse.fromFirestore(d.data(), d.id))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return list;
      },
    );
  }

  Future<void> addResponse({
    required Complaint complaint,
    required AppUser author,
    required String message,
    bool fromExecutive = false,
  }) async {
    final id = _uuid.v4();
    final r = ComplaintResponse(
      responseId: id,
      complaintId: complaint.complaintId,
      officerId: author.userId,
      message: message.trim(),
      createdAt: DateTime.now(),
      authorName: author.name,
      authorRole: author.role.displayName,
    );
    await _responses.doc(id).set(r.toFirestore());

    final label = fromExecutive ? author.role.displayName : 'Sector officer';
    await _notifications.notifyUser(
      userId: complaint.studentId,
      message:
          '$label replied to "${complaint.title}": ${message.length > 80 ? '${message.substring(0, 80)}…' : message}',
      type: 'response',
    );
  }

  Future<void> updateComplaintStatus({
    required Complaint complaint,
    required ComplaintStatus newStatus,
    required AppUser actor,
    String? note,
  }) async {
    final now = DateTime.now();
    final updates = <String, dynamic>{
      'status': newStatus.value,
      'updatedAt': Timestamp.fromDate(now),
    };

    if (newStatus == ComplaintStatus.escalated) {
      updates['escalatedAt'] = Timestamp.fromDate(now);
      await _logEscalation(complaint, actor, note);
    }

    if (newStatus == ComplaintStatus.assigned &&
        complaint.status == ComplaintStatus.submitted) {
      // Auto-assign when officer picks up
    }

    await _complaints.doc(complaint.complaintId).update(updates);

    var body =
        'Status of "${complaint.title}" is now ${newStatus.displayName}.';
    if (newStatus == ComplaintStatus.escalated) {
      body = 'Complaint "${complaint.title}" was escalated by ${actor.name}.';
      await _notifyExecutives(complaint);
    }

    await _notifications.notifyUser(
      userId: complaint.studentId,
      message: body,
      type: 'status_change',
    );
  }

  Future<void> _logEscalation(
    Complaint complaint,
    AppUser actor,
    String? note,
  ) async {
    await _escalationLogs.doc(_uuid.v4()).set({
      'complaintId': complaint.complaintId,
      'fromStatus': complaint.status.value,
      'toStatus': ComplaintStatus.escalated.value,
      'actorId': actor.userId,
      'actorName': actor.name,
      'sectorId': complaint.sectorId,
      'note': note,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> _notifyExecutives(Complaint complaint) async {
    final execs = await _db
        .collection(FirestorePaths.users)
        .where('role', whereIn: ['vicePresident', 'president'])
        .get();
    for (final doc in execs.docs) {
      await _notifications.notifyUser(
        userId: doc.id,
        message:
            'Escalated: "${complaint.title}" from ${complaint.sectorId} sector.',
        type: 'escalation',
      );
    }
  }

  Future<void> rateSatisfaction({
    required Complaint complaint,
    required SatisfactionRating rating,
  }) async {
    await _complaints.doc(complaint.complaintId).update({
      'satisfaction': rating.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> reopenComplaint({
    required Complaint complaint,
    required String reason,
  }) async {
    await _complaints.doc(complaint.complaintId).update({
      'status': ComplaintStatus.inProgress.value,
      'reopenCount': complaint.reopenCount + 1,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'satisfaction': SatisfactionRating.none.value,
    });
    await _notifications.notifySectorOfficers(
      sectorId: complaint.sectorId,
      message: 'Complaint reopened: "${complaint.title}" — $reason',
      type: 'reopen',
    );
  }

  /// Check unresolved complaints for auto-escalation (call from admin/cron).
  Future<int> runAutoEscalationCheck() async {
    final threshold = DateTime.now().subtract(
      const Duration(days: AppConstants.escalationDaysThreshold),
    );
    final snap = await _complaints
        .where('status', whereIn: [
          ComplaintStatus.submitted.value,
          ComplaintStatus.inProgress.value,
          ComplaintStatus.inReview.value,
        ])
        .get();

    var count = 0;
    for (final doc in snap.docs) {
      final c = Complaint.fromDoc(doc);
      if (c.createdAt.isAfter(threshold)) continue;
      if (c.priority == ComplaintPriority.low) continue;

      await _complaints.doc(c.complaintId).update({
        'status': ComplaintStatus.escalated.value,
        'escalatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      await _logEscalation(
        c,
        const AppUser(
          userId: 'system',
          name: 'Auto-Escalation',
          email: '',
          role: UserRole.admin,
        ),
        'Exceeded ${AppConstants.escalationDaysThreshold}-day threshold',
      );
      count++;
    }
    return count;
  }
}
