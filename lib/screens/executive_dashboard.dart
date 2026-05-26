import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/service_providers.dart';
import '../features/auth/presentation/auth_notifier.dart';
import 'complaint_list_screen.dart';

class ExecutiveDashboard extends ConsumerWidget {
  const ExecutiveDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).appUser;
    final stream = ref.watch(complaintServiceProvider).streamEscalated();

    return Scaffold(
      appBar: AppBar(
        title: Text('${user?.role.displayName ?? 'Executive'} desk'),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ComplaintListScreen(
        title: 'Escalated complaints',
        complaintsStream: stream,
        showStudentOnCard: true,
        embedded: true,
      ),
    );
  }
}
