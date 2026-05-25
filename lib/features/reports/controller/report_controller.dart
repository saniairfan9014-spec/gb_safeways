import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/utils/logger.dart';
import '../model/report_model.dart';
import '../model/alert_model.dart';
import '../../roads/controller/road_controller.dart';
import '../../auth/controller/auth_controller.dart';

class ReportController extends ChangeNotifier {
  final List<ReportModel> _reports = [];
  final List<AlertModel> _alerts = [];
  bool _isLoading = false;
  RealtimeChannel? _reportChannel;
  RealtimeChannel? _alertChannel;

  List<ReportModel> get reports => _reports;
  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;

  List<ReportModel> get activeReports => _reports.where((r) => !r.isResolved).toList();

  ReportController() {
    loadReports();
  }

  /// Load safety alerts and user reports. Syncs with Supabase if active, else uses presets.
  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<ReportModel> loadedReports = [];
      List<AlertModel> loadedAlerts = [];

      // 1. Try to fetch from Supabase if initialized
      if (SupabaseService.instance.isInitialized) {
        AppLogger.info("Fetching reports and alerts from Supabase backend...");
        loadedReports = await SupabaseService.instance.fetchReports();
        loadedAlerts = await SupabaseService.instance.fetchAlerts();

        // Establish real-time subscriptions for subsequent updates
        if (_reportChannel == null) {
          _reportChannel = SupabaseService.instance.subscribeToTableChanges(
            tableName: 'reports',
            channelId: 'reports-sync',
            onEvent: (payload) {
              AppLogger.info("Supabase Realtime Alert: reports updated. Syncing...");
              loadReports();
            },
          );
        }
        if (_alertChannel == null) {
          _alertChannel = SupabaseService.instance.subscribeToTableChanges(
            tableName: 'alerts',
            channelId: 'alerts-sync',
            onEvent: (payload) {
              AppLogger.info("Supabase Realtime Alert: global safety alerts updated. Syncing...");
              loadReports();
            },
          );
        }
      }

      // 2. Local Fallback/Mock reports removed to only show database data as requested.

      // 3. Local Fallback/Mock alerts removed to only show database data as requested.

      _reports.clear();
      _reports.addAll(loadedReports);

