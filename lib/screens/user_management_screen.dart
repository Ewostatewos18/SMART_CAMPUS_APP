import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/service_providers.dart';
import '../models/sector_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(userServiceProvider).streamAllUsers();

    return Scaffold(
      appBar: AppBar(title: const Text('User management')),
      body: StreamBuilder<List<AppUser>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final u = users[i];
              return Card(
                child: ListTile(
                  title: Text(u.name),
                  subtitle: Text('${u.email} · ${u.role.displayName}'),
                  trailing: PopupMenuButton<UserRole>(
                    tooltip: 'Change role',
                    onSelected: (role) async {
                      String? sectorId;
                      if (role == UserRole.sectorOfficer) {
                        sectorId = await _pickSector(context);
                        if (sectorId == null) return;
                      }
                      try {
                        await ref.read(userServiceProvider).updateUserRole(
                              userId: u.userId,
                              role: role,
                              sectorId: sectorId,
                            );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => UserRole.values
                        .map(
                          (r) => PopupMenuItem(
                            value: r,
                            child: Text(r.displayName),
                          ),
                        )
                        .toList(),
                    child: const Icon(Icons.admin_panel_settings_outlined),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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
