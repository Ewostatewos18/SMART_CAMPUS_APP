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

class ComplaintListScreen extends ConsumerWidget {
  const ComplaintListScreen({
    super.key,
    required this.title,
    required this.complaintsStream,
    this.showStudentOnCard = false,
    this.embedded = false,
  });

  final String title;
  final Stream<List<Complaint>> complaintsStream;
  final bool showStudentOnCard;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = StreamBuilder<List<Complaint>>(
      stream: ref
          .watch(complaintServiceProvider)
          .streamWithStudentNames(complaintsStream),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        if (!snap.hasData) return const ShimmerList();
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No complaints here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final c = list[i];
            return ComplaintCard(
              complaint: c,
              showStudent: showStudentOnCard,
              onTap: () => context.push('/complaint/${c.complaintId}'),
            );
          },
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}
