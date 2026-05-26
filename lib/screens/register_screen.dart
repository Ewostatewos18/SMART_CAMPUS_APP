import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/bdu_email_validator.dart';
import '../core/widgets/loading_overlay.dart';
import '../features/auth/presentation/auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _department = TextEditingController();
  final _studentId = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _department.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authStateProvider.notifier).clearError();

    final email = BduEmailValidator.normalize(_email.text);
    final idFromEmail = BduEmailValidator.extractStudentId(email);
    final studentId = _studentId.text.trim().isEmpty
        ? idFromEmail
        : _studentId.text.trim();

    if (idFromEmail != null &&
        _studentId.text.trim().isNotEmpty &&
        _studentId.text.trim() != idFromEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student ID must match the number in your BDU email.'),
        ),
      );
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).registerStudent(
            name: _name.text,
            email: email,
            password: _password.text,
            department: _department.text.trim().isEmpty
                ? null
                : _department.text.trim(),
            studentId: studentId,
          );
      if (mounted) context.go('/student');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(authStateProvider).errorMessage ?? 'Registration failed',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Student registration')),
      body: LoadingOverlay(
        loading: auth.isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Join ${AppConstants.universityName}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Student accounts only. Staff roles are assigned by administrators.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        onChanged: (value) {
                          final id = BduEmailValidator.extractStudentId(value);
                          if (id != null && _studentId.text.trim().isEmpty) {
                            _studentId.text = id;
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'University email',
                          hintText: AppConstants.studentEmailExample,
                          helperText: AppConstants.studentEmailHint,
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: BduEmailValidator.validate,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _studentId,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          hintText: '1403952',
                          helperText: 'Filled automatically from your BDU email',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter your student ID';
                          }
                          if (!RegExp(AppConstants.studentIdPattern)
                              .hasMatch(v.trim())) {
                            return 'Use digits only (e.g. 1403952)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _department,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Department / Faculty (optional)',
                          prefixIcon: Icon(Icons.account_tree_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: const Text('Create account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
