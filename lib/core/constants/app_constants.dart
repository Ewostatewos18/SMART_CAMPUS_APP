/// Application-wide constants for Smart Campus platform.
class AppConstants {
  AppConstants._();

  static const appName = 'Smart Campus';
  static const appTagline = 'Complaints & Suggestions';
  static const universityName = 'Bahir Dar University Student Union';

  /// Days before auto-escalation for unresolved high-priority complaints.
  static const escalationDaysThreshold = 7;

  /// BDU institutional email: BDU + student ID + @bdu.edu.et
  static const studentEmailExample = 'BDU1303957@bdu.edu.et';
  static const studentIdExample = '1303957';
  static const studentEmailDomain = 'bdu.edu.et';
  static const studentEmailHint =
      'BDU + your student ID + @bdu.edu.et (e.g. 1303957)';

  /// Numeric student ID (without BDU prefix), e.g. 1403952.
  static const studentIdPattern = r'^\d{4,10}$';

  /// Required when self-registering as administrator (demo / pilot).
  static const adminRegistrationCode = 'BDU-SMARTCAMPUS-ADMIN';
}
