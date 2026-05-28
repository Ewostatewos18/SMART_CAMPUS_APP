import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/service_providers.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../models/user_role.dart';
import 'complaint_list_screen.dart';

class ExecutiveDashboard extends ConsumerWidget {
  const ExecutiveDashboard({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final stream = ref.watch(complaintServiceProvider).streamEscalated();

    return Scaffold(
      appBar: AppBar(
        title: Text('${role.displayName} desk'),
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
      body: user?.role != role
          ? const Center(child: Text('Access denied for this dashboard.'))
          : ComplaintListScreen(
              title: 'Escalated complaints',
              complaintsStream: stream,
              showStudentOnCard: true,
              embedded: true,
            ),
    );
  }
}
