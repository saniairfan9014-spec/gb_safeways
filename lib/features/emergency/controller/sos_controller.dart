import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/notification_service.dart';
import '../model/sos_alert_model.dart';

class SosController extends ChangeNotifier {
  bool _isLoading = false;
  List<SosAlertModel> _myHistory = [];
  List<SosAlertModel> _adminActiveAlerts = [];

  bool get isLoading => _isLoading;
  List<SosAlertModel> get myHistory => _myHistory;
  List<SosAlertModel> get adminActiveAlerts => _adminActiveAlerts;

  static const String _mockStorageKey = 'mock_sos_alerts';

  // Submit a new SOS alert
  Future<bool> submitSosAlert({
    required String userId,
    required String emergencyType,
    String? description,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    notifyListeners();

    final newAlert = SosAlertModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      emergencyType: emergencyType,
      description: description,
      latitude: latitude,
      longitude: longitude,
      status: 'active',
      createdAt: DateTime.now(),
    );

    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        AppLogger.info("Submitting SOS alert to Supabase...");
        final response = await SupabaseService.instance.client!
            .from('sos_alerts')
            .insert(newAlert.toJson())
            .select()
            .single();

        final savedAlert = SosAlertModel.fromJson(response);
        _myHistory.insert(0, savedAlert);
        AppLogger.success("SOS Alert saved to Supabase: ${savedAlert.id}");
      } else {
        AppLogger.warn("Supabase not initialized. Simulating offline SOS creation.");
        await Future.delayed(const Duration(milliseconds: 800)); // simulate network delay
        
        final savedAlert = newAlert.copyWith(
          id: 'mock-uuid-${DateTime.now().millisecondsSinceEpoch}',
        );
        await _saveMockAlertLocally(savedAlert);
        _myHistory.insert(0, savedAlert);
      }
      
