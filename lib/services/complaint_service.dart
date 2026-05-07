import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/complaint_model.dart';
import '../models/complaint_status.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import 'firestore_paths.dart';
import 'notification_service.dart';

/// CRUD and streams for complaints and responses.
class ComplaintService {
  ComplaintService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    Uuid? uuid,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _notifications = notificationService ?? NotificationService(),
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _db;
  final NotificationService _notifications;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _complaints =>
      _db.collection(FirestorePaths.complaints);

  CollectionReference<Map<String, dynamic>> get _responses =>
      _db.collection(FirestorePaths.responses);

  /// Student submits a new complaint.
  Future<String> submitComplaint({
    required String studentId,
    required String title,
    required String description,
    required String sectorId,
  }) async {
    final id = _uuid.v4();
    final complaint = Complaint(
      complaintId: id,
      title: title.trim(),
      description: description.trim(),
      studentId: studentId,
      sectorId: sectorId,
      status: ComplaintStatus.submitted,
      createdAt: DateTime.now(),
    );
    await _complaints.doc(id).set(complaint.toFirestore());
    return id;
  }

  /// Real-time list for one student (sorted client-side to avoid composite indexes).
  Stream<List<Complaint>> streamForStudent(String studentId) {
    return _complaints.where('studentId', isEqualTo: studentId).snapshots().map(
          (snap) {
        final list = snap.docs
            .map((d) => Complaint.fromDoc(d))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
        );
  }

  /// Officer: complaints for a sector.
  Stream<List<Complaint>> streamForSector(String sectorId) {
    return _complaints.where('sectorId', isEqualTo: sectorId).snapshots().map(
          (snap) {
        final list = snap.docs
            .map((d) => Complaint.fromDoc(d))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
        );
  }

  /// Admin: all complaints (newest first server-side when possible).
  Stream<List<Complaint>> streamAll() {
    return _complaints
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Complaint.fromDoc(d)).toList(),
        );
  }

  /// VP / President: escalated only.
  Stream<List<Complaint>> streamEscalated() {
    return _complaints
        .where('status', isEqualTo: ComplaintStatus.escalated.value)
        .snapshots()
        .map(
      (snap) {
        final list = snap.docs
            .map((d) => Complaint.fromDoc(d))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  Future<Complaint?> getComplaint(String complaintId) async {
    final doc = await _complaints.doc(complaintId).get();
    if (!doc.exists) return null;
    return Complaint.fromDoc(doc);
  }

  /// Live updates for detail screen.
  Stream<Complaint?> streamComplaint(String complaintId) {
    return _complaints.doc(complaintId).snapshots().map(
          (d) {
            if (!d.exists) return null;
            return Complaint.fromDoc(d);
          },
        );
  }

  /// Optional student display name for admin / officer views.
  Future<Complaint?> getComplaintWithStudentName(String complaintId) async {
    final c = await getComplaint(complaintId);
    if (c == null) return null;
    final userDoc =
        await _db.collection(FirestorePaths.users).doc(c.studentId).get();
    final name = userDoc.data()?['name'] as String?;
    return c.copyWith(studentName: name);
  }

  /// Ordered thread for a complaint.
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

  /// Officer or executive adds a reply; notifies the student.
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
    );
    await _responses.doc(id).set(r.toFirestore());

    final label = fromExecutive ? author.role.displayName : 'Your officer';
    await _notifications.notifyUser(
      userId: complaint.studentId,
      message:
          '$label replied to "${complaint.title}": ${message.length > 80 ? '${message.substring(0, 80)}…' : message}',
    );
  }

  /// Officer workflow: move ticket forward or escalate.
  Future<void> updateComplaintStatus({
    required Complaint complaint,
    required ComplaintStatus newStatus,
    required AppUser actor,
  }) async {
    await _complaints.doc(complaint.complaintId).update({
      'status': newStatus.value,
    });

    var body = 'Status of "${complaint.title}" is now ${newStatus.displayName}.';
    if (newStatus == ComplaintStatus.escalated) {
      body =
          'Complaint "${complaint.title}" was escalated by ${actor.name}.';
    }
    await _notifications.notifyUser(
      userId: complaint.studentId,
      message: body,
    );
  }
}
