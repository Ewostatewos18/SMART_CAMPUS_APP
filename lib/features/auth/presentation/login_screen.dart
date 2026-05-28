import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_status.dart';
import '../../../core/auth/rbac.dart';
import '../../../core/auth/session_prefs.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import 'auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfAlreadySignedIn();
    });
  }

  void _redirectIfAlreadySignedIn() {
    final auth = ref.read(authStateProvider);
    if (auth.isAuthenticated && auth.user != null && mounted) {
      context.go(Rbac.homeForRole(auth.user!.role));
    }
  }

  Future<void> _loadRemembered() async {
    final remember = await SessionPrefs.getRememberMe();
    final email = await SessionPrefs.getRememberedEmail();
    if (!mounted) return;
    if (remember && email != null) {
      _email.text = email;
      setState(() => _remember = true);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goToDashboard(AuthState auth) {
    if (!mounted || auth.user == null) return;
    context.go(Rbac.homeForRole(auth.user!.role));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authStateProvider.notifier).clearError();
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).signIn(
            _email.text,
            _password.text,
            rememberMe: _remember,
          );
      if (!mounted) return;
      final auth = ref.read(authStateProvider);
      if (auth.isAuthenticated) {
        _goToDashboard(auth);
      }
    } catch (_) {
      if (mounted) {
        final err = ref.read(authStateProvider).errorMessage;
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              duration: const Duration(seconds: 8),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.isAuthenticated && next.user != null) {
        _goToDashboard(next);
      }
    });

    return LoadingOverlay(
      loading: _loading,
      child: AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in with your account',
        showBack: true,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.errorMessage != null) ...[
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
                const SizedBox(height: 12),
              ],
              AuthTextField(
                controller: _email,
                label: 'Your email',
                hint: 'Your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _password,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your password' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v ?? false),
                  ),
                  const Text('Remember me'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Log in'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
