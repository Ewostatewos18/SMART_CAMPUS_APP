import 'package:flutter/material.dart';

import '../models/complaint_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ComplaintStatus status;

  Color _color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case ComplaintStatus.submitted:
        return scheme.secondaryContainer;
      case ComplaintStatus.inProgress:
        return scheme.primaryContainer;
      case ComplaintStatus.resolved:
        return scheme.tertiaryContainer;
      case ComplaintStatus.escalated:
        return scheme.errorContainer;
    }
  }

  Color _onColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case ComplaintStatus.submitted:
        return scheme.onSecondaryContainer;
      case ComplaintStatus.inProgress:
        return scheme.onPrimaryContainer;
      case ComplaintStatus.resolved:
        return scheme.onTertiaryContainer;
      case ComplaintStatus.escalated:
        return scheme.onErrorContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.displayName),
      backgroundColor: _color(context),
      labelStyle: TextStyle(color: _onColor(context), fontWeight: FontWeight.w600),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
