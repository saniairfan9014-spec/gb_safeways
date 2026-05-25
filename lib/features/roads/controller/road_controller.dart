import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/utils/logger.dart';
import '../model/road_model.dart';

class RoadController extends ChangeNotifier {
  final List<RoadModel> _roads = [];
  bool _isLoading = false;
  String _searchQuery = "";
  String _statusFilter = "All"; // 'All', 'Open', 'Caution', 'Blocked'
  bool _showCommunity = false; // false = only verified roads
  RealtimeChannel? _roadChannel;

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
          road.status.toLowerCase() == _statusFilter.toLowerCase();

      final matchesVerification = _showCommunity ? true : road.isVerified;

      return matchesSearch && matchesFilter && matchesVerification;
    }).toList();
  }

  RoadController() {
    loadRoads();
  }

  /// Load road status. Connects to Supabase backend if active, else falls back cleanly to local mock database conditions.
  Future<void> loadRoads() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<RoadModel> loadedRoads = [];

      // 1. Try to fetch from Supabase if initialized
      if (SupabaseService.instance.isInitialized) {
        AppLogger.info("Fetching roads from Supabase backend...");
        loadedRoads = await SupabaseService.instance.fetchRoads();

        // Check if 'road-other' exists. If not, dynamically insert/upsert it to avoid foreign key violations.
        final hasOther = loadedRoads.any((r) => r.id == 'road-other');
        if (!hasOther && SupabaseService.instance.client != null) {
          try {
            await SupabaseService.instance.client!.from('roads').upsert({
              'id': 'road-other',
              'name': 'Other / Custom Road',
              'status': 'Open',
              'description': 'Custom/Other reported valley roads and highways.',
              'weather': 'Clear',
              'safety_rating': 5.0,
              'origin': 'Various',
              'destination': 'Various',
              'distance_km': 0,
              'last_updated': DateTime.now().toUtc().toIso8601String(),
            });
            
            // Add to the fetched list
            loadedRoads.add(RoadModel(
              id: 'road-other',
              name: 'Other / Custom Road',
              status: 'Open',
              description: 'Custom/Other reported valley roads and highways.',
              weather: 'Clear',
              safetyRating: 5.0,
              origin: 'Various',
              destination: 'Various',
              distanceKm: 0,
              isVerified: true,
              createdBy: '',
              lastUpdated: DateTime.now(),
            ));
          } catch (e) {
            AppLogger.warn("Failed to dynamically upsert 'road-other' to Supabase: $e");
          }
        }

        // Establish real-time subscription for subsequent updates (once)
        if (_roadChannel == null) {
          _roadChannel = SupabaseService.instance.subscribeToTableChanges(
            tableName: 'roads',
            channelId: 'roads-sync',
            onEvent: (payload) {
              AppLogger.info("Supabase Realtime Alert: roads updated. Syncing view...");
              // Hot-reload list from database when changes occur
              loadRoads();
            },
          );
        }
      }

      // 2. Local Fallback/Mock preset data removed to only show database data as requested.
      if (loadedRoads.isEmpty) {
        loadedRoads = [
          RoadModel(
              id: 'road-other',
              name: 'Other / Custom Road',
              status: 'Open',
              description: 'Custom/Other reported valley roads and highways.',
              weather: 'Clear',
              safetyRating: 5.0,
              origin: 'Various',
              destination: 'Various',
              distanceKm: 0,
              isVerified: true,
              createdBy: '',
              lastUpdated: DateTime.now(),
            ),
        ];
      }

      _roads.clear();
      _roads.addAll(loadedRoads);
    } catch (e) {
      AppLogger.error("Failed to load roads status", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setShowCommunity(bool show) {
    _showCommunity = show;
    notifyListeners();
  }

  void setFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  /// Submit a new community road (unverified) on behalf of the current user.
  Future<void> submitRoad(RoadModel road) async {
    // Ensure required fields are set
    final userId = SupabaseService.instance.client?.auth.currentUser?.id ?? '';
    final roadToSubmit = road.copyWith(
      isVerified: false,
      createdBy: userId,
    );

    await SupabaseService.instance.submitCustomRoad(roadToSubmit);
    // Refresh list after submission
    await loadRoads();
  }

  /// Update road safety status. Syncs dynamically to backend database, falling back to local memory immediately.
  Future<void> updateRoadStatus(
    String roadId,
    String newStatus,
    String newDescription,
    String newWeather,
    double safetyRating,
  ) async {
    // 1. Sync update to Supabase public.roads table if connected
    if (SupabaseService.instance.isInitialized) {
      try {
        await SupabaseService.instance.updateRoadStatus(
          roadId: roadId,
          status: newStatus,
          description: newDescription,
          weather: newWeather,
          safetyRating: safetyRating,
        );
      } catch (e) {
        AppLogger.warn("Supabase road update failed due to connection. Syncing locally first.");
      }
    }

    // 2. Perform immediate local memory sync
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

  @override
  void dispose() {
    if (_roadChannel != null) {
      SupabaseService.instance.unsubscribeChannel(_roadChannel);
    }
    super.dispose();
  }
}