      NotificationService.instance.showSuccessSnackbar("Emergency SOS alert submitted successfully.");
      return true;
    } catch (e) {
      AppLogger.error("Failed to submit SOS alert", e);
      NotificationService.instance.showErrorSnackbar("Failed to submit SOS alert: ${e.toString()}");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch SOS history for a specific user
  Future<void> fetchMyHistory(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        AppLogger.info("Fetching SOS history from Supabase...");
        final List<dynamic> response = await SupabaseService.instance.client!
            .from('sos_alerts')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        _myHistory = response.map((json) => SosAlertModel.fromJson(json)).toList();
      } else {
        AppLogger.warn("Supabase not initialized. Loading local mock history.");
        await Future.delayed(const Duration(milliseconds: 500));
        final localAlerts = await _loadMockAlertsLocally();
        _myHistory = localAlerts.where((alert) => alert.userId == userId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      AppLogger.error("Failed to fetch SOS history", e);
      NotificationService.instance.showErrorSnackbar("Failed to load SOS history: ${e.toString()}");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch active SOS alerts for admin dashboard
  Future<void> fetchAdminActiveAlerts() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        AppLogger.info("Fetching active SOS alerts for admin dashboard from Supabase...");
        // Join with public.users table to retrieve full_name, email, and avatar_url
        final List<dynamic> response = await SupabaseService.instance.client!
            .from('sos_alerts')
            .select('*, users(full_name, email, avatar_url)')
            .eq('status', 'active')
            .order('created_at', ascending: false);

        _adminActiveAlerts = response.map((json) => SosAlertModel.fromJson(json)).toList();
      } else {
        AppLogger.warn("Supabase not initialized. Loading local active mock alerts.");
        await Future.delayed(const Duration(milliseconds: 500));
        final localAlerts = await _loadMockAlertsLocally();
        _adminActiveAlerts = localAlerts.where((alert) => alert.status == 'active').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      AppLogger.error("Failed to fetch admin SOS alerts", e);
      NotificationService.instance.showErrorSnackbar("Failed to load admin SOS alerts: ${e.toString()}");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark an active SOS alert as resolved
  Future<bool> resolveSosAlert(String alertId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final nowUtc = DateTime.now().toUtc();
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.client != null) {
        AppLogger.info("Resolving SOS alert on Supabase: $alertId");
        await SupabaseService.instance.client!
            .from('sos_alerts')
            .update({
              'status': 'resolved',
              'resolved_at': nowUtc.toIso8601String(),
            })
            .eq('id', alertId);
      } else {
        AppLogger.warn("Supabase not initialized. Resolving mock alert locally.");
        await Future.delayed(const Duration(milliseconds: 500));
        await _resolveMockAlertLocally(alertId, nowUtc);
      }

      // Update local state lists
      _adminActiveAlerts.removeWhere((alert) => alert.id == alertId);
      final index = _myHistory.indexWhere((alert) => alert.id == alertId);
      if (index != -1) {
        _myHistory[index] = _myHistory[index].copyWith(
          status: 'resolved',
          resolvedAt: nowUtc,
        );
      }

      NotificationService.instance.showSuccessSnackbar("SOS alert marked as resolved.");
      return true;
    } catch (e) {
      AppLogger.error("Failed to resolve SOS alert", e);
      NotificationService.instance.showErrorSnackbar("Failed to resolve alert: ${e.toString()}");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =====================================================================
  // LOCAL MOCK PERSISTENCE HELPERS
  // =====================================================================

  Future<List<SosAlertModel>> _loadMockAlertsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_mockStorageKey);
      if (jsonString == null || jsonString.isEmpty) {
        // Return default seed mock values if empty
        return _getSeedMockAlerts();
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => SosAlertModel.fromJson(j)).toList();
    } catch (e) {
      AppLogger.error("Failed to load mock alerts locally", e);
      return _getSeedMockAlerts();
    }
  }

  Future<void> _saveMockAlertLocally(SosAlertModel alert) async {
    try {
      final alerts = await _loadMockAlertsLocally();
      alerts.insert(0, alert);
      
      final prefs = await SharedPreferences.getInstance();
      final listJson = alerts.map((a) {
        final map = a.toJson();
        map['id'] = a.id; // ensure ID is preserved
        // Include mock user details so history / admin screens show name properly
        map['user_name'] = a.userName ?? 'Karakoram Adventurer';
        map['user_email'] = a.userEmail ?? 'traveler@karakoram.com';
        map['user_avatar'] = a.userAvatar ?? 'https://ui-avatars.com/api/?name=Traveler&background=0284C7&color=fff&bold=true';
        return map;
      }).toList();
      await prefs.setString(_mockStorageKey, jsonEncode(listJson));
    } catch (e) {
      AppLogger.error("Failed to save mock alert locally", e);
    }
  }

  Future<void> _resolveMockAlertLocally(String alertId, DateTime resolvedAt) async {
    try {
      final alerts = await _loadMockAlertsLocally();
      final index = alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        alerts[index] = alerts[index].copyWith(
          status: 'resolved',
          resolvedAt: resolvedAt,
        );
        final prefs = await SharedPreferences.getInstance();
        final listJson = alerts.map((a) {
          final map = a.toJson();
          map['id'] = a.id;
          map['user_name'] = a.userName ?? 'Karakoram Adventurer';
          map['user_email'] = a.userEmail ?? 'traveler@karakoram.com';
          map['user_avatar'] = a.userAvatar ?? 'https://ui-avatars.com/api/?name=Traveler&background=0284C7&color=fff&bold=true';
          return map;
        }).toList();
        await prefs.setString(_mockStorageKey, jsonEncode(listJson));
      }
    } catch (e) {
      AppLogger.error("Failed to resolve mock alert locally", e);
    }
  }

  List<SosAlertModel> _getSeedMockAlerts() {
    return [
      SosAlertModel(
        id: 'mock-uuid-seed-1',
        userId: 'mock-uuid-1234',
        emergencyType: 'Landslide',
        description: 'Road blocked near Hunza Valley, need evacuation assistance.',
        latitude: 36.3167,
        longitude: 74.6500,
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        userName: 'Karakoram Adventurer',
        userEmail: 'traveler@karakoram.com',
        userAvatar: 'https://ui-avatars.com/api/?name=Traveler&background=0284C7&color=fff&bold=true',
      ),
      SosAlertModel(
        id: 'mock-uuid-seed-2',
        userId: 'mock-uuid-other-user',
        emergencyType: 'Medical Emergency',
        description: 'Altitude sickness, severe breathing difficulties at Babusar Top.',
        latitude: 35.1481,
        longitude: 74.0494,
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        userName: 'Sania Irfan',
        userEmail: 'sania@admin.com',
        userAvatar: 'https://ui-avatars.com/api/?name=Sania+Irfan&background=10B981&color=fff&bold=true',
      ),
      SosAlertModel(
        id: 'mock-uuid-seed-3',
        userId: 'mock-uuid-1234',
        emergencyType: 'Snow Blockage',
        description: 'Snowstorm blockage at Khunjerab Pass route.',
        latitude: 36.6896,
        longitude: 74.8214,
        status: 'resolved',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 1, hours: 22)),
        userName: 'Karakoram Adventurer',
        userEmail: 'traveler@karakoram.com',
        userAvatar: 'https://ui-avatars.com/api/?name=Traveler&background=0284C7&color=fff&bold=true',
      ),
    ];
  }
}
