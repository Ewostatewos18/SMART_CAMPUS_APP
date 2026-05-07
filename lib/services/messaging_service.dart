import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM setup: permission, token (save to Firestore in a follow-up if needed).
class MessagingService {
  MessagingService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  /// Request notification permission and attach foreground listener.
  Future<void> initialize({
    void Function(RemoteMessage message)? onForeground,
  }) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      onForeground?.call(message);
    });

    // Optional: background handler must be top-level — wire in main.dart if used.
  }

  Future<String?> getFcmToken() => _messaging.getToken();
}
