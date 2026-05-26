import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Shown on Linux desktop because Firebase Flutter does not support Linux.
class LinuxDevGuideApp extends StatelessWidget {
  const LinuxDevGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      home: const LinuxDevGuideScreen(),
    );
  }
}

class LinuxDevGuideScreen extends StatelessWidget {
  const LinuxDevGuideScreen({super.key});

  static const _runCommand = r'''export CHROME_EXECUTABLE=/usr/bin/chromium-browser
flutter run -d chrome''';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.desktop_windows_outlined, size: 64, color: scheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Use Web on Linux',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Firebase (Auth, Firestore, FCM) does not support Linux desktop. '
                    'Your machine only has Linux as the default Flutter device, so the app '
                    'must run in Chromium/Chrome instead.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Text('Run in terminal', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      _runCommand,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Or use the helper script:\n  ./scripts/run_web.sh',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For Android: connect a device or start an emulator, then\n'
                    '  flutter run -d android',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
