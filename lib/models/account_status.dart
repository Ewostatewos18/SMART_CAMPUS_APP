/// Account approval lifecycle for registration.
enum AccountStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const AccountStatus(this.value);
  final String value;

  static AccountStatus fromString(String? raw) {
    if (raw == null) return AccountStatus.approved;
    return AccountStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => AccountStatus.approved,
    );
  }

  String get displayName {
    switch (this) {
      case AccountStatus.pending:
        return 'Pending approval';
      case AccountStatus.approved:
        return 'Approved';
      case AccountStatus.rejected:
        return 'Rejected';
    }
  }
}
