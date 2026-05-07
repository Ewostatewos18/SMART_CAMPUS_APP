import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sector_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/user_service.dart';
import '../widgets/loading_overlay.dart';

/// Admin: change roles and sector assignment.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String? _updatingId;
  String? _error;

  Future<void> _changeRole(
    AppUser u,
    UserRole role,
    String? sectorId,
  ) async {
    setState(() {
      _updatingId = u.userId;
      _error = null;
    });
    try {
      await context.read<UserService>().updateUserRole(
            userId: u.userId,
            role: role,
            sectorId: sectorId,
          );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _updatingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = context.read<UserService>();
    return Scaffold(
      appBar: AppBar(title: const Text('User management')),
      body: LoadingOverlay(
        loading: _updatingId != null,
        child: StreamBuilder<List<AppUser>>(
          stream: users.streamAllUsers(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data!;
            return Column(
              children: [
                if (_error != null)
                  MaterialBanner(
                    content: Text(_error!),
                    actions: [
                      TextButton(
                        onPressed: () => setState(() => _error = null),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final u = list[i];
                      return ExpansionTile(
                        leading: CircleAvatar(
                          child: Text(u.name.isNotEmpty ? u.name[0] : '?'),
                        ),
                        title: Text(u.name),
                        subtitle: Text(
                          '${u.email}\n${u.role.displayName}'
                          '${u.sectorId != null ? ' • ${CampusSectors.label(u.sectorId!)}' : ''}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<UserRole>(
                                  value: u.role,
                                  decoration: const InputDecoration(
                                    labelText: 'Role',
                                  ),
                                  items: UserRole.values
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r.displayName),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _updatingId != null
                                      ? null
                                      : (newRole) async {
                                          if (newRole == null) return;
                                          if (newRole == UserRole.sectorOfficer) {
                                            await showDialog<void>(
                                              context: context,
                                              builder: (ctx) {
                                                var selected = u.sectorId ??
                                                    CampusSectors.all.first.id;
                                                return StatefulBuilder(
                                                  builder: (context, setDialogState) {
                                                    return AlertDialog(
                                                      title: const Text('Sector'),
                                                      content:
                                                          DropdownButtonFormField<
                                                              String>(
                                                        value: selected,
                                                        items: CampusSectors
                                                            .all
                                                            .map(
                                                              (s) =>
                                                                  DropdownMenuItem(
                                                                value: s.id,
                                                                child: Text(
                                                                  s.name,
                                                                ),
                                                              ),
                                                            )
                                                            .toList(),
                                                        onChanged: (v) {
                                                          if (v == null) return;
                                                          setDialogState(
                                                            () => selected = v,
                                                          );
                                                        },
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                ctx,
                                                              ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              ctx,
                                                            );
                                                            _changeRole(
                                                              u,
                                                              newRole,
                                                              selected,
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Save',
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          } else {
                                            await _changeRole(u, newRole, null);
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
