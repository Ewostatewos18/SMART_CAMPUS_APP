import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/service_providers.dart';
import '../models/account_status.dart';
import '../models/sector_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User management'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pending approval'),
            Tab(text: 'All users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PendingList(),
          _AllUsersList(),
        ],
      ),
    );
  }
}

class _PendingList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(userServiceProvider).streamPendingUsers();
    return StreamBuilder<List<AppUser>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data!;
        if (users.isEmpty) {
          return const Center(child: Text('No pending registrations'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) => _UserTile(user: users[i], showApproval: true),
        );
      },
    );
  }
}

class _AllUsersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(userServiceProvider).streamAllUsers();
    return StreamBuilder<List<AppUser>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) => _UserTile(user: users[i], showApproval: false),
        );
      },
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user, required this.showApproval});

  final AppUser user;
  final bool showApproval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = user.accountStatus;
    return Card(
      child: ListTile(
        title: Text(user.name),
        subtitle: Text(
          '${user.email} · ${user.role.displayName}'
          '${status != AccountStatus.approved ? ' · ${status.displayName}' : ''}',
        ),
        isThreeLine: showApproval,
        trailing: showApproval
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Approve',
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green.shade700,
                    onPressed: () => _setStatus(context, ref, AccountStatus.approved),
                  ),
                  IconButton(
                    tooltip: 'Reject',
                    icon: const Icon(Icons.cancel_outlined),
                    color: Colors.red.shade700,
                    onPressed: () => _setStatus(context, ref, AccountStatus.rejected),
                  ),
                ],
              )
            : PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'approve') {
                    await _setStatus(context, ref, AccountStatus.approved);
                  } else if (action == 'reject') {
                    await _setStatus(context, ref, AccountStatus.rejected);
                  } else if (action == 'role') {
                    await _changeRole(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  if (status == AccountStatus.pending)
                    const PopupMenuItem(value: 'approve', child: Text('Approve')),
                  if (status == AccountStatus.pending)
                    const PopupMenuItem(value: 'reject', child: Text('Reject')),
                  const PopupMenuItem(value: 'role', child: Text('Change role')),
                ],
              ),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    AccountStatus status,
  ) async {
    try {
      await ref.read(userServiceProvider).updateAccountStatus(
            userId: user.userId,
            status: status,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name}: ${status.displayName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _changeRole(BuildContext context, WidgetRef ref) async {
    final role = await showDialog<UserRole>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change role'),
        children: UserRole.values
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, r),
                child: Text(r.displayName),
              ),
            )
            .toList(),
      ),
    );
    if (role == null || !context.mounted) return;

    String? sectorId;
    if (role == UserRole.sectorOfficer) {
      sectorId = await _pickSector(context);
      if (sectorId == null) return;
    }

    try {
      await ref.read(userServiceProvider).updateUserRole(
            userId: user.userId,
            role: role,
            sectorId: sectorId,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<String?> _pickSector(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Assign sector'),
        children: CampusSectors.all
            .map(
              (s) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, s.id),
                child: Text(s.name),
              ),
            )
            .toList(),
      ),
    );
  }
}
