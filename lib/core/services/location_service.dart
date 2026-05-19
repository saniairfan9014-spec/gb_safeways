import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

class LocationPreset {
  final String name;
  final double latitude;
  final double longitude;

  const LocationPreset({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  // Presets of GB Mountain hotspots for mock reporting/locations
  static const List<LocationPreset> presets = [
    LocationPreset(name: "Gilgit City (HQ)", latitude: 35.9208, longitude: 74.3089),
    LocationPreset(name: "Hunza Valley (Aliabad)", latitude: 36.3167, longitude: 74.6500),
    LocationPreset(name: "Skardu City", latitude: 35.2971, longitude: 75.6337),
    LocationPreset(name: "Babusar Top Pass", latitude: 35.1481, longitude: 74.0494),
    LocationPreset(name: "Chilas (Karakoram)", latitude: 35.4169, longitude: 74.1017),
    LocationPreset(name: "Astore Valley", latitude: 35.3406, longitude: 74.8583),
    LocationPreset(name: "Sost (Border Custom)", latitude: 36.6896, longitude: 74.8214),
  ];

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warn("Location services are disabled. Falling back to default preset.");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warn("Location permissions are denied.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warn("Location permissions are permanently denied.");
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      AppLogger.error("Failed to get current location", e);
      return null;
    }
  }

  LocationPreset getClosestPreset(double latitude, double longitude) {
    LocationPreset closest = presets.first;
    double minDistance = double.maxFinite;

    for (final preset in presets) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        preset.latitude,
        preset.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closest = preset;
      }
    }
    return closest;
  }
}
