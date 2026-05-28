import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/account_status.dart';
import '../../../models/user_role.dart';
import '../widgets/auth_scaffold.dart';

class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({
    super.key,
    required this.role,
    required this.accountStatus,
    required this.email,
  });

  final UserRole role;
  final AccountStatus accountStatus;
  final String email;

  String get _successMessage {
    if (accountStatus == AccountStatus.pending) {
      return 'Your ${role.displayName} registration was received. '
          'You can sign in after an administrator approves your account.';
    }
    if (role == UserRole.admin) {
      return 'Your administrator account is ready. Sign in to open the admin dashboard.';
    }
    if (role == UserRole.student) {
      return 'Your student account is ready. Sign in with your credentials to continue.';
    }
    return 'Your account is ready. Sign in with your email and password.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pending = accountStatus == AccountStatus.pending;

    return AuthScaffold(
      maxWidth: 480,
      child: Column(
        children: [
          Icon(
            pending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
            size: 64,
            color: pending ? scheme.tertiary : scheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            pending ? 'Registration submitted' : 'Account created',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _successMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.go('/login'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Continue to log in'),
          ),
        ],
      ),
    );
  }
}
