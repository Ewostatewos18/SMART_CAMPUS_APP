import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/core/utils/bdu_email_validator.dart';
import 'package:smart_campus_app/core/services/smart_analysis_service.dart';
import 'package:smart_campus_app/models/complaint_status.dart';
import 'package:smart_campus_app/models/complaint_type.dart';
import 'package:smart_campus_app/models/sector_model.dart';
import 'package:smart_campus_app/services/report_service.dart';
import 'package:smart_campus_app/models/complaint_model.dart';

void main() {
  group('BduEmailValidator', () {
    test('accepts standard BDU email', () {
      expect(BduEmailValidator.isValid('BDU1403952@bdu.edu.et'), isTrue);
    });

    test('normalizes dot typo before domain', () {
      expect(
        BduEmailValidator.normalize('BDU1403952.bdu.edu.et'),
        'BDU1403952@bdu.edu.et',
      );
    });

    test('extracts student ID', () {
      expect(
        BduEmailValidator.extractStudentId('BDU1403952@bdu.edu.et'),
        '1403952',
      );
    });

    test('rejects non-BDU email', () {
      expect(BduEmailValidator.isValid('student@gmail.com'), isFalse);
    });
  });

  group('SmartAnalysisService', () {
    const service = SmartAnalysisService();

    test('detects suggestion type', () {
      final result = service.analyze(
        title: 'Improve cafeteria menu',
        description: 'I suggest adding more vegetarian options for students.',
        sectorId: 'cafeteria',
      );
      expect(result.suggestedType, ComplaintType.suggestion);
    });

    test('detects emergency priority', () {
      final result = service.analyze(
        title: 'Emergency in dorm',
        description: 'There is an emergency flood in block B dormitory.',
        sectorId: 'dormitory',
      );
      expect(result.suggestedPriority, ComplaintPriority.emergency);
    });

    test('flags very short text as spam', () {
      final result = service.analyze(
        title: 'Hi',
        description: 'bad',
        sectorId: 'health',
      );
      expect(result.isLikelySpam, isTrue);
    });
  });

  group('CampusReport', () {
    test('computes aggregates', () {
      final complaints = [
        Complaint(
          complaintId: '1',
          title: 'A',
          description: 'Test complaint one',
          studentId: 's1',
          sectorId: CampusSectors.all.first.id,
          status: ComplaintStatus.submitted,
          createdAt: DateTime(2026),
        ),
        Complaint(
          complaintId: '2',
          title: 'B',
          description: 'Test complaint two',
          studentId: 's2',
          sectorId: CampusSectors.all.first.id,
          status: ComplaintStatus.resolved,
          createdAt: DateTime(2026),
        ),
      ];

      final report = CampusReport.fromComplaints(complaints);
      expect(report.total, 2);
      expect(report.resolvedCount, 1);
      expect(report.pendingCount, 1);
    });
  });
}
