/// University roles stored in Firestore as [value] strings.
enum UserRole {
  student('student'),
  sectorOfficer('sectorOfficer'),
  admin('admin'),
  vicePresident('vicePresident'),
  president('president');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String? raw) {
    if (raw == null || raw.isEmpty) return UserRole.student;
    return UserRole.values.firstWhere(
      (r) => r.value == raw,
      orElse: () => UserRole.student,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.sectorOfficer:
        return 'Sector Officer';
      case UserRole.admin:
        return 'Admin';
      case UserRole.vicePresident:
        return 'Vice President';
      case UserRole.president:
        return 'President';
    }
  }
}
