import 'package:flutter/material.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../model/report_model.dart';
import '../../roads/controller/road_controller.dart';
import '../../auth/controller/auth_controller.dart';

class ReportController extends ChangeNotifier {
  final List<ReportModel> _reports = [];
  bool _isLoading = false;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;

  List<ReportModel> get activeReports => _reports.where((r) => !r.isResolved).toList();

  ReportController() {
    loadReports();
  }

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));

    _reports.clear();
    _reports.addAll([
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
    ]);

    _isLoading = false;
    notifyListeners();
  }

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

      // Fetch location GPS coordinates. Use preset fallback if unavailable.
      final location = await LocationService.instance.getCurrentLocation();
      double lat = 35.9208; // default Gilgit
      double lng = 74.3089;
      
      if (location != null) {
        lat = location.latitude;
        lng = location.longitude;
      } else {
        // Find if we have a matching preset for the road name
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

      // Insert at the top of reports
      _reports.insert(0, newReport);

      // Award community contributor points to the user
      authController.incrementContribution();

      // Automatically dynamically adjust the status of the road in RoadController!
      String newRoadStatus = 'Caution';
      double safetyRating = 3.0;
      if (severity == 'High') {
        newRoadStatus = 'Blocked';
        safetyRating = 1.0;
      } else if (severity == 'Medium') {
        newRoadStatus = 'Caution';
        safetyRating = 2.5;
      }

      roadController.updateRoadStatus(
        roadId,
        newRoadStatus,
        "$hazardType alert: $description",
        "Unsettled",
        safetyRating,
      );

      // Broadcast warning to all other travelers in the app using NotificationService banner
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

  void upvoteReport(String reportId) {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      _reports[index] = report.copyWith(upvotes: report.upvotes + 1);
      notifyListeners();
      NotificationService.instance.showSuccessSnackbar("Upvoted report. Thanks for validating road safety!");
    }
  }

  void resolveReport(String reportId, RoadController roadController) {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      _reports[index] = report.copyWith(isResolved: true);
      
      // Update road safety back to safe status once cleared
      roadController.updateRoadStatus(
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
}
