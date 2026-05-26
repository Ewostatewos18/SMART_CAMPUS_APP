import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_notifier.dart';
import '../../screens/admin_dashboard.dart';
import '../../screens/complaint_detail_screen.dart';
import '../../screens/complaint_form_screen.dart';
import '../../screens/executive_dashboard.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/officer_dashboard.dart';
import '../../screens/profile_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/search_screen.dart';
import '../../screens/student_dashboard.dart';
import '../../screens/user_management_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.appUser;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (isLoading) return null;

      if (user == null) {
        return onAuth ? null : '/login';
      }

      if (onAuth) {
        return dashboardPathForRole(user.role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (_, __) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/officer',
        builder: (_, __) => const OfficerDashboard(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/executive',
        builder: (_, __) => const ExecutiveDashboard(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/complaint/new',
        builder: (_, __) => const ComplaintFormScreen(),
      ),
      GoRoute(
        path: '/complaint/:id',
        builder: (_, state) => ComplaintDetailScreen(
          complaintId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const UserManagementScreen(),
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen<AuthState>(authStateProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
