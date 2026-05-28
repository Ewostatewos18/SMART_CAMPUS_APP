import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_glass_card.dart';
import 'auth_gradient_background.dart';

/// Scrollable auth layout with gradient + optional back button.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.maxWidth = 520,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showBack;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 900;

    return Scaffold(
      body: AuthGradientBackground(
        child: SafeArea(
          child: Row(
            children: [
              if (isWide)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: _SidePanel(),
                  ),
                ),
              Expanded(
                flex: isWide ? 1 : 1,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          showBack ? 8 : 24,
                          20,
                          32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showBack)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/welcome');
                                    }
                                  },
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                              ),
                            if (title != null) ...[
                              Text(
                                title!,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  subtitle!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 24),
                            ],
                            AuthGlassCard(
                              maxWidth: maxWidth,
                              child: child,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.school_rounded, size: 64, color: scheme.primary),
        const SizedBox(height: 24),
        Text(
          'Smart Campus',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bahir Dar University Student Union — track complaints, empower students, and coordinate campus services.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}
