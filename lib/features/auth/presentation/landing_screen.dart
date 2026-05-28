import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../widgets/auth_gradient_background.dart';

/// Premium welcome screen — first stop for unauthenticated users.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 720;

    return Scaffold(
      body: AuthGradientBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: isWide ? _WideLayout(scheme: scheme) : _NarrowLayout(scheme: scheme),
            ),
          ),
        ),
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: _LandingContent(scheme: scheme, centered: true),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Row(
            children: [
              Expanded(child: _HeroIllustration(scheme: scheme)),
              const SizedBox(width: 48),
              Expanded(child: _LandingContent(scheme: scheme, centered: false)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.2),
            scheme.tertiaryContainer.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.apartment_rounded, size: 120, color: scheme.primary.withValues(alpha: 0.35)),
          Icon(Icons.groups_rounded, size: 64, color: scheme.primary),
        ],
      ),
    );
  }
}

class _LandingContent extends StatelessWidget {
  const _LandingContent({
    required this.scheme,
    required this.centered,
  });

  final ColorScheme scheme;
  final bool centered;

  static const _features = [
    ('Track complaints', 'Submit and follow campus issues in real time.'),
    ('12 union sectors', 'Routed to the right Student Union office.'),
    ('Role-based access', 'Students, officers, executives, and admins.'),
    ('Transparent updates', 'Status changes and responses you can trust.'),
  ];

  @override
  Widget build(BuildContext context) {
    final align = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Icon(Icons.school_rounded, size: 48, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.appTagline,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Empowering BDU students with a modern platform for complaints, suggestions, and campus coordination.',
          textAlign: textAlign,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 32),
        ..._features.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FeatureTile(title: f.$1, subtitle: f.$2, scheme: scheme),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: centered ? double.infinity : 320,
          child: FilledButton(
            onPressed: () => context.go('/register'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Create account'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: centered ? double.infinity : 320,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Log in'),
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.scheme,
  });

  final String title;
  final String subtitle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