      _alerts.clear();
      _alerts.addAll(loadedAlerts);
    } catch (e) {
      AppLogger.error("Failed to load reports and alerts database", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit traveler road issue report. Syncs to Supabase, updating road statuses automatically.
  Future<bool> submitReport({
    required String roadId,
    required String roadName,
    required String hazardType,
    required String description,
    required String severity,
    String? imageUrl,
    required AuthController authController,
    required RoadController roadController,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (description.isEmpty || description.length < 10) {
        throw Exception("Please provide a description of at least 10 characters.");
      }

      if (authController.currentUser == null) {
        throw Exception("You must be signed in to submit reports.");
      }

      // Fetch location GPS coordinates.
      final location = await LocationService.instance.getCurrentLocation();
      double lat = 35.9208; // default Gilgit
      double lng = 74.3089;
      
      if (location != null) {
        lat = location.latitude;
        lng = location.longitude;
      } else {
        final preset = LocationService.presets.firstWhere(
          (p) => roadName.contains(p.name) || p.name.contains(roadName.split(' ')[0]),
          orElse: () => LocationService.presets.first,
        );
        lat = preset.latitude;
        lng = preset.longitude;
      }

      final newReport = ReportModel(
        id: 'report-${DateTime.now().millisecondsSinceEpoch}',
        userId: authController.currentUser!.id,
        userName: authController.currentUser!.fullName,
        userAvatar: authController.currentUser!.avatarUrl,
        roadId: roadId,
        roadName: roadName,
        hazardType: hazardType,
        description: description,
        severity: severity,
        latitude: lat,
        longitude: lng,
        upvotes: 0,
        isResolved: false,
        status: 'pending',
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      ReportModel? dbReport;

      // 1. Write to Supabase if active
      if (SupabaseService.instance.isInitialized) {
        try {
          dbReport = await SupabaseService.instance.submitReport(newReport);
        } catch (e) {
          AppLogger.warn("Supabase report submission failed due to connection. Saving locally.");
        }
      }

      // 2. Perform local update immediately
      final finalReport = dbReport ?? newReport;
      _reports.insert(0, finalReport);

      // Award community contributor points
      authController.incrementContribution();

      // Broadcast alert banner
      NotificationService.instance.showWarningBanner(
        title: "NEW ALERT: $hazardType on $roadName",
        message: description,
      );

      return true;
    } catch (e) {
      NotificationService.instance.showErrorSnackbar(e.toString().replaceAll("Exception: ", ""));
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upvotes an active report to increase its credibility
  Future<void> upvoteReport(String reportId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];

      // 1. Sync to Supabase if active
      if (SupabaseService.instance.isInitialized) {
        try {
          await SupabaseService.instance.upvoteReport(reportId, report.upvotes);
        } catch (e) {
          AppLogger.warn("Upvote sync to Supabase failed.");
        }
      }

      // 2. Update locally
      _reports[index] = report.copyWith(upvotes: report.upvotes + 1);
      notifyListeners();
      NotificationService.instance.showSuccessSnackbar("Upvoted report. Thanks for validating road safety!");
    }
  }

  /// Verify an active safety report and automatically adjust road status (Admin Workflow)
  Future<bool> verifyReport({
    required ReportModel report,
    required String newRoadStatus,
    required RoadController roadController,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Sync status update to Supabase
      if (SupabaseService.instance.isInitialized) {
        await SupabaseService.instance.updateReportStatus(
          reportId: report.id,
          status: 'verified',
        );
      }

      // 2. Update locally in the list
      final index = _reports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _reports[index] = _reports[index].copyWith(
          status: 'verified',
          isResolved: true,
        );
      }

      // 3. Automatically adjust road safety status based on verified status
      double safetyRating = 4.8;
      String roadWeather = "Clear";
      String roadDesc = "Previously reported hazard (${report.hazardType}) has been verified and resolved by Admin.";

      final statusLower = newRoadStatus.toLowerCase();
      if (statusLower == 'blocked') {
        safetyRating = 1.0;
        roadWeather = "Severe";
        roadDesc = "BLOCKED: Verified ${report.hazardType}. ${report.description}";
      } else if (statusLower == 'closed') {
        safetyRating = 0.5;
        roadWeather = "Adverse";
        roadDesc = "CLOSED: Verified ${report.hazardType}. ${report.description}";
      } else if (statusLower == 'slow' || statusLower == 'caution') {
        safetyRating = 2.5;
        roadWeather = "Cautionary";
        roadDesc = "SLOW TRAFFIC: Verified ${report.hazardType}. ${report.description}";
      } else if (statusLower == 'under_construction') {
        safetyRating = 3.0;
        roadWeather = "Variable";
        roadDesc = "UNDER CONSTRUCTION: Verified ${report.hazardType}. ${report.description}";
      } else {
        newRoadStatus = "Open";
      }

      await roadController.updateRoadStatus(
        report.roadId,
        newRoadStatus,
        roadDesc,
        roadWeather,
        safetyRating,
      );

      NotificationService.instance.showSuccessSnackbar(
        "Report verified! Road status updated to $newRoadStatus.",
      );
      return true;
    } catch (e) {
      AppLogger.error("Failed to verify report", e);
      NotificationService.instance.showErrorSnackbar("Failed to verify report: ${e.toString()}");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reject a false or duplicate hazard report (Admin Workflow)
  Future<bool> rejectReport({required String reportId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Sync to Supabase if active
      if (SupabaseService.instance.isInitialized) {
        await SupabaseService.instance.updateReportStatus(
          reportId: reportId,
          status: 'rejected',
        );
      }

      // 2. Update locally
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = _reports[index].copyWith(
          status: 'rejected',
          isResolved: true,
        );
      }

      NotificationService.instance.showSuccessSnackbar("Report rejected successfully.");
      return true;
    } catch (e) {
      AppLogger.error("Failed to reject report", e);
      NotificationService.instance.showErrorSnackbar("Failed to reject report: ${e.toString()}");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a report as resolved once the hazard is cleared
  Future<void> resolveReport(String reportId, RoadController roadController) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];

      // 1. Sync to Supabase if active
      if (SupabaseService.instance.isInitialized) {
        try {
          await SupabaseService.instance.resolveReport(reportId);
        } catch (e) {
          AppLogger.warn("Resolve sync to Supabase failed.");
        }
      }

      // 2. Update locally
      _reports[index] = report.copyWith(isResolved: true, status: 'verified');
      
      // Update road safety back to safe status once cleared
      await roadController.updateRoadStatus(
        report.roadId,
        'Open',
        'Previously reported blockage has been cleared. Drive safely.',
        'Clear',
        4.8,
      );

      notifyListeners();
      NotificationService.instance.showSuccessSnackbar("Marked report as resolved. Road status updated to Open!");
    }
  }

  @override
  void dispose() {
    if (_reportChannel != null) {
      SupabaseService.instance.unsubscribeChannel(_reportChannel);
    }
    if (_alertChannel != null) {
      SupabaseService.instance.unsubscribeChannel(_alertChannel);
    }
    super.dispose();
  }
}
