import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/complaint_service.dart';
import 'complaint_list_screen.dart';

/// Sector officer: work queue for the assigned [sectorId].
class OfficerDashboard extends StatelessWidget {
  const OfficerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (user.sectorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Officer')),
        body: const Center(
          child: Text('No sector assigned. Contact an administrator.'),
        ),
      );
    }
    final stream = context
        .read<ComplaintService>()
        .streamForSector(user.sectorId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer queue'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded),
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
