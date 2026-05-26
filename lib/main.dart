import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/service_providers.dart';
import 'firebase_options.dart';
import 'screens/firebase_init_error_screen.dart';
import 'screens/linux_dev_guide_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Flutter SDK: Android, iOS, macOS, Web, Windows — not Linux desktop.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    runApp(const LinuxDevGuideApp());
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
    runApp(FirebaseInitErrorScreen(error: e));
    return;
  }

  runApp(
    ProviderScope(
      child: const _MessagingBootstrap(child: SmartCampusApp()),
    ),
  );
}

class _MessagingBootstrap extends ConsumerStatefulWidget {
  const _MessagingBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_MessagingBootstrap> createState() =>
      _MessagingBootstrapState();
}

class _MessagingBootstrapState extends ConsumerState<_MessagingBootstrap> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initMessaging();
    }
  }

  Future<void> _initMessaging() async {
    try {
      final messaging = ref.read(messagingServiceProvider);
      await messaging.initialize(
        onForeground: (message) {
          debugPrint('FCM foreground: ${message.notification?.title}');
        },
      );
    } catch (e, st) {
      debugPrint('Messaging init skipped: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
