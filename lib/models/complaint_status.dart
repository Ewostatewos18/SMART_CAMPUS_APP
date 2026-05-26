/// Complaint workflow states persisted in Firestore as [value].
enum ComplaintStatus {
  submitted('submitted'),
  assigned('assigned'),
  inReview('inReview'),
  inProgress('inProgress'),
  resolved('resolved'),
  escalated('escalated'),
  closed('closed'),
  rejected('rejected');

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
      case ComplaintStatus.assigned:
        return 'Assigned';
      case ComplaintStatus.inReview:
        return 'In Review';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.escalated:
        return 'Escalated';
      case ComplaintStatus.closed:
        return 'Closed';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isTerminal =>
      this == ComplaintStatus.resolved ||
      this == ComplaintStatus.closed ||
      this == ComplaintStatus.rejected;
}
