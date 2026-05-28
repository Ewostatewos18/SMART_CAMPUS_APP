import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/bdu_email_validator.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../models/sector_model.dart';
import '../../../models/user_role.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/role_selector.dart';
import 'auth_notifier.dart';
import '../models/register_success_args.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  UserRole _role = UserRole.student;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _studentId = TextEditingController();
  final _department = TextEditingController();
  final _year = TextEditingController();
  final _section = TextEditingController();
  final _position = TextEditingController();
  final _officeInfo = TextEditingController();
  final _adminCode = TextEditingController();

  String? _sectorId;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _studentId.dispose();
    _department.dispose();
    _year.dispose();
    _section.dispose();
    _position.dispose();
    _officeInfo.dispose();
    _adminCode.dispose();
    super.dispose();
  }

  bool get _isStudent => _role == UserRole.student;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == UserRole.sectorOfficer &&
        (_sectorId == null || _sectorId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your assigned sector.')),
      );
      return;
    }

    ref.read(authStateProvider.notifier).clearError();
    setState(() => _loading = true);

    final email = _isStudent
        ? BduEmailValidator.normalize(_email.text)
        : _email.text.trim();

    try {
      final result = await ref.read(authStateProvider.notifier).registerAccount(
            role: _role,
            name: _name.text,
            email: email,
            password: _password.text,
            phone: _phone.text.trim().isEmpty ? null : _phone.text,
            studentId: _studentId.text.trim().isEmpty ? null : _studentId.text,
            department:
                _department.text.trim().isEmpty ? null : _department.text,
            year: _year.text.trim().isEmpty ? null : _year.text,
            section: _section.text.trim().isEmpty ? null : _section.text,
            sectorId: _sectorId,
            position: _position.text.trim().isEmpty ? null : _position.text,
            officeInfo:
                _officeInfo.text.trim().isEmpty ? null : _officeInfo.text,
            adminCode: _adminCode.text.trim().isEmpty ? null : _adminCode.text,
          );

      if (!mounted) return;
      // Stay on success screen even if auth listener fires sign-out.
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      context.go(
        '/register-success',
        extra: RegisterSuccessArgs(
          role: result.role,
          accountStatus: result.accountStatus,
          email: result.email,
        ),
      );
    } catch (e) {
      if (mounted) {
        final err =
            ref.read(authStateProvider).errorMessage ?? _formatError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    return LoadingOverlay(
      loading: _loading,
      child: AuthScaffold(
        title: 'Create account',
        subtitle: switch (_role) {
          UserRole.student => 'Students use their official BDU email',
          UserRole.admin => 'Use your admin registration code to sign in right away',
          _ => 'Officers and executives need approval after registration',
        },
        showBack: true,
        maxWidth: 560,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoleSelector(
                value: _role,
                onChanged: (r) => setState(() => _role = r),
              ),
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 12),
                MaterialBanner(
                  content: Text(auth.errorMessage!),
                  backgroundColor:
                      Theme.of(context).colorScheme.errorContainer,
                  actions: [
                    TextButton(
                      onPressed: () =>
                          ref.read(authStateProvider.notifier).clearError(),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              if (_isStudent) ...[
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Profile photo can be added after sign-in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AuthTextField(
                controller: _name,
                label: 'Full name',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _email,
                label: _isStudent ? 'University email' : 'Email',
                hint: _isStudent
                    ? AppConstants.studentEmailExample
                    : 'your.email@example.com',
                helper: _isStudent ? AppConstants.studentEmailHint : 'Your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => _isStudent
                    ? BduEmailValidator.validate(v)
                    : (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _phone,
                label: 'Phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              ..._roleFields(),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _password,
                label: 'Password',
                helper: 'At least ${PasswordValidator.minLength} characters',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) => PasswordValidator.validate(v),
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _confirmPassword,
                label: 'Confirm password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) => PasswordValidator.validateConfirm(
                  v,
                  _password.text,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isStudent ? 'Create student account' : 'Submit registration'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Log in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _roleFields() {
    switch (_role) {
      case UserRole.student:
        return [
          AuthTextField(
            controller: _studentId,
            label: 'Student ID',
            hint: 'e.g. ${AppConstants.studentIdExample}',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                final fromEmail =
                    BduEmailValidator.extractStudentId(_email.text);
                if (fromEmail != null) return null;
                return 'Enter your student ID';
              }
              if (!RegExp(AppConstants.studentIdPattern).hasMatch(v.trim())) {
                return 'Enter a valid numeric student ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _department,
            label: 'Department',
            prefixIcon: Icons.domain_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AuthTextField(
                  controller: _year,
                  label: 'Year',
                  prefixIcon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthTextField(
                  controller: _section,
                  label: 'Section',
                  prefixIcon: Icons.class_outlined,
                ),
              ),
            ],
          ),
        ];
      case UserRole.sectorOfficer:
        return [
          DropdownButtonFormField<String>(
            value: _sectorId,
            decoration: const InputDecoration(
              labelText: 'Assigned sector',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
            items: CampusSectors.all
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _sectorId = v),
            validator: (v) => v == null ? 'Select a sector' : null,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _position,
            label: 'Position / title',
            prefixIcon: Icons.work_outline,
          ),
        ];
      case UserRole.vicePresident:
        return [
          AuthTextField(
            controller: _position,
            label: 'Leadership position',
            prefixIcon: Icons.military_tech_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your position' : null,
          ),
        ];
      case UserRole.president:
        return [
          AuthTextField(
            controller: _officeInfo,
            label: 'Office information',
            prefixIcon: Icons.business_outlined,
            maxLines: 2,
          ),
        ];
      case UserRole.admin:
        return [
          AuthTextField(
            controller: _adminCode,
            label: 'Administrator code',
            prefixIcon: Icons.vpn_key_outlined,
            obscureText: true,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Enter the admin registration code'
                : null,
          ),
        ];
    }
  }
}

String _formatError(Object e) {
  if (e is FirebaseAuthException) {
    return e.message ?? e.code;
  }
  if (e is StateError) return e.message;
  if (e is ArgumentError) return e.message ?? e.toString();
  return e.toString();
}
