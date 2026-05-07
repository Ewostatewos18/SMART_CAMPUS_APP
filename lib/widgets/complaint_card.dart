import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/complaint_model.dart';
import '../models/sector_model.dart';
import 'status_chip.dart';

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
    this.showStudent = false,
  });

  final Complaint complaint;
  final VoidCallback? onTap;
  final bool showStudent;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().add_jm().format(complaint.createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          complaint.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              CampusSectors.label(complaint.sectorId),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showStudent && complaint.studentName != null)
              Text(
                'Student: ${complaint.studentName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(date, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        trailing: StatusChip(status: complaint.status),
      ),
    );
  }
}
