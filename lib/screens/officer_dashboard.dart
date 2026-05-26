import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/service_providers.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../models/sector_model.dart';
import 'complaint_list_screen.dart';

class OfficerDashboard extends ConsumerWidget {
  const OfficerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user.sectorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Officer')),
        body: const Center(
          child: Text('No sector assigned. Contact an administrator.'),
        ),
      );
    }

    final stream =
        ref.watch(complaintServiceProvider).streamForSector(user.sectorId!);

    return Scaffold(
      appBar: AppBar(
        title: Text('${CampusSectors.label(user.sectorId!)} queue'),
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
        title: 'Sector complaints',
        complaintsStream: stream,
        showStudentOnCard: true,
        embedded: true,
      ),
    );
  }
}
