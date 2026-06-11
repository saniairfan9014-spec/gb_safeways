import 'package:flutter/material.dart';
import '../model/road_model.dart';
import '../../../core/services/supabase_client.dart';

class RoadController extends ChangeNotifier {
  final List<RoadModel> _roads = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = "";
  String _statusFilter = "All";

  List<RoadModel> get roads => _roads;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;

  List<RoadModel> get filteredRoads {
    return _roads.where((road) {
      final q = _searchQuery.toLowerCase();

      final matchesSearch =
          road.name.toLowerCase().contains(q) ||
              road.origin.toLowerCase().contains(q) ||
              road.destination.toLowerCase().contains(q);

      final matchesFilter =
          _statusFilter == "All" ||
              road.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  RoadController() {
    loadRoads();
  }

  Future<void> loadRoads() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await SupabaseService.instance.fetchRoads();

      _roads
        ..clear()
        ..addAll(data);

    } catch (e) {
      _errorMessage = "Failed to load roads: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  Future<void> submitRoad(RoadModel road) async {
    await SupabaseService.instance.submitCustomRoad(road);
    await loadRoads();
  }

  Future<void> updateRoadStatus(
    String roadId,
    String status,
    String description,
    String weather,
    double safetyRating,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.instance.updateRoadStatus(
        roadId: roadId,
        status: status,
        description: description,
        weather: weather,
        safetyRating: safetyRating,
      );

      final index = _roads.indexWhere((r) => r.id == roadId);
      if (index != -1) {
        _roads[index] = _roads[index].copyWith(
          status: status,
          description: description,
          weather: weather,
          safetyRating: safetyRating,
        );
      }
    } catch (e) {
      _errorMessage = "Failed to update road status: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}