import 'package:flutter/material.dart';

/// Premium gradient backdrop for auth and onboarding screens.
class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.surface,
            scheme.tertiaryContainer.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: child,
    );
  }
}
