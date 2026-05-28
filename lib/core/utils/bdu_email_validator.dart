/// Validates Bahir Dar University institutional student emails.
///
/// Format: `BDU` + student ID + `@bdu.edu.et`
/// Example: `BDU1403952@bdu.edu.et`
class BduEmailValidator {
  BduEmailValidator._();

  /// `BDU` + digits + `@bdu.edu.et` (case-insensitive domain/prefix).
  static final RegExp _pattern = RegExp(
    r'^BDU(\d{4,10})@bdu\.edu\.et$',
    caseSensitive: false,
  );

  /// Accepts `BDU1403952.bdu.edu.et` and normalizes to `BDU1403952@bdu.edu.et`.
  static String normalize(String raw) {
    var email = raw.trim();
    if (email.isEmpty) return email;

    // Common typo: dot instead of @ before the domain.
    final dotDomain = RegExp(r'^(.+)\.bdu\.edu\.et$', caseSensitive: false);
    final dotMatch = dotDomain.firstMatch(email);
    if (dotMatch != null && !email.contains('@')) {
      email = '${dotMatch.group(1)}@bdu.edu.et';
    }

    final match = _pattern.firstMatch(email);
    if (match == null) return email.toLowerCase();

    final id = match.group(1)!;
    return 'BDU$id@bdu.edu.et';
  }

  static bool isValid(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    return _pattern.hasMatch(normalize(raw));
  }

  /// Returns `null` when valid, otherwise a user-facing error message.
  static String? validate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Enter your university email';
    }
    if (!isValid(raw)) {
      return 'Use your BDU email (e.g. BDU1303957@bdu.edu.et)';
    }
    return null;
  }

  /// Numeric student ID from email local part, e.g. `1403952`.
  static String? extractStudentId(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final match = _pattern.firstMatch(normalize(raw));
    return match?.group(1);
  }
}
