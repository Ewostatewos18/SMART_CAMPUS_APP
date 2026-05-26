/// Campus sectors for routing complaints to the correct officer group.
class Sector {
  const Sector({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  final String id;
  final String name;
  final String icon;
  final String description;
}

/// All 12 BDU Student Union sectors.
class CampusSectors {
  CampusSectors._();

  static const List<Sector> all = [
    Sector(
      id: 'academics',
      name: 'Academics',
      icon: 'school',
      description: 'Courses, exams, grading, and academic services',
    ),
    Sector(
      id: 'health',
      name: 'Health',
      icon: 'medical_services',
      description: 'Campus clinic and student health services',
    ),
    Sector(
      id: 'cafeteria',
      name: 'Cafeteria',
      icon: 'restaurant',
      description: 'Dining halls, food quality, and meal services',
    ),
    Sector(
      id: 'dormitory',
      name: 'Dormitory',
      icon: 'apartment',
      description: 'Housing, dorm facilities, and room assignments',
    ),
    Sector(
      id: 'gender_affairs',
      name: 'Gender Affairs',
      icon: 'diversity_3',
      description: 'Gender equity, safety, and inclusion programs',
    ),
    Sector(
      id: 'sports',
      name: 'Sports',
      icon: 'sports_soccer',
      description: 'Athletics, recreation, and sports facilities',
    ),
    Sector(
      id: 'finance',
      name: 'Finance',
      icon: 'account_balance',
      description: 'Fees, bursar, scholarships, and financial aid',
    ),
    Sector(
      id: 'clubs',
      name: 'Clubs',
      icon: 'groups',
      description: 'Student clubs, associations, and activities',
    ),
    Sector(
      id: 'discipline',
      name: 'Discipline',
      icon: 'gavel',
      description: 'Conduct, disciplinary procedures, and appeals',
    ),
    Sector(
      id: 'pr',
      name: 'PR',
      icon: 'campaign',
      description: 'Public relations and campus communications',
    ),
    Sector(
      id: 'special_needs',
      name: 'Special Needs',
      icon: 'accessibility_new',
      description: 'Accessibility and disability support services',
    ),
    Sector(
      id: 'general_services',
      name: 'General Services',
      icon: 'build',
      description: 'Maintenance, utilities, and general campus services',
    ),
  ];

  static Sector? byId(String? id) {
    if (id == null) return null;
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  static String label(String sectorId) => byId(sectorId)?.name ?? sectorId;
}
