import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/service_providers.dart';
import '../core/theme/theme_mode_notifier.dart';
import '../core/widgets/loading_overlay.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _department = TextEditingController();
  final _studentId = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    _studentId.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  void _syncControllers(AppUser user) {
    if (_initialized) return;
    _name.text = user.name;
    _department.text = user.department ?? '';
    _studentId.text = user.studentId ?? '';
    _initialized = true;
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authStateProvider).appUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(authServiceProvider).updateProfile(
            uid: user.userId,
            name: _name.text.trim(),
            department: _department.text.trim(),
            studentId: _studentId.text.trim(),
          );
      await ref.read(authStateProvider.notifier).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPassword.text.isEmpty || _newPassword.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter current password and new password (6+ chars).'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(authServiceProvider).changePassword(
            currentPassword: _currentPassword.text,
            newPassword: _newPassword.text,
          );
      _currentPassword.clear();
      _newPassword.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password change failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authStateProvider.notifier).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).appUser;
    final themeMode = ref.watch(themeModeProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _syncControllers(user);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: LoadingOverlay(
        loading: _saving,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 28,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                ),
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${user.role.displayName} · ${user.email}'),
            ),
            const SizedBox(height: 16),
            Text('Account', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _studentId,
              decoration: const InputDecoration(labelText: 'Student ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _department,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saveProfile,
              child: const Text('Save profile'),
            ),
            const Divider(height: 40),
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) {
                ref.read(themeModeProvider.notifier).setThemeMode(s.first);
              },
            ),
            const Divider(height: 40),
            Text('Security', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _currentPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _changePassword,
              child: const Text('Change password'),
            ),
            const Divider(height: 40),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
