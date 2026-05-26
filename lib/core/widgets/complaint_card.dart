import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/complaint_model.dart';
import '../../models/sector_model.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: complaint.status),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  TypeChip(type: complaint.type),
                  PriorityChip(priority: complaint.priority),
                  if (complaint.isAnonymous)
                    Chip(
                      avatar: const Icon(Icons.visibility_off, size: 14),
                      label: const Text('Anonymous'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.domain, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    CampusSectors.label(complaint.sectorId),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              if (showStudent && complaint.studentName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Student: ${complaint.studentName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (complaint.location != null && complaint.location!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 14, color: scheme.outline),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint.location!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                date,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
