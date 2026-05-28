import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Ensures Firestore is ready before reads/writes (especially on web).
class FirestoreBootstrap {
  FirestoreBootstrap._();

  static bool _configured = false;

  static Future<void> configure() async {
    if (_configured) return;
    final db = FirebaseFirestore.instance;

    try {
      await db.enableNetwork();
    } catch (e) {
      debugPrint('Firestore enableNetwork: $e');
    }

    _configured = true;
  }

  /// Reads a user profile document (server first, then cache).
  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    await configure();
    try {
      return await ref.get(const GetOptions(source: Source.server));
    } on FirebaseException catch (e) {
      if (_isOfflineError(e) || e.code == 'unavailable') {
        try {
          return await ref.get(const GetOptions(source: Source.cache));
        } catch (_) {
          await ref.firestore.enableNetwork();
          return await ref.get();
        }
      }
      rethrow;
    }
  }

  static bool _isOfflineError(FirebaseException e) {
    if (e.code == 'unavailable') return true;
    final msg = (e.message ?? '').toLowerCase();
    return msg.contains('offline') || msg.contains('client is offline');
  }

  static String offlineMessage() {
    return 'Cannot reach Firebase. Check your internet, turn off VPN/ad-blockers, '
        'reload the page (Ctrl+Shift+R), and try again.';
  }

  static String permissionMessage() {
    return 'Cannot read your profile from Firestore. '
        'In Firebase Console → Firestore → Rules, publish the rules from '
        'firestore.rules in this project, then try again.';
  }
}
