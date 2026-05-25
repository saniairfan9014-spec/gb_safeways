import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../../features/auth/model/user_model.dart';
import '../../features/roads/model/road_model.dart';
import '../../features/reports/model/report_model.dart';
import '../../features/reports/model/alert_model.dart';
import '../../features/emergency/model/emergency_request_model.dart';
import '../../features/home/model/location_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();



  bool _isInitialized = false;



  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (_isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }

  /// Initialize Supabase. If credentials are missing or connection fails, runs in local mock mode.
  Future<void> initialize({String? url, String? anonKey}) async {
    if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
      AppLogger.warn("Supabase credentials not provided. Running in LOCAL MOCK MODE.");
      _isInitialized = false;



      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      _isInitialized = true;
      AppLogger.success("Supabase initialized successfully!");
    } catch (e) {
      AppLogger.error("Failed to initialize Supabase. Falling back to LOCAL MOCK MODE", e);
      _isInitialized = false;
    }
  }

  // =====================================================================
  // AUTHENTICATION APIS
  // =====================================================================

  /// Email & Password Sign Up. Synchronizes a public.users profile automatically via DB triggers.
  Future<UserModel?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (!_isInitialized || client == null) return null;

    try {
      final response = await client!.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'avatar_url': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=0284C7&color=fff&bold=true',
        },
      ).timeout(const Duration(seconds: 6));

      final authUser = response.user;
      if (authUser == null) throw Exception("Sign up returned empty user session.");

      // Perform explicit upsert into the public.users table (new schema alignment)
      try {
        await client!.from('users').upsert({
          'id': authUser.id,
          'name': fullName,
          'phone': '+92 355 4567890',
          'avatar': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=0284C7&color=fff&bold=true',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (upsertError) {
        AppLogger.warn("Non-blocking signup profile upsert failure: $upsertError");
      }

      // Fetch the public.users record which has been automatically populated.
      return await fetchUserProfile(authUser.id);
    } catch (e) {
      AppLogger.error("Supabase sign up failed", e);
      rethrow;
    }
  }

  /// Email & Password Login
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized || client == null) return null;

    try {
      final response = await client!.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 6));

      final authUser = response.user;
      if (authUser == null) throw Exception("Login returned empty user session.");

      return await fetchUserProfile(authUser.id);
    } catch (e) {
      AppLogger.error("Supabase login failed", e);
      rethrow;
    }
  }

  /// Log out from session
  Future<void> logout() async {
    if (!_isInitialized || client == null) return;
    try {
      await client!.auth.signOut();
    } catch (e) {
      AppLogger.error("Supabase sign out failed", e);
    }
  }

  /// Fetch public user profile
  Future<UserModel?> fetchUserProfile(String userId) async {
    if (!_isInitialized || client == null) return null;

    try {
      final data = await client!
          .from('users')
          .select()
          .eq('id', userId)
          .single()
          .timeout(const Duration(seconds: 5));

      return UserModel.fromJson(data);
    } catch (e) {
      AppLogger.error("Failed to fetch public profile for user $userId", e);
      return null;
    }
  }

  // =====================================================================
  // ROADS CONDITIONAL APIS
  // =====================================================================

  /// Fetch all active regional roads
  Future<List<RoadModel>> fetchRoads() async {
    if (!_isInitialized || client == null) return [];

    try {
      final List<dynamic> data = await client!
          .from('roads')
          .select()
          .timeout(const Duration(seconds: 5));

      return data.map((json) => RoadModel.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error("Failed to fetch roads from Supabase, returning empty", e);
      rethrow;
    }
  }

  /// Update road state (blocked/caution/open) with dispatcher remarks
  Future<void> updateRoadStatus({
    required String roadId,
    required String status,
    required String description,
    required String weather,
    required double safetyRating,
  }) async {
    if (!_isInitialized || client == null) return;

    try {
      await client!.from('roads').update({
        'status': status,
        'description': description,
        'weather': weather,
        'safety_rating': safetyRating,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', roadId).timeout(const Duration(seconds: 5));
      
      AppLogger.success("Supabase updated road status: $roadId -> $status");
    } catch (e) {
      AppLogger.error("Failed to update road status on Supabase", e);
      rethrow;
    }
  }

  // =====================================================================
  // HAZARD REPORTS APIS
  // =====================================================================

  /// Fetch all active hazard reports
  Future<List<ReportModel>> fetchReports() async {
    if (!_isInitialized || client == null) return [];

    try {
      final List<dynamic> data = await client!
          .from('reports')
          .select('*, users(name, avatar), roads(name)')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 5));

      // Filter out resolved/verified reports in Dart memory to be fully compatible with differing schemas
      return data
          .map((json) => ReportModel.fromJson(json))
          .where((report) => !report.isResolved)
          .toList();
    } catch (e) {
      AppLogger.error("Failed to fetch active hazard reports from Supabase", e);
      rethrow;
    }
  }

  /// Submit a new traveler road hazard report
  Future<ReportModel?> submitReport(ReportModel report) async {
    if (!_isInitialized || client == null) return null;

    try {
      final Map<String, dynamic> rawJson = report.toJson();
      // Remove mock ID if it doesn't match a proper UUID format
      if (rawJson['id'] == null || !RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(rawJson['id'].toString())) {
        rawJson.remove('id');
      }

      final List<dynamic> response = await client!
          .from('reports')
          .insert(rawJson)
          .select()
          .timeout(const Duration(seconds: 6));

      if (response.isNotEmpty) {
        // Increment community points for contributor
        await _incrementUserContribution(report.userId);
        return ReportModel.fromJson(response.first);
      }
      return null;
    } catch (e) {
      AppLogger.error("Failed to insert safety report to Supabase", e);
      rethrow;
    }
  }

  /// Upvote a specific report to validate credibility
  Future<void> upvoteReport(String reportId, int currentUpvotes) async {
    if (!_isInitialized || client == null) return;

    try {
      await client!.from('reports').update({
        'upvotes': currentUpvotes + 1,
      }).eq('id', reportId).timeout(const Duration(seconds: 4));
    } catch (e) {
      AppLogger.error("Failed to upvote report $reportId in Supabase", e);
      rethrow;
    }
  }

  /// Resolve an active report
  Future<void> resolveReport(String reportId) async {
    if (!_isInitialized || client == null) return;

    try {
      await client!.from('reports').update({
        'is_resolved': true,
        'status': 'verified', // Support both boolean and enum schema fields for maximum resilience
      }).eq('id', reportId).timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLogger.error("Failed to resolve report $reportId in Supabase", e);
      rethrow;
    }
  }

  /// Update an active report's status (pending/verified/rejected)
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    if (!_isInitialized || client == null) return;

    try {
      await client!.from('reports').update({
        'status': status,
        'is_resolved': status == 'verified' || status == 'rejected',
      }).eq('id', reportId).timeout(const Duration(seconds: 5));
      AppLogger.success("Supabase updated report status: $reportId -> $status");
    } catch (e) {
      AppLogger.error("Failed to update report status on Supabase", e);
      rethrow;
    }
  }

  /// Sync contributor points dynamically in background
  Future<void> _incrementUserContribution(String userId) async {
    if (!_isInitialized || client == null) return;
    try {
      final user = await fetchUserProfile(userId);
      if (user != null) {
        final newPoints = user.contributionsCount + 1;
        String newBadge = "Basecamp Guide";
        if (newPoints >= 10) {
          newBadge = "Himalayan Sherpa";
        } else if (newPoints >= 5) {
          newBadge = "Karakoram Sentinel";
        }

        await client!.from('users').update({
          'contributions_count': newPoints,
          'badge': newBadge,
        }).eq('id', userId);
      }
    } catch (e) {
      AppLogger.warn("Non-blocking failure: Unable to update contributor points in Supabase.");
    }
  }

  // =====================================================================
  // EMERGENCY SOS BROADCAST APIS
  // =====================================================================

  /// Submit a critical emergency SOS signal
  Future<EmergencyRequestModel?> triggerSos(EmergencyRequestModel request) async {
    if (!_isInitialized || client == null) return null;

    try {
      final Map<String, dynamic> rawJson = request.toJson();
      // Remove mock ID if it doesn't match a proper UUID format
      if (rawJson['id'] == null || !RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(rawJson['id'].toString())) {
        rawJson.remove('id');
      }

      final List<dynamic> response = await client!
          .from('emergency_requests')
          .insert(rawJson)
          .select()
          .timeout(const Duration(seconds: 6));

      if (response.isNotEmpty) {
        return EmergencyRequestModel.fromJson(response.first);
      }
      return null;
    } catch (e) {
      AppLogger.error("Failed to trigger SOS broadcast in Supabase", e);
      rethrow;
    }
  }

  /// Update an SOS distress beacons lifecycle (e.g. resolve it)
  Future<void> updateSosStatus(String requestId, String status) async {
    if (!_isInitialized || client == null) return;

    try {
      await client!.from('emergency_requests').update({
        'status': status,
      }).eq('id', requestId).timeout(const Duration(seconds: 4));
    } catch (e) {
      AppLogger.error("Failed to update SOS status in Supabase", e);
      rethrow;
    }
  }

  // =====================================================================
  // SAFETY ALERTS APIS
  // =====================================================================

  /// Fetch dispatcher active emergency broadcast announcements
  Future<List<AlertModel>> fetchAlerts() async {
    if (!_isInitialized || client == null) return [];

    try {
      final List<dynamic> data = await client!
          .from('alerts')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 5));

      return data.map((json) => AlertModel.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error("Failed to fetch official alerts from Supabase", e);
      rethrow;
    }
  }

  // =====================================================================
  // LIVE GPS TRACKING APIS
  // =====================================================================

  /// Stream live GPS tracking updates
  Future<void> syncUserLocation(UserLocationModel location) async {
    if (!_isInitialized || client == null) return;

    try {
      await client!.from('locations').upsert(location.toJson()).timeout(const Duration(seconds: 3));
    } catch (e) {
      AppLogger.warn("Non-blocking location sync timeout.");
    }
  }

  /// Fetch report and emergency counts for a specific user.
  Future<Map<String, int>> fetchUserStats(String userId) async {
    if (!_isInitialized || client == null) {
      return {'reports': 0, 'emergencies': 0};
    }

    try {
      final reportsRes = await client!
          .from('reports')
          .select('id')
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));
      final reportsCount = (reportsRes as List).length;

      final emergencyRes = await client!
          .from('emergency_requests')
          .select('id')
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));
      final emergencyCount = (emergencyRes as List).length;

      return {
        'reports': reportsCount,
        'emergencies': emergencyCount,
      };
    } catch (e) {
      AppLogger.error("Failed to fetch user stats for $userId", e);
      return {'reports': 0, 'emergencies': 0};
    }
  }

  // =====================================================================
  // REAL-TIME SYNC HANDLERS
  // =====================================================================

  /// Listens to postgres inserts/updates/deletes on any given table 
  /// and executes a callback immediately. Extremely useful for real-time UI maps.
  RealtimeChannel? subscribeToTableChanges({
    required String tableName,
    required String channelId,
    required void Function(PostgresChangePayload payload) onEvent,
  }) {
    if (!_isInitialized || client == null) return null;

    try {
      final channel = client!.channel(channelId);
      
      final activeChannel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: tableName,
        callback: onEvent,
      );

      activeChannel.subscribe();
      AppLogger.success("Real-time active subscription: public.$tableName -> [$channelId]");
      return activeChannel;
    } catch (e) {
      AppLogger.error("Failed to activate Real-time changes for public.$tableName", e);
      return null;
    }
  }

  /// Safely release a real-time listening channel
  Future<void> unsubscribeChannel(RealtimeChannel? channel) async {
    if (!_isInitialized || client == null || channel == null) return;
    try {
      await client!.removeChannel(channel);
      AppLogger.info("Released Real-time channel: ${channel.topic}");
    } catch (e) {
      AppLogger.error("Failed to release Real-time channel", e);
    }
  }
}
