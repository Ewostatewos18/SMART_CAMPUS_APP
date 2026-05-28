import '../../../models/account_status.dart';
import '../../../models/user_role.dart';

class RegistrationResult {
  const RegistrationResult({
    required this.email,
    required this.role,
    required this.accountStatus,
  });

  final String email;
  final UserRole role;
  final AccountStatus accountStatus;

  bool get pendingApproval => accountStatus == AccountStatus.pending;
}
