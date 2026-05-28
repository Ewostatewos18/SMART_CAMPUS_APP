import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/service_providers.dart';
import '../core/widgets/complaint_card.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/shimmer_loading.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../models/complaint_model.dart';
import '../models/notification_model.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final complaints = ref.watch(complaintServiceProvider);
    final notifications = ref.watch(notificationServiceProvider);
    final complaintStream = complaints.streamForStudent(user.userId);
    final notifStream = notifications.streamForUser(user.userId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Campus'),
            Text(
              'Hello, ${user.name.split(' ').first}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _ComplaintsTab(stream: complaintStream),
          _NotificationsTab(stream: notifStream),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/complaint/new'),
              icon: const Icon(Icons.add),
              label: const Text('New ticket'),
            )
          : null,
    );
  }
}

class _ComplaintsTab extends StatelessWidget {
  const _ComplaintsTab({required this.stream});

  final Stream<List<Complaint>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Complaint>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load complaints',
            subtitle: '${snap.error}',
          );
        }
        if (!snap.hasData) return const ShimmerList();
        final list = snap.data!;
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.outgoing_mail,
            title: 'No complaints yet',
            subtitle: 'Submit your first complaint or suggestion to the Student Union.',
            actionLabel: 'New ticket',
            onAction: () => context.push('/complaint/new'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];
              return ComplaintCard(
                complaint: c,
                onTap: () => context.push('/complaint/${c.complaintId}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _NotificationsTab extends ConsumerWidget {
  const _NotificationsTab({required this.stream});

  final Stream<List<AppNotification>> stream;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifSvc = ref.watch(notificationServiceProvider);
    return StreamBuilder<List<AppNotification>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        if (!snap.hasData) return const ShimmerList();
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'No notifications',
            subtitle: 'Status updates and officer replies appear here.',
          );
        }
        return Column(
          children: [
            if (list.any((n) => !n.isRead))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final uid = ref.read(authStateProvider).user!.userId;
                    notifSvc.markAllRead(uid);
                  },
                  child: const Text('Mark all read'),
                ),
              ),
            Expanded(
              child: ListView.separated(
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(_iconForType(n.type)),
                    title: Text(n.message),
                    trailing: n.isRead
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.done_all, size: 20),
                            onPressed: () => notifSvc.markRead(n.notificationId),
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'status_change':
        return Icons.sync_alt;
      case 'response':
        return Icons.chat_bubble_outline;
      case 'escalation':
        return Icons.priority_high;
      case 'complaint_submitted':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }
}
