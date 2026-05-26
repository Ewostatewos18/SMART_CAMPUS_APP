import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/service_providers.dart';
import '../core/widgets/complaint_card.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/shimmer_loading.dart';
import '../models/complaint_model.dart';
import '../models/complaint_status.dart';
import '../models/complaint_type.dart';
import '../models/sector_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  ComplaintStatus? _status;
  String? _sectorId;
  ComplaintPriority? _priority;
  ComplaintType? _type;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Complaint> _filter(List<Complaint> list) {
    final q = _query.text.trim().toLowerCase();
    return list.where((c) {
      if (q.isNotEmpty &&
          !c.title.toLowerCase().contains(q) &&
          !c.description.toLowerCase().contains(q)) {
        return false;
      }
      if (_status != null && c.status != _status) return false;
      if (_sectorId != null && c.sectorId != _sectorId) return false;
      if (_priority != null && c.priority != _priority) return false;
      if (_type != null && c.type != _type) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(complaintServiceProvider).streamAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Search & filter')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search complaints…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DropdownButton<ComplaintStatus?>(
                        value: _status,
                        hint: const Text('Status'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All statuses'),
                          ),
                          ...ComplaintStatus.values.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.displayName),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _status = v),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String?>(
                        value: _sectorId,
                        hint: const Text('Sector'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All sectors'),
                          ),
                          ...CampusSectors.all.map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _sectorId = v),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<ComplaintPriority?>(
                        value: _priority,
                        hint: const Text('Priority'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All priorities'),
                          ),
                          ...ComplaintPriority.values.map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.displayName),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _priority = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Complaint>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) return const ShimmerList();
                final filtered = _filter(snap.data!);
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching complaints',
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    return ComplaintCard(
                      complaint: c,
                      showStudent: true,
                      onTap: () => context.push('/complaint/${c.complaintId}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
