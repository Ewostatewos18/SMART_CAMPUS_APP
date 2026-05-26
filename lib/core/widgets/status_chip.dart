import 'package:flutter/material.dart';

import '../../models/complaint_status.dart';
import '../../models/complaint_type.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ComplaintStatus status;

  (Color, Color) _colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case ComplaintStatus.submitted:
        return (scheme.secondaryContainer, scheme.onSecondaryContainer);
      case ComplaintStatus.assigned:
        return (scheme.surfaceContainerHighest, scheme.onSurface);
      case ComplaintStatus.inReview:
        return (scheme.tertiaryContainer, scheme.onTertiaryContainer);
      case ComplaintStatus.inProgress:
        return (scheme.primaryContainer, scheme.onPrimaryContainer);
      case ComplaintStatus.resolved:
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
      case ComplaintStatus.escalated:
        return (scheme.errorContainer, scheme.onErrorContainer);
      case ComplaintStatus.closed:
        return (scheme.surfaceContainerHigh, scheme.onSurfaceVariant);
      case ComplaintStatus.rejected:
        return (scheme.errorContainer.withValues(alpha: 0.6), scheme.onErrorContainer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(context);
    return Chip(
      label: Text(status.displayName),
      backgroundColor: bg,
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority});

  final ComplaintPriority priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (priority) {
      case ComplaintPriority.low:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
      case ComplaintPriority.medium:
        bg = scheme.primaryContainer.withValues(alpha: 0.5);
        fg = scheme.onPrimaryContainer;
      case ComplaintPriority.high:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
      case ComplaintPriority.emergency:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
    }
    return Chip(
      label: Text(priority.displayName),
      backgroundColor: bg,
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 11),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class TypeChip extends StatelessWidget {
  const TypeChip({super.key, required this.type});

  final ComplaintType type;

  @override
  Widget build(BuildContext context) {
    final isSuggestion = type == ComplaintType.suggestion;
    return Chip(
      avatar: Icon(
        isSuggestion ? Icons.lightbulb_outline : Icons.report_problem_outlined,
        size: 16,
      ),
      label: Text(type.displayName),
      visualDensity: VisualDensity.compact,
    );
  }
}
