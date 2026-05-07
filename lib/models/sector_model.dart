/// Campus sectors for routing complaints to the correct officer group.
class Sector {
  const Sector({required this.id, required this.name});

  final String id;
  final String name;
}

/// Default sectors — extend or move to Firestore if admins should edit them.
class CampusSectors {
  CampusSectors._();

  static const List<Sector> all = [
    Sector(id: 'academic', name: 'Academic Affairs'),
    Sector(id: 'facilities', name: 'Facilities & Housing'),
    Sector(id: 'it', name: 'IT Services'),
    Sector(id: 'student_affairs', name: 'Student Affairs'),
    Sector(id: 'finance', name: 'Finance & Bursar'),
    Sector(id: 'security', name: 'Campus Security'),
  ];

  static Sector? byId(String? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static String label(String sectorId) => byId(sectorId)?.name ?? sectorId;
}
