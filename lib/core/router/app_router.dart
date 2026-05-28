import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_status.dart';
import '../../core/auth/rbac.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/models/register_success_args.dart';
import '../../features/auth/presentation/register_success_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../models/account_status.dart';
import '../../models/user_role.dart';
import '../../screens/admin_dashboard.dart';
import '../../screens/complaint_detail_screen.dart';
import '../../screens/complaint_form_screen.dart';
import '../../screens/create_staff_screen.dart';
import '../../screens/executive_dashboard.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/officer_dashboard.dart';
import '../../screens/profile_screen.dart';
import '../../screens/profile_missing_screen.dart';
import '../../screens/search_screen.dart';
import '../../screens/student_dashboard.dart';
import '../../screens/user_management_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Single GoRouter instance — must NOT rebuild when auth changes (that resets navigation).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final isSplash = loc == '/';
      final isPublicAuth = loc == '/welcome' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/register-success' ||
          loc == '/forgot-password';
      final isAuthRoute = isPublicAuth || loc == '/profile-missing';

      switch (auth.status) {
        case AuthStatus.unknown:
        case AuthStatus.loading:
          // Only hold on splash while bootstrapping; never kick login/register to welcome.
          if (isSplash) return null;
          if (isPublicAuth) return null;
          return null;

        case AuthStatus.profileMissing:
          return loc == '/profile-missing' ? null : '/profile-missing';

        case AuthStatus.unauthenticated:
          if (isAuthRoute && loc != '/profile-missing') return null;
          if (isSplash) return '/welcome';
          return '/welcome';

        case AuthStatus.authenticated:
          final user = auth.user!;
          if (isAuthRoute || isSplash) {
            return Rbac.homeForRole(user.role);
          }
          if (!Rbac.canAccessRoute(user.role, loc)) {
            return Rbac.homeForRole(user.role);
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/register-success',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is RegisterSuccessArgs) {
            return RegisterSuccessScreen(
              role: extra.role,
              accountStatus: extra.accountStatus,
              email: extra.email,
            );
          }
          return const RegisterSuccessScreen(
            role: UserRole.student,
            accountStatus: AccountStatus.approved,
            email: '',
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile-missing',
        builder: (_, __) => const ProfileMissingScreen(),
      ),
      GoRoute(path: '/student', builder: (_, __) => const StudentDashboard()),
      GoRoute(path: '/officer', builder: (_, __) => const OfficerDashboard()),
      GoRoute(
        path: '/vp',
        builder: (_, __) =>
            const ExecutiveDashboard(role: UserRole.vicePresident),
      ),
      GoRoute(
        path: '/president',
        builder: (_, __) => const ExecutiveDashboard(role: UserRole.president),
      ),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
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
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/admin/create-user',
        builder: (_, __) => const CreateStaffScreen(),
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _sub = _ref.listen<AuthState>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
