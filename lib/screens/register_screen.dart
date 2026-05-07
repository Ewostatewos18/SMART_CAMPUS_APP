import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sector_model.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_overlay.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  UserRole _role = UserRole.student;
  String? _sectorId = CampusSectors.all.first.id;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == UserRole.sectorOfficer &&
        (_sectorId == null || _sectorId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sector.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    auth.clearError();
    try {
      await auth.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
        sectorId: _role == UserRole.sectorOfficer ? _sectorId : null,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Registration failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
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
                        decoration: const InputDecoration(
                          labelText: 'University email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || !v.contains('@')) {
                            return 'Valid email required';
                          }
                          return null;
                        },
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
                          if (v == null || v.length < 6) {
                            return 'Min 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        value: _role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: UserRole.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _role = v);
                        },
                      ),
                      if (_role == UserRole.sectorOfficer) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _sectorId,
                          decoration: const InputDecoration(
                            labelText: 'Assigned sector',
                            prefixIcon: Icon(Icons.domain_verification_outlined),
                          ),
                          items: CampusSectors.all
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _sectorId = v),
                        ),
                      ],
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
