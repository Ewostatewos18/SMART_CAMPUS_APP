import '../models/complaint_model.dart';
import '../models/complaint_status.dart';
import '../models/complaint_type.dart';
import '../models/sector_model.dart';

/// Analytics aggregates for admin dashboard.
class CampusReport {
  CampusReport({
    required this.total,
    required this.byStatus,
    required this.bySector,
    required this.byPriority,
    required this.byType,
    required this.resolvedCount,
    required this.pendingCount,
    required this.escalatedCount,
  });

  final int total;
  final Map<ComplaintStatus, int> byStatus;
  final Map<String, int> bySector;
  final Map<ComplaintPriority, int> byPriority;
  final Map<ComplaintType, int> byType;
  final int resolvedCount;
  final int pendingCount;
  final int escalatedCount;

  double get resolutionRate =>
      total == 0 ? 0 : resolvedCount / total;

  static CampusReport fromComplaints(List<Complaint> complaints) {
    final byStatus = <ComplaintStatus, int>{
      for (final s in ComplaintStatus.values) s: 0,
    };
    final bySector = <String, int>{};
    final byPriority = <ComplaintPriority, int>{
      for (final p in ComplaintPriority.values) p: 0,
    };
    final byType = <ComplaintType, int>{
      for (final t in ComplaintType.values) t: 0,
    };

    var resolved = 0;
    var pending = 0;
    var escalated = 0;

    for (final c in complaints) {
      byStatus[c.status] = (byStatus[c.status] ?? 0) + 1;
      bySector[c.sectorId] = (bySector[c.sectorId] ?? 0) + 1;
      byPriority[c.priority] = (byPriority[c.priority] ?? 0) + 1;
      byType[c.type] = (byType[c.type] ?? 0) + 1;

      if (c.status == ComplaintStatus.resolved ||
          c.status == ComplaintStatus.closed) {
        resolved++;
      } else if (c.status == ComplaintStatus.escalated) {
        escalated++;
        pending++;
      } else if (!c.status.isTerminal) {
        pending++;
      }
    }

    return CampusReport(
      total: complaints.length,
      byStatus: byStatus,
      bySector: bySector,
      byPriority: byPriority,
      byType: byType,
      resolvedCount: resolved,
      pendingCount: pending,
      escalatedCount: escalated,
    );
  }

  static String sectorLabel(String id) => CampusSectors.label(id);
}

class ReportService {
  CampusReport compute(List<Complaint> complaints) =>
      CampusReport.fromComplaints(complaints);
}
