import 'package:shared_preferences/shared_preferences.dart';

/// Persists non-secret session preferences (remember me email).
class SessionPrefs {
  SessionPrefs._();

  static const _rememberKey = 'remember_me';
  static const _emailKey = 'remembered_email';

  static Future<bool> getRememberMe() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_rememberKey) ?? false;
  }

  static Future<String?> getRememberedEmail() async {
    final p = await SharedPreferences.getInstance();
    if (!(p.getBool(_rememberKey) ?? false)) return null;
    return p.getString(_emailKey);
  }

  static Future<void> saveRememberMe({
    required bool remember,
    String? email,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_rememberKey, remember);
    if (remember && email != null) {
      await p.setString(_emailKey, email.trim());
    } else {
      await p.remove(_emailKey);
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_rememberKey);
    await p.remove(_emailKey);
  }
}
