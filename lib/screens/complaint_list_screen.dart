import 'package:flutter/material.dart';

import '../models/complaint_model.dart';
import '../widgets/complaint_card.dart';
import '../widgets/empty_state.dart';
import 'complaint_detail_screen.dart';

/// Generic list driven by a [Stream] of complaints.
class ComplaintListScreen extends StatelessWidget {
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

  /// When true, only the scrollable content is returned (parent supplies [Scaffold]).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<List<Complaint>>(
      stream: complaintsStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading list: ${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No complaints yet',
            subtitle: 'When items appear, they will show up here.',
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final c = list[i];
            return ComplaintCard(
              complaint: c,
              showStudent: showStudentOnCard,
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
