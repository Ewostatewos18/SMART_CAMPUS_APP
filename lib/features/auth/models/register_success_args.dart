import '../../../models/account_status.dart';
import '../../../models/user_role.dart';

class RegisterSuccessArgs {
  const RegisterSuccessArgs({
    required this.role,
    required this.accountStatus,
    required this.email,
  });

  final UserRole role;
  final AccountStatus accountStatus;
  final String email;
}
