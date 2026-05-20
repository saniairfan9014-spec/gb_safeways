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

      // 2. Local Fallback/Mock reports if offline or uninitialized
      if (loadedReports.isEmpty) {
        AppLogger.warn("Supabase reports returning empty or inactive. Setting up mock presets.");
        await Future.delayed(const Duration(milliseconds: 600));

        loadedReports = [
          ReportModel(
            id: 'report-1',
            userId: 'uuid-sherpa',
            userName: 'Local Sherpa (Sher Ali)',
            userAvatar: 'https://ui-avatars.com/api/?name=Sher+Ali&background=0284C7&color=fff&bold=true',
            roadId: 'road-skardu',
            roadName: 'Jaglot-Skardu Road (S-1)',
            hazardType: 'Landslide',
            description: 'Huge boulders rolled down at Shengus point. Blocked both lanes. GBDMA crew is arriving soon. Avoid this route.',
            severity: 'High',
            latitude: 35.4389,
            longitude: 74.8011,
            upvotes: 24,
            isResolved: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
          ),
          ReportModel(
            id: 'report-2',
            userId: 'uuid-hiker',
            userName: 'Zahid Hunzai',
            userAvatar: 'https://ui-avatars.com/api/?name=Zahid+Hunzai&background=10B981&color=fff&bold=true',
            roadId: 'road-kkh',
            roadName: 'Karakoram Highway (N-35)',
            hazardType: 'Rockfall / Shooting Stones',
            description: 'Shooting stones reported near Haldeikish (Hunza). Minor dent on one vehicle. Rocks are still falling sporadically. Drive with caution!',
            severity: 'Medium',
            latitude: 36.3214,
            longitude: 74.6719,
            upvotes: 15,
            isResolved: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
          ),
          ReportModel(
            id: 'report-3',
            userId: 'uuid-driver',
            userName: 'Awan Transport',
            userAvatar: 'https://ui-avatars.com/api/?name=Awan+Transport&background=F59E0B&color=fff&bold=true',
            roadId: 'road-astore',
            roadName: 'Astore Valley Road',
            hazardType: 'Mudslide / Flooding',
            description: 'Water stream (Nallah) overflowing on the road near Gorikot due to rapid snowmelt. Safe for SUVs but small cars should wait.',
            severity: 'Low',
            latitude: 35.2891,
            longitude: 74.9124,
            upvotes: 8,
            isResolved: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ];
      }

      // 3. Local Fallback/Mock alerts
      if (loadedAlerts.isEmpty) {
        loadedAlerts = [
          AlertModel(
            id: 'alert-1',
            title: 'High Altitude Blizzard Notice',
            message: 'Heavy winds and zero visibility reported near Babusar Pass summit. All travelers are advised to bypass Naran-Chilas route.',
            severity: 'Danger',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          AlertModel(
            id: 'alert-2',
            title: 'Landslide Warning Skardu S-1',
            message: 'Active shooting stones near Shengus. GBDMA recommends avoiding travel on Jaglot-Skardu road until dawn.',
            severity: 'Warning',
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ];
      }

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
        createdAt: DateTime.now(),
      );

      bool syncSuccess = false;
      ReportModel? dbReport;

      // 1. Write to Supabase if active
      if (SupabaseService.instance.isInitialized) {
        try {
          dbReport = await SupabaseService.instance.submitReport(newReport);
          syncSuccess = dbReport != null;
        } catch (e) {
          AppLogger.warn("Supabase report submission failed due to connection. Saving locally.");
        }
      }

      // 2. Perform local update immediately
      final finalReport = dbReport ?? newReport;
      _reports.insert(0, finalReport);

      // Award community contributor points
      authController.incrementContribution();

      // Automatically adjust safety status in RoadController
      String newRoadStatus = 'Caution';
      double safetyRating = 3.0;
      if (severity == 'High') {
        newRoadStatus = 'Blocked';
        safetyRating = 1.0;
      } else if (severity == 'Medium') {
        newRoadStatus = 'Caution';
        safetyRating = 2.5;
      }

      await roadController.updateRoadStatus(
        roadId,
        newRoadStatus,
        "$hazardType alert: $description",
        "Unsettled",
        safetyRating,
      );

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
      _reports[index] = report.copyWith(isResolved: true);
      
      // Update road safety back to safe status once cleared
      await roadController.updateRoadStatus(
        report.roadId,
        'Open',
        'Previously reported blockage ($reportId) has been cleared. Drive safely.',
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
