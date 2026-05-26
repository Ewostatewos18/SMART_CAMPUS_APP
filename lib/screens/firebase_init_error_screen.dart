import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shown when Firebase fails to start.
class FirebaseInitErrorScreen extends StatelessWidget {
  const FirebaseInitErrorScreen({super.key, required this.error});

  final Object error;

  String get _platformHint {
    if (kIsWeb) {
      return 'Web requires valid Firebase web config in lib/firebase_options.dart '
          'and a Web app registered in the Firebase console.';
    }
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'Linux desktop needs Firebase options in lib/firebase_options.dart. '
          'This project includes a Linux config; if you still see this error, '
          're-run FlutterFire configure and select Linux, or run on Chrome/Android.';
    }
    return 'Check that this platform is registered in Firebase and that '
        'lib/firebase_options.dart matches your project.';
  }

  String get _fixSteps {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'Fix (Linux desktop):\n'
          '1) dart pub global activate flutterfire_cli\n'
          '2) dart run flutterfire_cli:flutterfire configure\n'
          '3) Select project smartcampusapp-bf9af and enable Linux + Web\n'
          '4) flutter clean && flutter pub get && flutter run -d linux\n\n'
          'Or use Web instead:\n'
          '  flutter config --enable-web\n'
          '  flutter run -d chrome';
    }
    return 'Fix (recommended):\n'
        '1) dart pub global activate flutterfire_cli\n'
        '2) dart run flutterfire_cli:flutterfire configure\n'
        '3) Select your Firebase project and enable Web + Android\n'
        '4) flutter clean && flutter pub get && flutter run -d chrome';
  }

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
                  _platformHint,
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
                Text(_fixSteps),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
