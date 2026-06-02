import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/utils/logger.dart';
import '../model/road_model.dart';

class RoadController extends ChangeNotifier {
  final List<RoadModel> _roads = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = "";
  String _statusFilter = "All";
  bool _showCommunity = false;
  RealtimeChannel? _roadChannel;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  List<RoadModel> get roads => List.unmodifiable(_roads);
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  List<RoadModel> get filteredRoads {
    return _roads.where((road) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          road.name.toLowerCase().contains(query) ||
          road.origin.toLowerCase().contains(query) ||
          road.destination.toLowerCase().contains(query);

      final matchesFilter = _statusFilter == "All" ||
          road.status.toLowerCase() == _statusFilter.toLowerCase();

      final matchesVerification = _showCommunity ? true : road.isVerified;

      return matchesSearch && matchesFilter && matchesVerification;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Constructor — fetch on init
  // ---------------------------------------------------------------------------

  RoadController() {
    loadRoads();
  }

  // ---------------------------------------------------------------------------
  // Core data loading
  // ---------------------------------------------------------------------------

  /// Fetch all roads from Supabase. Starts the realtime subscription on first
  /// successful load.
  Future<void> loadRoads() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!SupabaseService.instance.isInitialized) {
        _errorMessage = "Service unavailable. Please check your connection.";
        AppLogger.warn("RoadController: Supabase not initialized.");
        return;
      }

      AppLogger.info("Fetching roads from Supabase...");
      final loadedRoads = await SupabaseService.instance.fetchRoads();

      _roads
        ..clear()
        ..addAll(loadedRoads);

      // Subscribe once after first successful load
      _subscribeToRealtimeUpdates();
    } on PostgrestException catch (e) {
      _errorMessage = "Database error: ${e.message}";
      AppLogger.error("RoadController: PostgrestException during loadRoads", e);
    } catch (e) {
      _errorMessage = "Failed to load roads. Pull down to retry.";
      AppLogger.error("RoadController: Unexpected error during loadRoads", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Realtime subscription — granular event handling
  // ---------------------------------------------------------------------------

  void _subscribeToRealtimeUpdates() {
    if (_roadChannel != null) return; // Already subscribed

    _roadChannel = SupabaseService.instance.subscribeToTableChanges(
      tableName: 'roads',
      channelId: 'roads-realtime-sync',
      onEvent: _handleRealtimeEvent,
    );
  }

  /// Handle individual Postgres change events without re-fetching everything.
  void _handleRealtimeEvent(PostgresChangePayload payload) {
    final eventType = payload.eventType;
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    AppLogger.info(
      "Realtime roads event: ${eventType.name} | "
      "new=${newRecord.isNotEmpty} old=${oldRecord.isNotEmpty}",
    );

    switch (eventType) {
      case PostgresChangeEvent.insert:
        if (newRecord.isNotEmpty) {
          try {
            final road = RoadModel.fromJson(newRecord);
            // Avoid duplicates (e.g. if we just submitted this road ourselves)
            if (!_roads.any((r) => r.id == road.id)) {
              _roads.add(road);
              notifyListeners();
              AppLogger.success("Realtime INSERT: added '${road.name}'");
            }
          } catch (e) {
            AppLogger.error("Failed to parse realtime INSERT payload", e);
          }
        }
        break;

      case PostgresChangeEvent.update:
        if (newRecord.isNotEmpty) {
          try {
            final updatedRoad = RoadModel.fromJson(newRecord);
            final idx = _roads.indexWhere((r) => r.id == updatedRoad.id);
            if (idx != -1) {
              _roads[idx] = updatedRoad;
              notifyListeners();
              AppLogger.success("Realtime UPDATE: patched '${updatedRoad.name}'");
            }
          } catch (e) {
            AppLogger.error("Failed to parse realtime UPDATE payload", e);
          }
        }
        break;

      case PostgresChangeEvent.delete:
        final deletedId = oldRecord['id']?.toString();
        if (deletedId != null) {
          final removed = _roads.removeWhere((r) => r.id == deletedId);
          notifyListeners();
          AppLogger.success("Realtime DELETE: removed road '$deletedId'");
        }
        break;

      default:
        // PostgresChangeEvent.all — should not reach here with granular handling
        AppLogger.info("Realtime: unhandled event type '${eventType.name}', refreshing.");
        loadRoads();
    }
  }

  // ---------------------------------------------------------------------------
  // Filters & search
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Community road submission
  // ---------------------------------------------------------------------------

  /// Submit a new community road (unverified) on behalf of the current user.
  Future<void> submitRoad(RoadModel road) async {
    final userId =
        SupabaseService.instance.client?.auth.currentUser?.id ?? '';
    final roadToSubmit = road.copyWith(
      isVerified: false,
      createdBy: userId,
    );

    await SupabaseService.instance.submitCustomRoad(roadToSubmit);
    // Refresh list after submission
    await loadRoads();
  }

  // ---------------------------------------------------------------------------
  // Road status update
  // ---------------------------------------------------------------------------

  /// Update road safety status. Syncs to backend and applies optimistic local
  /// update immediately so the UI feels instant.
  Future<void> updateRoadStatus(
    String roadId,
    String newStatus,
    String newDescription,
    String newWeather,
    double safetyRating,
  ) async {
    // 1. Optimistic local update
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

    // 2. Sync to Supabase
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
        AppLogger.warn(
          "Road update failed on backend. Local state may diverge: $e",
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Disposal
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    if (_roadChannel != null) {
      SupabaseService.instance.unsubscribeChannel(_roadChannel);
      _roadChannel = null;
    }
    super.dispose();
  }
}
