import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shown when Firebase fails to start (common on Web without `firebase_options.dart`).
class FirebaseInitErrorScreen extends StatelessWidget {
  const FirebaseInitErrorScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase setup')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectionArea(
            child: ListView(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not initialize Firebase',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  kIsWeb
                      ? 'Web requires valid Firebase web config in lib/firebase_options.dart '
                          '(run FlutterFire CLI) and a Web app registered in the Firebase console.'
                      : 'Check that this platform is registered in Firebase and that '
                          'lib/firebase_options.dart matches your project.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Fix (recommended):\n'
                  '1) dart pub global activate flutterfire_cli\n'
                  '2) dart run flutterfire_cli:flutterfire configure\n'
                  '3) Select your Firebase project and enable Web + Android\n'
                  '4) flutter clean && flutter pub get && flutter run -d chrome',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
