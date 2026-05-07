import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/complaint_service.dart';
import 'complaint_list_screen.dart';

/// VP / President: escalated items only.
class ExecutiveDashboard extends StatelessWidget {
  const ExecutiveDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final stream = context.read<ComplaintService>().streamEscalated();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leadership'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded),
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
