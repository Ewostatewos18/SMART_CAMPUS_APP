import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/complaint_model.dart';
import '../providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../services/complaint_service.dart';
import '../services/notification_service.dart';
import '../widgets/complaint_card.dart';
import '../widgets/empty_state.dart';
import 'complaint_detail_screen.dart';
import 'complaint_form_screen.dart';
import 'complaint_list_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final complaints = context.read<ComplaintService>();
    final notifications = context.read<NotificationService>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student home'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => context.read<AuthProvider>().signOut(),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My complaints', icon: Icon(Icons.list_alt)),
              Tab(text: 'Notifications', icon: Icon(Icons.notifications_none)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StudentComplaintsTab(stream: complaints.streamForStudent(user.userId)),
            _NotificationsTab(
              stream: notifications.streamForUser(user.userId),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final added = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const ComplaintFormScreen(),
              ),
            );
            if (added == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complaint added to your list.')),
              );
            }
          },
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('New complaint'),
        ),
      ),
    );
  }
}

class _StudentComplaintsTab extends StatelessWidget {
  const _StudentComplaintsTab({required this.stream});

  final Stream<List<Complaint>> stream;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: FilledButton.tonalIcon(
            onPressed: () {
              final u = context.read<AuthProvider>().appUser!;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ComplaintListScreen(
                    title: 'All my complaints',
                    complaintsStream:
                        context.read<ComplaintService>().streamForStudent(
                              u.userId,
                            ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.open_in_full),
            label: const Text('Open full list'),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Complaint>>(
            stream: stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.outgoing_mail,
                  title: 'No complaints yet',
                  subtitle: 'Tap “New complaint” to reach the right office.',
                );
              }
              final preview = list.take(8).toList();
              return ListView.builder(
                itemCount: preview.length,
                itemBuilder: (context, i) {
                  final c = preview[i];
                  return ComplaintCard(
                    complaint: c,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ComplaintDetailScreen(
                            complaintId: c.complaintId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({required this.stream});

  final Stream<List<AppNotification>> stream;

  @override
  Widget build(BuildContext context) {
    final notifSvc = context.read<NotificationService>();
    return StreamBuilder<List<AppNotification>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'No notifications',
            subtitle: 'We will notify you when your ticket is updated.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final n = list[i];
            return ListTile(
              tileColor: n.isRead
                  ? null
                  : Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(n.message),
              trailing: n.isRead
                  ? null
                  : TextButton(
                      onPressed: () => notifSvc.markRead(n.notificationId),
                      child: const Text('Mark read'),
                    ),
            );
          },
        );
      },
    );
  }
}
