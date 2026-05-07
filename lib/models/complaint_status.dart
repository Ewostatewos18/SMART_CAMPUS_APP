/// Complaint workflow states persisted in Firestore as [value].
enum ComplaintStatus {
  submitted('submitted'),
  inProgress('inProgress'),
  resolved('resolved'),
  escalated('escalated');

  const ComplaintStatus(this.value);
  final String value;

  static ComplaintStatus fromString(String? raw) {
    if (raw == null || raw.isEmpty) return ComplaintStatus.submitted;
    return ComplaintStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => ComplaintStatus.submitted,
    );
  }

  String get displayName {
    switch (this) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.escalated:
        return 'Escalated';
    }
  }
}
