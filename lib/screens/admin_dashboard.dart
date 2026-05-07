import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/complaint_model.dart';
import '../providers/auth_provider.dart';
import '../services/complaint_service.dart';
import '../services/report_service.dart';
import '../widgets/complaint_card.dart';
import '../widgets/empty_state.dart';
import 'complaint_detail_screen.dart';
import 'user_management_screen.dart';

/// Admin: overview, reports, and entry to user tools.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ComplaintService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Users',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UserManagementScreen(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: svc.streamAll(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          final report = CampusReport.fromComplaints(list);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus snapshot',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _ReportGrid(report: report),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No complaints in the system',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final c = list[i];
                      return ComplaintCard(
                        complaint: c,
                        showStudent: true,
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
                    childCount: list.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportGrid extends StatelessWidget {
  const _ReportGrid({required this.report});

  final CampusReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricChip(
              label: 'Total',
              value: '${report.total}',
            ),
            ...report.byStatus.entries.map(
              (e) => _MetricChip(
                label: e.key.displayName,
                value: '${e.value}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'By sector',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...report.bySector.entries.map(
          (e) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(CampusReport.sectorLabel(e.key)),
            trailing: Text('${e.value}'),
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(label),
    );
  }
}
