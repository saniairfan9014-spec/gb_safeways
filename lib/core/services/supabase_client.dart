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

  static const Duration _defaultTimeout = Duration(seconds: 8);
  static const Duration _extendedTimeout = Duration(seconds: 12);
  static const Duration _locationTimeout = Duration(seconds: 4);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client =>
      _isInitialized ? Supabase.instance.client : null;

  bool _isValidUuid(String? id) {
    if (id == null) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
  }

  Future<T> _executeWithRetry<T>(
      Future<T> Function() operation, {
        required String operationName,
        required T fallbackValue,
        Duration timeout = _defaultTimeout,
      }) async {
    if (!_isInitialized || client == null) {
      AppLogger.warn("Offline mode: $operationName");
      return fallbackValue;
    }

    try {
      return await operation().timeout(timeout);
    } catch (e) {
      AppLogger.error("Error in $operationName", e);
      return fallbackValue;
    }
  }

  Future<void> initialize({String? url, String? anonKey}) async {
    if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
      _isInitialized = false;
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    _isInitialized = true;
    AppLogger.success("Supabase initialized");
  }

  // ========================= AUTH =========================

  Future<UserModel?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _executeWithRetry<UserModel?>(
          () async {
        final res = await client!.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
          },
        );

        final user = res.user;
        if (user == null) return null;

        // Manually insert into public.users to ensure the profile exists
        // (This acts as a fallback or replacement if the SQL trigger fails/is missing)
        try {
          final existingUser = await client!.from('users').select('id').eq('id', user.id).maybeSingle();
          if (existingUser == null) {
            await client!.from('users').insert({
              'id': user.id,
              'email': email,
              'full_name': fullName,
              'avatar_url': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}',
              'phone_number': '+92 355 4567890',
            });
          }
        } catch (e) {
          AppLogger.warn("Manual user insert failed: $e");
        }

        return await fetchUserProfile(user.id);
      },
      operationName: "signUp",
      fallbackValue: null,
      timeout: _extendedTimeout,
    );
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    return _executeWithRetry<UserModel?>(
          () async {
        final res = await client!.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = res.user;
        if (user == null) return null;

        UserModel? profile = await fetchUserProfile(user.id);
        
        // If profile is missing (e.g., trigger failed or old user), auto-create it now!
        if (profile == null) {
          AppLogger.warn("Profile missing in public.users for ${user.email}. Creating now...");
          try {
            final email = user.email ?? 'unknown@email.com';
            final name = user.userMetadata?['full_name'] ?? email.split('@')[0];
            await client!.from('users').insert({
              'id': user.id,
              'email': email,
              'full_name': name,
              'avatar_url': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}',
              'phone_number': user.phone ?? '+92 355 4567890',
            });
            profile = await fetchUserProfile(user.id);
          } catch (e) {
            AppLogger.error("Failed to auto-create missing profile during login", e);
          }
        }

        return profile;
      },
      operationName: "login",
      fallbackValue: null,
    );
  }

  Future<void> logout() async {
    await client?.auth.signOut();
  }

  // ========================= FIXED PROFILE FETCH =========================

  Future<UserModel?> fetchUserProfile(String userId) async {
    if (!_isValidUuid(userId)) return null;

    return _executeWithRetry<UserModel?>(
          () async {
        final PostgrestMap? data = await client!
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (data == null) return null;

        return UserModel.fromJson(
          Map<String, dynamic>.from(data),
        );
      },
      operationName: "fetchUserProfile",
      fallbackValue: null,
    );
  }

  // ========================= ROADS =========================

  Future<List<RoadModel>> fetchRoads() async {
    return _executeWithRetry<List<RoadModel>>(
          () async {
        final data = await client!.from('roads').select();
        return (data as List)
            .map((e) => RoadModel.fromJson(e))
            .toList();
      },
      operationName: "fetchRoads",
      fallbackValue: [],
    );
  }

  // ========================= REPORTS =========================

  Future<List<ReportModel>> fetchReports() async {
    return _executeWithRetry<List<ReportModel>>(
          () async {
        final data = await client!.from('reports').select('*, users(name, avatar), roads(name)').order('created_at', ascending: false);
        return (data as List)
            .map((e) => ReportModel.fromJson(e))
            .toList();
      },
      operationName: "fetchReports",
      fallbackValue: [],
    );
  }

  Future<ReportModel?> submitReport(ReportModel report) async {
    return _executeWithRetry<ReportModel?>(
          () async {
        final response = await client!
            .from('reports')
            .insert(report.toJson())
            .select()
            .maybeSingle();

        if (response == null) return null;

        return ReportModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      },
      operationName: "submitReport",
      fallbackValue: null,
    );
  }

  // ========================= EMERGENCY =========================

  Future<EmergencyRequestModel?> triggerSos(
      EmergencyRequestModel request) async {
    return _executeWithRetry<EmergencyRequestModel?>(
          () async {
        final response = await client!
            .from('emergency_requests')
            .insert(request.toJson())
            .select()
            .maybeSingle();

        if (response == null) return null;

        return EmergencyRequestModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      },
      operationName: "triggerSos",
      fallbackValue: null,
    );
  }

  // ========================= STATS =========================

  Future<Map<String, int>> fetchUserStats(String userId) async {
    if (!_isValidUuid(userId)) {
      return {'reports': 0, 'emergencies': 0};
    }

    return _executeWithRetry<Map<String, int>>(
          () async {
        final reports = await client!
            .from('reports')
            .select('id')
            .eq('user_id', userId);

        final emergencies = await client!
            .from('emergency_requests')
            .select('id')
            .eq('user_id', userId);

        return {
          'reports': (reports as List).length,
          'emergencies': (emergencies as List).length,
        };
      },
      operationName: "fetchUserStats",
      fallbackValue: {'reports': 0, 'emergencies': 0},
    );
  }

  // ========================= ROADS MANAGEMENT & REALTIME =========================

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
      fallbackValue: null,
    );
  }

  Future<RoadModel?> submitCustomRoad(RoadModel road) async {
    return _executeWithRetry<RoadModel?>(
      () async {
        final Map<String, dynamic> payload = road.toJson();
        payload['is_verified'] = false;

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
      fallbackValue: null,
    );
  }

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

  Future<void> unsubscribeChannel(RealtimeChannel? channel) async {
    if (!_isInitialized || client == null || channel == null) return;
    try {
      await client!.removeChannel(channel);
      AppLogger.info("Released Real-time channel: ${channel.topic}");
    } catch (e) {
      AppLogger.error("Failed to release Real-time channel", e);
    }
  }

  // ========================= ALERTS =========================

  /// Fetch dispatcher active emergency broadcast announcements
  Future<List<AlertModel>> fetchAlerts() async {
    return _executeWithRetry<List<AlertModel>>(
      () async {
        final List<dynamic> data = await client!
            .from('alerts')
            .select()
            .order('created_at', ascending: false);

        if (data.isEmpty) {
          return [
            AlertModel(
              id: 'alert-mock-1',
              title: "Welcome to GB SafeWay",
              message: "Drive safely and obey speed limits across Karakoram Highway and inter-city passes.",
              severity: "Info",
              createdAt: DateTime.now(),
            )
          ];
        }

        return data
            .map((json) => AlertModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      },
      operationName: "fetchAlerts",
      fallbackValue: [],
    );
  }

  // ========================= SOS =========================

  /// Update an SOS distress beacon's lifecycle status (e.g. resolve it)
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
      fallbackValue: null,
    );
  }

  // ========================= LIVE LOCATION SYNC =========================

  /// Upsert live GPS coordinates for a user during an active SOS or tracking
  Future<void> syncUserLocation(UserLocationModel location) async {
    if (!_isValidUuid(location.id)) {
      AppLogger.warn("syncUserLocation bypassed: user ID is not a valid UUID.");
      return;
    }
    await _executeWithRetry<void>(
      () async {
        await client!.from('locations').upsert(location.toJson());
      },
      operationName: "syncUserLocation",
      timeout: _locationTimeout,
      fallbackValue: null,
    );
  }

  // ========================= REPORTS MANAGEMENT =========================

  /// Atomically increment upvotes on a report via a Postgres RPC call
  Future<void> upvoteReport(String reportId, [int? currentUpvotes]) async {
    if (!_isValidUuid(reportId)) {
      AppLogger.warn("upvoteReport bypassed: reportId is not a valid UUID.");
      return;
    }
    await _executeWithRetry<void>(
      () async {
        try {
          await client!.rpc('increment_report_upvotes', params: {
            'report_id': reportId,
          });
        } catch (e) {
          AppLogger.warn("RPC upvote failed — falling back to direct update.");
          // Fallback: direct increment if RPC function doesn't exist
          final currentData = await client!
              .from('reports')
              .select('upvotes')
              .eq('id', reportId)
              .maybeSingle();
          final current = (currentData?['upvotes'] as int?) ?? (currentUpvotes ?? 0);
          await client!.from('reports').update({
            'upvotes': current + 1,
          }).eq('id', reportId);
        }
      },
      operationName: "upvoteReport",
      fallbackValue: null,
    );
  }

  /// Update a report's status (pending / verified / rejected)
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
      fallbackValue: null,
    );
  }

  /// Mark a report as resolved (sets status to verified and is_resolved to true)
  Future<void> resolveReport(String reportId) async {
    if (!_isValidUuid(reportId)) {
      AppLogger.warn("resolveReport bypassed: reportId is not a valid UUID.");
      return;
    }
    await _executeWithRetry<void>(
      () async {
        await client!.from('reports').update({
          'status': 'verified',
          'is_resolved': true,
        }).eq('id', reportId);
      },
      operationName: "resolveReport",
      fallbackValue: null,
    );
  }
}