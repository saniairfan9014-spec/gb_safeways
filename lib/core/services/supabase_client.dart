import 'dart:async';
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

  // Production-grade customized timeouts for unstable mobile networks
  static const Duration _defaultTimeout = Duration(seconds: 8);
  static const Duration _extendedTimeout = Duration(seconds: 12);
  static const Duration _locationTimeout = Duration(seconds: 4);

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (_isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }

  /// Helper to validate standard UUID format before making database transactions
  bool _isValidUuid(String? id) {
    if (id == null) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
  }

  /// Central production request executor wrapper. Handles timeout safety,
  /// automatic logging of distinct exceptions, and initialization assertions.
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    required String operationName,
    Duration timeout = _defaultTimeout,
    required T fallbackValue,
  }) async {
    if (!_isInitialized || client == null) {
      AppLogger.warn("Supabase local bypass: $operationName executing in local/offline backup.");
      return fallbackValue;
    }

    try {
      return await operation().timeout(timeout);
    } on TimeoutException catch (e) {
      AppLogger.error("Unstable network: Timeout during '$operationName' after ${timeout.inSeconds}s.", e);
      return fallbackValue;
    } on AuthException catch (e) {
      AppLogger.error("Authentication failure during '$operationName': ${e.message}", e);
      rethrow;
    } on PostgrestException catch (e) {
      AppLogger.error("PostgreSQL database failure during '$operationName': ${e.message} (Code: ${e.code}, Details: ${e.details})", e);
      rethrow;
    } catch (e) {
      AppLogger.error("Unexpected failure during '$operationName'", e);
      rethrow;
    }
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
    return _executeWithRetry<UserModel?>(
      () async {
        final response = await client!.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'avatar_url': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=0284C7&color=fff&bold=true',
          },
        );

        final authUser = response.user;
        if (authUser == null) throw Exception("Sign up returned empty user session.");

        // The database trigger 'on_auth_user_created' automatically handles inserting 
        // the user profile into the 'public.users' table. Manual upsert has been removed
        // to maintain a single reliable user creation flow.
        return await fetchUserProfile(authUser.id);
      },
      operationName: "signUp",
      timeout: _extendedTimeout,
      fallbackValue: null,
    );
  }

  /// Email & Password Login
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    return _executeWithRetry<UserModel?>(
      () async {
        final response = await client!.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final authUser = response.user;
        if (authUser == null) throw Exception("Login returned empty user session.");

        return await fetchUserProfile(authUser.id);
      },
      operationName: "login",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  /// Log out from session
  Future<void> logout() async {
    await _executeWithRetry<void>(
      () async {
        await client!.auth.signOut();
      },
      operationName: "logout",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  /// Fetch public user profile
  Future<UserModel?> fetchUserProfile(String userId) async {
    if (!_isValidUuid(userId)) {
      AppLogger.warn("fetchUserProfile bypassed: user ID is not a valid UUID.");
      return null;
    }
    return _executeWithRetry<UserModel?>(
      () async {
        final data = await client!
            .from('users')
            .select()
            .eq('id', userId)
            .single();

        return UserModel.fromJson(data);
      },
      operationName: "fetchUserProfile",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  // =====================================================================
  // ROADS CONDITIONAL APIS
  // =====================================================================

  /// Fetch all active regional roads
  Future<List<RoadModel>> fetchRoads() async {
    return _executeWithRetry<List<RoadModel>>(
      () async {
        final List<dynamic> data = await client!.from('roads').select();
        return data.map((json) => RoadModel.fromJson(json)).toList();
      },
      operationName: "fetchRoads",
      timeout: _defaultTimeout,
      fallbackValue: [],
    );
  }

  /// Update road state (blocked/caution/open) with dispatcher remarks
  Future<void> updateRoadStatus({
    required String roadId,
    required String status,
    required String description,
    required String weather,
    required double safetyRating,
  }) async {
    await _executeWithRetry<void>(
      () async {
        await client!.from('roads').update({
          'status': status,
          'description': description,
          'weather': weather,
          'safety_rating': safetyRating,
          'last_updated': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', roadId);
        
        AppLogger.success("Supabase updated road status: $roadId -> $status");
      },
      operationName: "updateRoadStatus",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  // =====================================================================
  // COMMUNITY ROAD APIs
  // =====================================================================

  /// Submit a user‑created road (unverified by default)
  Future<RoadModel?> submitCustomRoad(RoadModel road) async {
    return _executeWithRetry<RoadModel?>(
      () async {
        final Map<String, dynamic> payload = road.toJson();
        // Ensure community flags
        payload['is_verified'] = false;
        
        // Ensure creator ID is a valid UUID or null to prevent PostgREST exceptions
        final creatorId = road.createdBy;
        payload['created_by'] = _isValidUuid(creatorId) ? creatorId : null;

        final List<dynamic> response = await client!
            .from('roads')
            .insert(payload)
            .select();

        if (response.isNotEmpty) {
          return RoadModel.fromJson(response.first);
        }
        return null;
      },
      operationName: "submitCustomRoad",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  /// Verify a pending community road (admin only)
  Future<void> verifyRoad(String roadId) async {
    await _executeWithRetry<void>(
      () async {
        await client!.from('roads').update({
          'is_verified': true,
        }).eq('id', roadId);
        AppLogger.success('Road $roadId verified');
      },
      operationName: "verifyRoad",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  /// Reject a pending community road (admin only) – optional hard delete
  Future<void> rejectRoad(String roadId, {bool hardDelete = false}) async {
    await _executeWithRetry<void>(
      () async {
        if (hardDelete) {
          await client!.from('roads').delete().eq('id', roadId);
          AppLogger.success('Road $roadId permanently deleted');
        } else {
          await client!.from('roads').update({
            'is_verified': false,
          }).eq('id', roadId);
          AppLogger.info('Road $roadId marked as rejected');
        }
      },
      operationName: "rejectRoad",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }
  // =====================================================================
  // HAZARD REPORTS APIS
  // =====================================================================

  /// Fetch all hazard reports (latest first)
  Future<List<ReportModel>> fetchReports() async {
    return _executeWithRetry<List<ReportModel>>(
      () async {
        List<dynamic> data;

        // Try fetching with user/road joins first for enriched data display.
        // Fall back to simple select if the joins fail (schema may not have
        // the expected foreign-key relationships exposed via PostgREST).
        try {
          data = await client!
              .from('reports')
              .select('*, users(name:full_name, avatar:avatar_url), roads(name)')
              .order('created_at', ascending: false);
        } catch (_) {
          data = await client!
              .from('reports')
              .select()
              .order('created_at', ascending: false);
        }

        return data.map((json) => ReportModel.fromJson(json)).toList();
      },
      operationName: "fetchReports",
      timeout: _defaultTimeout,
      fallbackValue: [],
    );
  }

  /// Submit a new traveler road hazard report
  Future<ReportModel?> submitReport(ReportModel report) async {
    return _executeWithRetry<ReportModel?>(
      () async {
        final Map<String, dynamic> dbPayload = {
          'message': '[Hazard: ${report.hazardType}] [Severity: ${report.severity}] ${report.description}',
          'image': report.imageUrl ?? '',
          'location': '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
          'status': report.status,
          'created_at': report.createdAt.toUtc().toIso8601String(),
        };

        // Standardize foreign key mapping: Ensure user_id is a valid UUID or null
        dbPayload['user_id'] = _isValidUuid(report.userId) ? report.userId : null;

        // Standardize foreign key mapping: Ensure road_id is a valid UUID or null
        dbPayload['road_id'] = _isValidUuid(report.roadId) ? report.roadId : null;

        // If the report id is a valid UUID, use it. Otherwise, let database generate it.
        if (_isValidUuid(report.id)) {
          dbPayload['id'] = report.id;
        }

        final List<dynamic> response = await client!
            .from('reports')
            .insert(dbPayload)
            .select();

        if (response.isNotEmpty) {
          final insertedReport = ReportModel.fromJson(response.first);
          // Increment community points for contributor atomically in database
          if (_isValidUuid(insertedReport.userId)) {
            await _incrementUserContribution(insertedReport.userId);
          }
          return insertedReport;
        }
        return null;
      },
      operationName: "submitReport",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  /// Upvote a specific report to validate credibility (atomic increment)
  Future<void> upvoteReport(String reportId, [int? currentUpvotes]) async {
    if (!_isValidUuid(reportId)) {
      AppLogger.warn("upvoteReport bypassed: reportId is not a valid UUID.");
      return;
    }
    await _executeWithRetry<void>(
      () async {
        // Execute atomic RPC call on database to prevent lost upvotes race conditions
        // Bypassed if 'upvotes' column doesn't exist on reports table
        try {
          await client!.rpc('increment_report_upvotes', params: {
            'report_id': reportId,
          });
        } catch (e) {
          AppLogger.warn("Database RPC for upvotes failed (column/function might be missing).");
        }
      },
      operationName: "upvoteReport",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  /// Resolve an active report
  Future<void> resolveReport(String reportId) async {
    if (!_isValidUuid(reportId)) {
      AppLogger.warn("resolveReport bypassed: reportId is not a valid UUID.");
      return;
    }
    await _executeWithRetry<void>(
      () async {
        await client!.from('reports').update({
          'status': 'verified',
        }).eq('id', reportId);
      },
      operationName: "resolveReport",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  /// Update an active report's status (pending/verified/rejected)
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    if (!_isValidUuid(reportId)) {
      AppLogger.warn("updateReportStatus bypassed: reportId is not a valid UUID.");
      return;
    }
    await _executeWithRetry<void>(
      () async {
        await client!.from('reports').update({
          'status': status,
        }).eq('id', reportId);
        AppLogger.success("Supabase updated report status: $reportId -> $status");
      },
      operationName: "updateReportStatus",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  /// Sync contributor points dynamically and atomically in background (atomic increment)
  Future<void> _incrementUserContribution(String userId) async {
    if (!_isValidUuid(userId)) {
      AppLogger.warn("_incrementUserContribution bypassed: user ID is not a valid UUID.");
      return;
    }
    await _executeWithRetry<void>(
      () async {
        // Execute atomic RPC call on database to prevent race conditions and dynamically recalculate badge
        await client!.rpc('increment_user_contributions', params: {
          'user_id': userId,
        });
      },
      operationName: "_incrementUserContribution",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  // =====================================================================
  // EMERGENCY SOS BROADCAST APIS
  // =====================================================================

  /// Submit a critical emergency SOS signal
  Future<EmergencyRequestModel?> triggerSos(EmergencyRequestModel request) async {
    return _executeWithRetry<EmergencyRequestModel?>(
      () async {
        // Build a sanitized payload matching the public.emergency_requests table schema
        final Map<String, dynamic> dbPayload = {
          'user_name': request.userName,
          'phone_number': request.phoneNumber,
          'latitude': request.latitude,
          'longitude': request.longitude,
          'status': request.isActive ? 'Active' : 'Resolved',
          'created_at': request.createdAt.toUtc().toIso8601String(),
        };

        // Standardize foreign key mapping: Ensure user_id is a valid UUID or null
        dbPayload['user_id'] = _isValidUuid(request.userId) ? request.userId : null;

        // Ensure id is a valid UUID, otherwise let Supabase generate a proper UUID
        if (_isValidUuid(request.id)) {
          dbPayload['id'] = request.id;
        }

        final List<dynamic> response = await client!
            .from('emergency_requests')
            .insert(dbPayload)
            .select();

        if (response.isNotEmpty) {
          return EmergencyRequestModel.fromJson(response.first);
        }
        return null;
      },
      operationName: "triggerSos",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  /// Update an SOS distress beacons lifecycle (e.g. resolve it)
  Future<void> updateSosStatus(String requestId, String status) async {
    if (!_isValidUuid(requestId)) {
      AppLogger.warn("updateSosStatus bypassed: requestId is not a valid UUID.");
      return;
    }
    await _executeWithRetry<void>(
      () async {
        await client!.from('emergency_requests').update({
          'status': status,
        }).eq('id', requestId);
      },
      operationName: "updateSosStatus",
      timeout: _defaultTimeout,
      fallbackValue: null,
    );
  }

  // =====================================================================
  // SAFETY ALERTS APIS
  // =====================================================================

  /// Fetch dispatcher active emergency broadcast announcements
  Future<List<AlertModel>> fetchAlerts() async {
    return _executeWithRetry<List<AlertModel>>(
      () async {
        final List<dynamic> data = await client!
            .from('alerts')
            .select()
            .order('created_at', ascending: false);

        return data.map((json) => AlertModel.fromJson(json)).toList();
      },
      operationName: "fetchAlerts",
      timeout: _defaultTimeout,
      fallbackValue: [],
    );
  }

  // =====================================================================
  // LIVE GPS TRACKING APIS
  // =====================================================================

  /// Stream live GPS tracking updates
  Future<void> syncUserLocation(UserLocationModel location) async {
    if (!_isValidUuid(location.id)) {
      AppLogger.warn("syncUserLocation bypassed: user ID is not a valid UUID.");
      return;
    }
    await _executeWithRetry<void>(
      () async {
        // Upserting with a primary key constraint on 'id' avoids duplicate rows
        await client!.from('locations').upsert(location.toJson());
      },
      operationName: "syncUserLocation",
      timeout: _locationTimeout,
      fallbackValue: null,
    );
  }

  /// Fetch report and emergency counts for a specific user.
  Future<Map<String, int>> fetchUserStats(String userId) async {
    if (!_isValidUuid(userId)) {
      AppLogger.warn("fetchUserStats bypassed: user ID is not a valid UUID.");
      return {'reports': 0, 'emergencies': 0};
    }
    return _executeWithRetry<Map<String, int>>(
      () async {
        // Optimize database queries: retrieve counts in parallel to reduce duplicate network requests
        final reportsFuture = client!
            .from('reports')
            .select('id')
            .eq('user_id', userId);
            
        final emergencyFuture = client!
            .from('emergency_requests')
            .select('id')
            .eq('user_id', userId);

        final results = await Future.wait([reportsFuture, emergencyFuture]);

        final reportsCount = (results[0] as List).length;
        final emergencyCount = (results[1] as List).length;

        return {
          'reports': reportsCount,
          'emergencies': emergencyCount,
        };
      },
      operationName: "fetchUserStats",
      timeout: _defaultTimeout,
      fallbackValue: {'reports': 0, 'emergencies': 0},
    );
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
