import '../models/complaint_model.dart';
import '../models/complaint_status.dart';
import '../models/sector_model.dart';

/// Simple aggregates for the admin dashboard (client-side from snapshot).
class CampusReport {
  CampusReport({
    required this.total,
    required this.byStatus,
    required this.bySector,
  });

  final int total;
  final Map<ComplaintStatus, int> byStatus;
  final Map<String, int> bySector;

  static CampusReport fromComplaints(List<Complaint> complaints) {
    final byStatus = <ComplaintStatus, int>{
      for (final s in ComplaintStatus.values) s: 0,
    };
    final bySector = <String, int>{};
    for (final c in complaints) {
      byStatus[c.status] = (byStatus[c.status] ?? 0) + 1;
      bySector[c.sectorId] = (bySector[c.sectorId] ?? 0) + 1;
    }
    return CampusReport(
      total: complaints.length,
      byStatus: byStatus,
      bySector: bySector,
    );
  }

  static String sectorLabel(String id) => CampusSectors.label(id);
}
