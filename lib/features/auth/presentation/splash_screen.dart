import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_status.dart';
import '../../../core/auth/rbac.dart';
import '../../../core/constants/app_constants.dart';
import 'auth_notifier.dart';

/// Animated splash while Firebase session is restored.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateFromAuth(AuthState auth) {
    if (!mounted) return;
    switch (auth.status) {
      case AuthStatus.authenticated:
        if (auth.user != null) {
          context.go(Rbac.homeForRole(auth.user!.role));
        }
        break;
      case AuthStatus.unauthenticated:
        context.go('/welcome');
        break;
      case AuthStatus.profileMissing:
        context.go('/profile-missing');
        break;
      case AuthStatus.unknown:
      case AuthStatus.loading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.status != AuthStatus.loading && next.status != AuthStatus.unknown) {
        _navigateFromAuth(next);
      }
    });

    final auth = ref.watch(authStateProvider);
    if (auth.status != AuthStatus.loading && auth.status != AuthStatus.unknown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromAuth(auth);
      });
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.15),
              scheme.surface,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_rounded, size: 72, color: scheme.primary),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Starting…',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
