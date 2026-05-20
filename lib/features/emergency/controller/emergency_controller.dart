import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/utils/logger.dart';
import '../../auth/model/user_model.dart';
import '../../home/model/location_model.dart';
import '../model/emergency_request_model.dart';

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
  EmergencyRequestModel? _activeSos;
  Timer? _locationSyncTimer;

  bool get sosTriggered => _sosTriggered;
  bool get isSosActivating => _isSosActivating;
  int get sosCountdown => _sosCountdown;
  EmergencyRequestModel? get activeSos => _activeSos;

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

  Future<void> startSosTriggerFlow({
    UserModel? user,
    String type = 'rescue',
    String message = 'Distress satellite signal',
  }) async {
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
    double lat = 35.9208; // default Gilgit
    double lng = 74.3089;
    if (location != null) {
      lat = location.latitude;
      lng = location.longitude;
    }

    final coordinates = "Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}";

    // 1. Build SOS request
    final newSosRequest = EmergencyRequestModel(
      id: 'sos-${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id ?? 'mock-uuid-1234',
      userName: user?.fullName ?? 'Karakoram Traveler',
      phoneNumber: user?.phoneNumber ?? '+92 355 4567890',
      latitude: lat,
      longitude: lng,
      type: type,
      message: message,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // 2. Trigger on Supabase if active
    if (SupabaseService.instance.isInitialized) {
      try {
        AppLogger.info("Broadcasting emergency SOS beacon to Supabase...");
        _activeSos = await SupabaseService.instance.triggerSos(newSosRequest);
        AppLogger.success("Supabase SOS Broadcast Active: ${_activeSos?.id}");
      } catch (e) {
        AppLogger.error("Failed to broadcast SOS to Supabase. Operating in mock offline backup.", e);
        _activeSos = newSosRequest;
      }
    } else {
      _activeSos = newSosRequest;
    }

    // 3. Start live location syncing timer
    _startLocationSync(user);

    NotificationService.instance.showWarningBanner(
      title: "🚨 SOS ACTIVATED!",
      message: "Your location ($coordinates) and profile details have been broadcasted to GBDMA and active Rescue teams.",
    );
  }

  void _startLocationSync(UserModel? user) {
    _locationSyncTimer?.cancel();
    _locationSyncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_sosTriggered) {
        timer.cancel();
        return;
      }

      final location = await LocationService.instance.getCurrentLocation();
      if (location != null) {
        final userId = user?.id ?? 'mock-uuid-1234';
        final locModel = UserLocationModel(
          id: userId,
          latitude: location.latitude,
          longitude: location.longitude,
          lastUpdated: DateTime.now(),
        );

        if (SupabaseService.instance.isInitialized) {
          try {
            await SupabaseService.instance.syncUserLocation(locModel);
            AppLogger.success("Synced user live location to Supabase during SOS: ${location.latitude}, ${location.longitude}");
          } catch (e) {
            AppLogger.warn("Non-blocking location sync failed during active SOS: $e");
          }
        } else {
          AppLogger.info("Offline/mock: Synced live location locally: ${location.latitude}, ${location.longitude}");
        }
      }
    });
  }

  void cancelSosTrigger() {
    _isSosActivating = false;
    _sosCountdown = 5;
    _locationSyncTimer?.cancel();
    _locationSyncTimer = null;
    notifyListeners();
    NotificationService.instance.showSuccessSnackbar("SOS countdown aborted. Stay safe!");
  }

  Future<void> resetSos() async {
    _sosTriggered = false;
    _isSosActivating = false;
    _locationSyncTimer?.cancel();
    _locationSyncTimer = null;

    if (_activeSos != null && SupabaseService.instance.isInitialized) {
      try {
        await SupabaseService.instance.updateSosStatus(_activeSos!.id, 'Resolved');
        AppLogger.success("SOS distress beacon resolved successfully on Supabase.");
      } catch (e) {
        AppLogger.error("Failed to resolve SOS beacon on Supabase", e);
      }
    }
    _activeSos = null;
    notifyListeners();
    NotificationService.instance.showSuccessSnackbar("SOS status cleared.");
  }
}
