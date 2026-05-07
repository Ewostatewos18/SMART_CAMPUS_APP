import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/user_role.dart';
import 'providers/auth_provider.dart';
import 'screens/admin_dashboard.dart';
import 'screens/executive_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/officer_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'services/auth_service.dart';
import 'services/complaint_service.dart';
import 'services/messaging_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'screens/firebase_init_error_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web + mobile need explicit options from FlutterFire (`firebase_options.dart`).
  // Calling `Firebase.initializeApp()` with no options often fails on Web → blank page.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
    runApp(FirebaseInitErrorScreen(error: e));
    return;
  }

  // FCM on Web needs extra Service Worker / VAPID setup; skip here to avoid startup crashes.
  if (!kIsWeb) {
    final messaging = MessagingService();
    try {
      await messaging.initialize(
        onForeground: (message) {
          debugPrint('FCM foreground: ${message.notification?.title}');
        },
      );
    } catch (e, st) {
      debugPrint('Messaging init skipped: $e\n$st');
    }
  }

  runApp(const SmartCampusApp());
}

class SmartCampusApp extends StatelessWidget {
  const SmartCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<UserService>(create: (_) => UserService()),
        Provider<ComplaintService>(
          create: (c) => ComplaintService(
            notificationService: c.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (c) => AuthProvider(c.read<AuthService>()),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Campus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes signed-in users to the correct dashboard by role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!auth.isAuthenticated || auth.appUser == null) {
      return const LoginScreen();
    }
    switch (auth.appUser!.role) {
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.sectorOfficer:
        return const OfficerDashboard();
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.vicePresident:
      case UserRole.president:
        return const ExecutiveDashboard();
    }
  }
}
