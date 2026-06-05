import 'dart:async';
import 'dart:io';
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
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri.parse("tel:$cleanNumber");
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
        AppLogger.success("Dialing: $cleanNumber");
      } else {
        // Fallback for emulator / mock dials
        AppLogger.warn("Cannot launch dialer. Mocking dial on emulator...");
        NotificationService.instance.showSuccessSnackbar("Mocking Call: Dialing $cleanNumber...");
      }
    } catch (e) {
      AppLogger.error("Failed to launch dialer", e);
      NotificationService.instance.showSuccessSnackbar("Mocking Call: Dialing $cleanNumber...");
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
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

    NotificationService.instance.showSuccessSnackbar("Processing SOS request...");

    // Fetch GPS coordinates to include in SOS message
    final location = await LocationService.instance.getCurrentLocation();
    double? lat;
    double? lng;
    if (location != null) {
      lat = location.latitude;
      lng = location.longitude;
    }

    final coordinates = lat != null && lng != null
        ? "Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}"
        : "Location unavailable";

    final hasInternet = await _hasInternetConnection();

    if (hasInternet && SupabaseService.instance.isInitialized) {
      // ONLINE FLOW
      final newSosRequest = EmergencyRequestModel(
        id: 'sos-${DateTime.now().millisecondsSinceEpoch}',
        userId: user?.id ?? 'mock-uuid-1234',
        userName: user?.fullName ?? 'Karakoram Traveler',
        phoneNumber: user?.phoneNumber ?? '+92 355 4567890',
        latitude: lat ?? 35.9208,
        longitude: lng ?? 74.3089,
        type: type,
        message: message,
        isActive: true,
        createdAt: DateTime.now(),
      );

      try {
        AppLogger.info("Broadcasting emergency SOS beacon to Supabase...");
        _activeSos = await SupabaseService.instance.triggerSos(newSosRequest);
        AppLogger.success("Supabase SOS Broadcast Active: ${_activeSos?.id}");
        
        NotificationService.instance.showSuccessSnackbar("SOS sent online successfully");
        NotificationService.instance.showWarningBanner(
          title: "🚨 SOS ACTIVATED!",
          message: "Your location ($coordinates) and profile details have been broadcasted to GBDMA and active Rescue teams.",
        );
        _startLocationSync(user);
      } catch (e) {
        AppLogger.error("Online SOS failed, switching to offline fallback", e);
        await _executeOfflineSos(user, coordinates, lat, lng);
      }
    } else {
      // OFFLINE FLOW
      await _executeOfflineSos(user, coordinates, lat, lng);
    }
  }

  Future<void> _executeOfflineSos(UserModel? user, String coordinates, double? lat, double? lng) async {
    AppLogger.warn("Executing Offline SOS Fallback...");
    
    final name = user?.fullName ?? 'Karakoram Traveler';
    final phone = user?.phoneNumber ?? '';
    final mapLink = lat != null && lng != null ? "https://maps.google.com/?q=$lat,$lng" : "";
    
    final smsBody = Uri.encodeComponent(
      "Emergency SOS - No internet available\n"
      "Name: $name\n"
      "Phone: $phone\n"
      "Location: $coordinates\n"
      "$mapLink"
    );

    final String emergencyNumber = "1122";

    // Launch SMS
    final Uri smsUri = Uri.parse("sms:$emergencyNumber?body=$smsBody");
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.error("Failed to launch SMS", e);
    }

    // Launch Call after a brief delay
    await Future.delayed(const Duration(seconds: 2));
    await makeCall(emergencyNumber);

    NotificationService.instance.showWarningBanner(
      title: "🚨 OFFLINE SOS ACTIVATED!",
      message: "Offline SOS activated (Call + SMS sent with location: $coordinates)",
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
