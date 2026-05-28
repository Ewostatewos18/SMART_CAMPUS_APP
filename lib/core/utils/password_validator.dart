/// Password rules for registration (aligned with Firebase Auth minimum).
class PasswordValidator {
  PasswordValidator._();

  /// Minimum length only — no letter/number requirements.
  static const minLength = 6;

  static String? validate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Enter a password';
    if (raw.length < minLength) {
      return 'Use at least $minLength characters';
    }
    return null;
  }

  static String? validateConfirm(String? confirm, String password) {
    if (confirm == null || confirm.isEmpty) return 'Confirm your password';
    if (confirm != password) return 'Passwords do not match';
    return null;
  }
}
