import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_notifier.dart';

/// Firebase Auth exists but Firestore user profile is missing.
class ProfileMissingScreen extends ConsumerWidget {
  const ProfileMissingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Profile not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              auth.errorMessage ??
                  'Your login exists but your campus profile is missing. '
                  'Ask an administrator to complete your account setup.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  ref.read(authStateProvider.notifier).clearOrphanSession(),
              child: const Text('Sign out and try again'),
            ),
          ],
        ),
      ),
    );
  }
}
