/// Type of submission from a student.
enum ComplaintType {
  complaint('complaint'),
  suggestion('suggestion');

  const ComplaintType(this.value);
  final String value;

  static ComplaintType fromString(String? raw) {
    if (raw == null) return ComplaintType.complaint;
    return ComplaintType.values.firstWhere(
      (t) => t.value == raw,
      orElse: () => ComplaintType.complaint,
    );
  }

  String get displayName =>
      this == ComplaintType.complaint ? 'Complaint' : 'Suggestion';
}

/// Priority level for triage and escalation.
enum ComplaintPriority {
  low('low'),
  medium('medium'),
  high('high'),
  emergency('emergency');

  const ComplaintPriority(this.value);
  final String value;

  static ComplaintPriority fromString(String? raw) {
    if (raw == null) return ComplaintPriority.medium;
    return ComplaintPriority.values.firstWhere(
      (p) => p.value == raw,
      orElse: () => ComplaintPriority.medium,
    );
  }

  String get displayName {
    switch (this) {
      case ComplaintPriority.low:
        return 'Low';
      case ComplaintPriority.medium:
        return 'Medium';
      case ComplaintPriority.high:
        return 'High';
      case ComplaintPriority.emergency:
        return 'Emergency';
    }
  }
}

/// Student satisfaction after resolution.
enum SatisfactionRating {
  none('none'),
  satisfied('satisfied'),
  unsatisfied('unsatisfied');

  const SatisfactionRating(this.value);
  final String value;

  static SatisfactionRating fromString(String? raw) {
    if (raw == null) return SatisfactionRating.none;
    return SatisfactionRating.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => SatisfactionRating.none,
    );
  }
}
