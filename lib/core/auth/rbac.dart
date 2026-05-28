import '../../models/user_role.dart';

/// Role-based access control helpers.
class Rbac {
  Rbac._();

  static const _studentRoutes = {'/student', '/complaint', '/profile'};
  static const _officerRoutes = {'/officer', '/complaint', '/profile', '/search'};
  static const _vpRoutes = {'/vp', '/complaint', '/profile', '/search'};
  static const _presidentRoutes = {
    '/president',
    '/complaint',
    '/profile',
    '/search',
  };
  static const _adminRoutes = {
    '/admin',
    '/complaint',
    '/profile',
    '/search',
    '/admin/users',
    '/admin/create-user',
  };

  static String homeForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return '/student';
      case UserRole.sectorOfficer:
        return '/officer';
      case UserRole.vicePresident:
        return '/vp';
      case UserRole.president:
        return '/president';
      case UserRole.admin:
        return '/admin';
    }
  }

  static bool canAccessRoute(UserRole role, String path) {
    final prefixes = switch (role) {
      UserRole.student => _studentRoutes,
      UserRole.sectorOfficer => _officerRoutes,
      UserRole.vicePresident => _vpRoutes,
      UserRole.president => _presidentRoutes,
      UserRole.admin => _adminRoutes,
    };
    return prefixes.any((p) => path == p || path.startsWith('$p/'));
  }

  static bool canSelfRegister(UserRole role) => true;

  static bool isStaffRole(UserRole role) =>
      role != UserRole.student && role != UserRole.admin;

  static bool canManageUsers(UserRole role) => role == UserRole.admin;

  static bool canCreateComplaint(UserRole role) => role == UserRole.student;
}
