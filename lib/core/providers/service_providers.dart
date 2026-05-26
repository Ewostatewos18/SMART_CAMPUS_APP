import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/messaging_service.dart';
import '../../services/notification_service.dart';
import '../../services/report_service.dart';
import '../../services/user_service.dart';
import '../services/smart_analysis_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final userServiceProvider = Provider<UserService>((ref) => UserService());

final smartAnalysisProvider =
    Provider<SmartAnalysisService>((ref) => const SmartAnalysisService());

final complaintServiceProvider = Provider<ComplaintService>((ref) {
  return ComplaintService(
    notificationService: ref.watch(notificationServiceProvider),
    smartAnalysis: ref.watch(smartAnalysisProvider),
  );
});

final reportServiceProvider = Provider<ReportService>((ref) => ReportService());

final messagingServiceProvider =
    Provider<MessagingService>((ref) => MessagingService());
