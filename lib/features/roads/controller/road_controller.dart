import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../model/road_model.dart';

class RoadController extends ChangeNotifier {
  final List<RoadModel> _roads = [];
  bool _isLoading = false;
  String _searchQuery = "";
  String _statusFilter = "All"; // 'All', 'Open', 'Caution', 'Blocked'

  List<RoadModel> get roads => _roads;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  List<RoadModel> get filteredRoads {
    return _roads.where((road) {
      final matchesSearch = road.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          road.origin.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          road.destination.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _statusFilter == "All" ||
          road.status.toLowerCase() == _statusFilter.toLowerCase() ||
          (_statusFilter == "Closed" && 
              (road.status.toLowerCase() == "blocked" || road.status.toLowerCase() == "caution"));

      return matchesSearch && matchesFilter;
    }).toList();
  }

  RoadController() {
    loadRoads();
  }

  Future<void> loadRoads() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    _roads.clear();
    _roads.addAll([
      RoadModel(
        id: 'road-kkh',
        name: AppStrings.kkh,
        status: 'Caution',
        description: 'Partial mudflow blocking one lane near Attabad Lake tunnel. One-way traffic active. Drive slowly.',
        weather: 'Foggy / Drizzle',
        safetyRating: 3.5,
        origin: 'Hassan Abdal',
        destination: 'Khunjerab Pass (China Border)',
        distanceKm: 806,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 42)),
      ),
      RoadModel(
        id: 'road-skardu',
        name: AppStrings.skarduRoad,
        status: 'Blocked',
        description: 'Major landslide at Shengus. Karakoram Highway junction blocked. Heavy machinery is clearing the debris. Expected open in 8 hours.',
        weather: 'Heavy Rain',
        safetyRating: 1.2,
        origin: 'Jaglot Junction',
        destination: 'Skardu City',
        distanceKm: 167,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      RoadModel(
        id: 'road-babusar',
        name: AppStrings.babusarPass,
        status: 'Blocked',
        description: 'Seasonally closed due to heavy snow blockages at the summit (4,173m). Use Karakoram Highway via Thakot/Besham instead.',
        weather: 'Blizzard',
        safetyRating: 0.5,
        origin: 'Naran',
        destination: 'Chilas',
        distanceKm: 45,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      RoadModel(
        id: 'road-astore',
        name: AppStrings.astorRoad,
        status: 'Open',
        description: 'Road is clear and open for all vehicles. Clear visibility across Rama and Astore valley checkpoints.',
        weather: 'Sunny & Clear',
        safetyRating: 4.8,
        origin: 'Thalichi',
        destination: 'Astore City',
        distanceKm: 43,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RoadModel(
        id: 'road-ghizer',
        name: AppStrings.ghizerRoad,
        status: 'Open',
        description: 'Road open up to Phander Lake. Shandur Top pass has high winds but is passable for 4x4 vehicles only.',
        weather: 'Windy',
        safetyRating: 4.0,
        origin: 'Gilgit',
        destination: 'Chitral',
        distanceKm: 370,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      RoadModel(
        id: 'road-khunjerab',
        name: AppStrings.khunjerabPass,
        status: 'Open',
        description: 'Khunjerab Pass (4,693m) road is fully cleared. High altitude icy patches between Sost and the border. Winter tires recommended.',
        weather: 'Very Cold / Sunny',
        safetyRating: 4.2,
        origin: 'Sost',
        destination: 'Khunjerab Top',
        distanceKm: 85,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void updateRoadStatus(String roadId, String newStatus, String newDescription, String newWeather, double safetyRating) {
    final index = _roads.indexWhere((road) => road.id == roadId);
    if (index != -1) {
      _roads[index] = _roads[index].copyWith(
        status: newStatus,
        description: newDescription,
        weather: newWeather,
        safetyRating: safetyRating,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }
}
