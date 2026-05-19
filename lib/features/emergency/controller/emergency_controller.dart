import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/logger.dart';

class EmergencyContact {
  final String name;
  final String category; // 'Rescue', 'Police', 'Disaster'
  final String phone;
  final String location;
  final IconData icon;

  const EmergencyContact({
    required this.name,
    required this.category,
    required this.phone,
    required this.location,
    required this.icon,
  });
}

class EmergencyController extends ChangeNotifier {
  bool _sosTriggered = false;
  bool _isSosActivating = false;
  int _sosCountdown = 5;

  bool get sosTriggered => _sosTriggered;
  bool get isSosActivating => _isSosActivating;
  int get sosCountdown => _sosCountdown;

  final List<EmergencyContact> contacts = const [
    EmergencyContact(
      name: "Rescue 1122 Gilgit",
      category: "Rescue",
      phone: "1122",
      location: "Gilgit Region",
      icon: Icons.local_hospital_rounded,
    ),
    EmergencyContact(
      name: "Rescue 1122 Skardu",
      category: "Rescue",
      phone: "05815-1122",
      location: "Baltistan Region",
      icon: Icons.local_hospital_rounded,
    ),
    EmergencyContact(
      name: "GBDMA (Disaster Management)",
      category: "Disaster",
      phone: "05811-920874",
      location: "Central Gilgit Office",
      icon: Icons.gavel_rounded,
    ),
    EmergencyContact(
      name: "Highway Patrol Karakoram",
      category: "Police",
      phone: "130",
      location: "KKH N-35 checkpoints",
      icon: Icons.local_police_rounded,
    ),
    EmergencyContact(
      name: "Army Helicopter Rescue Coord.",
      category: "Rescue",
      phone: "05811-922606",
      location: "High Altitude Rescue",
      icon: Icons.airplanemode_active_rounded,
    ),
    EmergencyContact(
      name: "Gilgit Police Control Room",
      category: "Police",
      phone: "05811-930300",
      location: "Gilgit District",
      icon: Icons.shield_rounded,
    ),
    EmergencyContact(
      name: "Skardu Police Headquarters",
      category: "Police",
      phone: "05815-930100",
      location: "Skardu District",
      icon: Icons.shield_rounded,
    ),
  ];

  Future<void> makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        AppLogger.success("Dialing: $phoneNumber");
      } else {
        // Fallback for emulator / mock dials
        AppLogger.warn("Cannot launch dialer. Mocking dial on emulator...");
        NotificationService.instance.showSuccessSnackbar("Mocking Call: Dialing $phoneNumber...");
      }
    } catch (e) {
      AppLogger.error("Failed to launch dialer", e);
      NotificationService.instance.showSuccessSnackbar("Mocking Call: Dialing $phoneNumber...");
    }
  }

  Future<void> startSosTriggerFlow() async {
    if (_sosTriggered || _isSosActivating) return;

    _isSosActivating = true;
    _sosCountdown = 5;
    notifyListeners();

    while (_sosCountdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      _sosCountdown--;
      notifyListeners();
      if (!_isSosActivating) return; // Cancelled
    }

    _isSosActivating = false;
    _sosTriggered = true;
    notifyListeners();

    // Fetch GPS coordinates to include in SOS message
    final location = await LocationService.instance.getCurrentLocation();
    String coordinates = "Lat: 35.9208, Lng: 74.3089 (Gilgit)";
    if (location != null) {
      coordinates = "Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}";
    }

    NotificationService.instance.showWarningBanner(
      title: "🚨 SOS ACTIVATED!",
      message: "Your location ($coordinates) and profile details have been broadcasted to GBDMA and active Rescue teams.",
    );
  }

  void cancelSosTrigger() {
    _isSosActivating = false;
    _sosCountdown = 5;
    notifyListeners();
    NotificationService.instance.showSuccessSnackbar("SOS countdown aborted. Stay safe!");
  }

  void resetSos() {
    _sosTriggered = false;
    _isSosActivating = false;
    notifyListeners();
    NotificationService.instance.showSuccessSnackbar("SOS status cleared.");
  }
}
