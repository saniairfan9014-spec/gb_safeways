import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Tracks report IDs this user has already confirmed. Persisted locally.
  final Set<String> _confirmedReportIds = {};

  List<ReportModel> get reports {
    final sorted = List<ReportModel>.from(_reports);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;

  List<ReportModel> get activeReports => reports.where((r) => !r.isResolved).toList();

  /// Returns true if the current user has already confirmed this report.
  bool hasConfirmed(String reportId) => _confirmedReportIds.contains(reportId);

  ReportController() {
    _loadConfirmedIds();
    loadReports();
  }

  Future<void> _loadConfirmedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('confirmed_report_ids') ?? [];
      _confirmedReportIds.addAll(saved);
      notifyListeners();
    } catch (e) {
      AppLogger.warn("Failed to load confirmed report IDs: $e");
    }
  }

  Future<void> _saveConfirmedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('confirmed_report_ids', _confirmedReportIds.toList());
    } catch (e) {
      AppLogger.warn("Failed to save confirmed report IDs: $e");
    }
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
              final newRecord = payload.newRecord;
              
              if (payload.eventType == PostgresChangeEvent.insert && newRecord.isNotEmpty) {
                final newUserId = newRecord['user_id']?.toString() ?? '';
                final currentUserId = SupabaseService.instance.client?.auth.currentUser?.id;
                
                // Add to local list immediately
                try {
                  final newReport = ReportModel.fromJson(newRecord);
                  if (!_reports.any((r) => r.id == newReport.id)) {
                    _reports.insert(0, newReport);
                    notifyListeners();
                  }
                } catch (e) {
                  AppLogger.warn("Failed to parse realtime report insert: $e");
                }
                
                if (newUserId != currentUserId) {
                  final roadName = newRecord['road_name']?.toString() ?? 'a road';
                  final hazard = newRecord['hazard_type']?.toString() ?? 'Hazard';
                  NotificationService.instance.showWarningBanner(
                    title: "🚨 New Report: $hazard",
                    message: "A new hazard was just reported on $roadName. Pull to refresh for details.",
                  );
                }
              } 
              else if (payload.eventType == PostgresChangeEvent.update && newRecord.isNotEmpty) {
                // Update local list for upvotes etc.
                try {
                  final updatedReport = ReportModel.fromJson(newRecord);
                  final idx = _reports.indexWhere((r) => r.id == updatedReport.id);
                  if (idx != -1) {
                    // Update only fields that change, keep joined data if any
                    final old = _reports[idx];
                    _reports[idx] = old.copyWith(
                      upvotes: updatedReport.upvotes,
                      isResolved: updatedReport.isResolved,
                      status: updatedReport.status,
                      severity: updatedReport.severity,
                    );
                    notifyListeners();
                  }
                } catch (e) {
                  AppLogger.warn("Failed to parse realtime report update: $e");
                }
              }
              else if (payload.eventType == PostgresChangeEvent.delete) {
                final deletedId = payload.oldRecord['id']?.toString();
                if (deletedId != null) {
                  _reports.removeWhere((r) => r.id == deletedId);
                  notifyListeners();
                }
              }
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
      final finalReport = dbReport != null ? newReport.copyWith(id: dbReport.id) : newReport;
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

  /// Confirms an active report once per user — prevents duplicate confirmations.
  Future<void> upvoteReport(String reportId) async {
    // Guard: already confirmed by this user
    if (_confirmedReportIds.contains(reportId)) {
      NotificationService.instance.showSuccessSnackbar("You have already confirmed this report.");
      return;
    }

    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];

      // 1. Mark as confirmed locally first (optimistic)
      _confirmedReportIds.add(reportId);
      _reports[index] = report.copyWith(upvotes: report.upvotes + 1);
      notifyListeners();
      await _saveConfirmedIds();

      // 2. Sync to Supabase
      if (SupabaseService.instance.isInitialized) {
        try {
          await SupabaseService.instance.upvoteReport(reportId, report.upvotes);
        } catch (e) {
          AppLogger.warn("Upvote sync to Supabase failed — local count updated.");
        }
      }

      NotificationService.instance.showSuccessSnackbar("Report confirmed! Thanks for keeping GB roads safe. 🏔️");
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
