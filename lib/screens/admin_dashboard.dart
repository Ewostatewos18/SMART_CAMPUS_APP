import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/service_providers.dart';
import '../core/widgets/complaint_card.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/shimmer_loading.dart';
import '../models/complaint_model.dart';
import '../services/report_service.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(complaintServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Create staff account',
            onPressed: () => context.push('/admin/create-user'),
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Users',
            onPressed: () => context.push('/admin/users'),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: svc.streamAll(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData) return const ShimmerList();
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
                        'Campus overview',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _MetricGrid(report: report),
                      const SizedBox(height: 24),
                      Text('Status distribution',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: _StatusPieChart(report: report),
                      ),
                      const SizedBox(height: 24),
                      Text('Sector performance',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: _SectorBarChart(report: report),
                      ),
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
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final c = list[i];
                        return ComplaintCard(
                          complaint: c,
                          showStudent: true,
                          onTap: () => context.push('/complaint/${c.complaintId}'),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.report});

  final CampusReport report;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _MetricCard(
          label: 'Total',
          value: '${report.total}',
          icon: Icons.folder_open,
          color: Theme.of(context).colorScheme.primary,
        ),
        _MetricCard(
          label: 'Resolved',
          value: '${report.resolvedCount}',
          icon: Icons.check_circle_outline,
          color: Colors.green.shade700,
        ),
        _MetricCard(
          label: 'Pending',
          value: '${report.pendingCount}',
          icon: Icons.pending_actions,
          color: Colors.orange.shade800,
        ),
        _MetricCard(
          label: 'Escalated',
          value: '${report.escalatedCount}',
          icon: Icons.priority_high,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  const _StatusPieChart({required this.report});

  final CampusReport report;

  @override
  Widget build(BuildContext context) {
    final entries = report.byStatus.entries
        .where((e) => e.value > 0)
        .toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No data yet'));
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.green,
      Colors.red,
      Colors.grey,
      Colors.brown,
    ];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 36,
        sections: [
          for (var i = 0; i < entries.length; i++)
            PieChartSectionData(
              value: entries[i].value.toDouble(),
              title: '${entries[i].value}',
              color: colors[i % colors.length],
              radius: 52,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectorBarChart extends StatelessWidget {
  const _SectorBarChart({required this.report});

  final CampusReport report;

  @override
  Widget build(BuildContext context) {
    final entries = report.bySector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const Center(child: Text('No sector data'));
    }

    final maxY = entries.first.value.toDouble() + 2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: [
          for (var i = 0; i < entries.length && i < 6; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length || i >= 6) {
                  return const SizedBox.shrink();
                }
                final label = CampusReport.sectorLabel(entries[i].key);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label.length > 8 ? '${label.substring(0, 7)}…' : label,
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
