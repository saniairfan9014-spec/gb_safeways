import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/logger.dart';
import '../model/user_model.dart';

class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  int _reportsCount = 0;
  int _emergenciesCount = 0;
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  int get reportsCount => _currentUser?.contributionsCount ?? _reportsCount;
  int get emergenciesCount => _emergenciesCount;

  AuthController() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSession = prefs.getBool('has_session') ?? false;

      if (hasSession) {
        final email = prefs.getString('user_email') ?? 'traveler@karakoram.com';
        final name = prefs.getString('user_name') ?? 'Karakoram Adventurer';
        final phone = prefs.getString('user_phone') ?? '+92 355 4567890';
        final contributions = prefs.getInt('user_contributions') ?? 3;
        final role = prefs.getString('user_role') ?? 'user';
        final badge = _calculateBadge(contributions);

        _currentUser = UserModel(
          id: 'mock-uuid-1234',
          email: email,
          fullName: name,
          avatarUrl: AppHelpers.getRandomAvatarUrl(name),
          phoneNumber: phone,
          contributionsCount: contributions,
          badge: badge,
          role: role,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        );
        AppLogger.success("Session loaded: ${_currentUser!.fullName}");
        loadUserStats();
      }
    } catch (e) {
      AppLogger.error("Failed to load local session", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception("Please fill in all fields.");
      }

      if (!email.contains('@') || password.length < 6) {
        throw Exception("Invalid credentials. Password must be at least 6 characters.");
      }

      UserModel? userProfile;
      // 1. Attempt Supabase Login first if active
      if (SupabaseService.instance.isInitialized) {
        AppLogger.info("Attempting Supabase backend login...");
        userProfile = await SupabaseService.instance.login(email: email, password: password);
      }

      // 2. Local Fallback simulation only if Supabase is offline/inactive
      if (userProfile == null) {
        if (!SupabaseService.instance.isInitialized) {
          AppLogger.warn("Supabase auth offline/inactive. Simulating fallback session.");
          await Future.delayed(const Duration(milliseconds: 1000));
          
          final name = email.split('@')[0].toUpperCase();
          const phone = '+92 355 4567890';
          final role = email == 'admin@safeway.com' ? 'admin' : 'user';
          userProfile = UserModel(
            id: 'mock-uuid-1234',
            email: email,
            fullName: name,
            avatarUrl: AppHelpers.getRandomAvatarUrl(name),
            phoneNumber: phone,
            contributionsCount: 4,
            badge: _calculateBadge(4),
            role: role,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          );
        } else {
          throw Exception("Invalid email or password");
        }
      }

      _currentUser = userProfile;
      loadUserStats();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_session', true);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_name', _currentUser!.fullName);
      await prefs.setString('user_phone', _currentUser!.phoneNumber);
      await prefs.setString('user_role', _currentUser!.role);
      await prefs.setInt('user_contributions', _currentUser!.contributionsCount);

      NotificationService.instance.showSuccessSnackbar("Welcome, traveler ${_currentUser!.fullName}!");
      return true;
    } catch (e) {
      NotificationService.instance.showErrorSnackbar(e.toString().replaceAll("Exception: ", ""));
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({required String fullName, required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception("Please fill in all fields.");
      }
      if (password.length < 6) {
        throw Exception("Password must be at least 6 characters.");
      }

      UserModel? userProfile;
      // 1. Attempt Supabase sign up first
      if (SupabaseService.instance.isInitialized) {
        AppLogger.info("Attempting Supabase backend signup...");
        userProfile = await SupabaseService.instance.signUp(
          fullName: fullName,
          email: email,
          password: password,
        );
      }

      // 2. Local Fallback simulation
      if (userProfile == null) {
        AppLogger.warn("Supabase auth offline/inactive. Simulating fallback signup.");
        await Future.delayed(const Duration(milliseconds: 1000));
        
        const phone = '+92 355 4567890';
        userProfile = UserModel(
          id: 'mock-uuid-${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: fullName,
          avatarUrl: AppHelpers.getRandomAvatarUrl(fullName),
          phoneNumber: phone,
          contributionsCount: 0,
          badge: _calculateBadge(0),
          createdAt: DateTime.now(),
        );
      }

      _currentUser = userProfile;
      loadUserStats();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_session', true);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_name', _currentUser!.fullName);
      await prefs.setString('user_phone', _currentUser!.phoneNumber);
      await prefs.setString('user_role', _currentUser!.role);
      await prefs.setInt('user_contributions', _currentUser!.contributionsCount);

      NotificationService.instance.showSuccessSnackbar("Account created! Welcome to GB SafeRoute.");
      return true;
    } catch (e) {
      NotificationService.instance.showErrorSnackbar(e.toString().replaceAll("Exception: ", ""));
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({required String fullName, required String email, required String phoneNumber}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (fullName.isEmpty || email.isEmpty || phoneNumber.isEmpty) {
        throw Exception("Please fill in all fields.");
      }

      if (SupabaseService.instance.isInitialized && _currentUser != null) {
        AppLogger.info("Updating profile on Supabase...");
        await SupabaseService.instance.client!
            .from('users')
            .update({
              'full_name': fullName,
              'email': email,
              'phone_number': phoneNumber,
            })
            .eq('id', _currentUser!.id);
      }

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          avatarUrl: AppHelpers.getRandomAvatarUrl(fullName),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', fullName);
      await prefs.setString('user_phone', phoneNumber);

      NotificationService.instance.showSuccessSnackbar("Profile updated successfully!");
      return true;
    } catch (e) {
      AppLogger.error("Failed to update profile", e);
      NotificationService.instance.showErrorSnackbar(e.toString().replaceAll("Exception: ", ""));
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (SupabaseService.instance.isInitialized) {
      await SupabaseService.instance.logout();
    }
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    NotificationService.instance.showSuccessSnackbar("Signed out successfully.");
    notifyListeners();
  }

  void incrementContribution() async {
    if (_currentUser == null) return;
    
    final newCount = _currentUser!.contributionsCount + 1;
    final newBadge = _calculateBadge(newCount);
    
    _currentUser = _currentUser!.copyWith(
      contributionsCount: newCount,
      badge: newBadge,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_contributions', newCount);
    notifyListeners();

    NotificationService.instance.showSuccessSnackbar(
      "Report submitted! Points: $newCount. Rank: $newBadge 🎉"
    );
  }

  Future<void> loadUserStats() async {
    if (_currentUser == null) return;

    if (!SupabaseService.instance.isInitialized) {
      _reportsCount = _currentUser!.contributionsCount;
      _emergenciesCount = 2;
      notifyListeners();
      return;
    }

    try {
      final stats = await SupabaseService.instance.fetchUserStats(_currentUser!.id);
      _reportsCount = stats['reports'] ?? 0;
      _emergenciesCount = stats['emergencies'] ?? 0;

      // Sync contributionsCount and badge in current user
      _currentUser = _currentUser!.copyWith(
        contributionsCount: _reportsCount,
        badge: _calculateBadge(_reportsCount),
      );

      notifyListeners();
    } catch (e) {
      AppLogger.warn("Failed to load dynamic user stats from Supabase: $e");
    }
  }

  String _calculateBadge(int contributions) {
    if (contributions >= 10) {
      return "Himalayan Sherpa";
    } else if (contributions >= 5) {
      return "Karakoram Sentinel";
    } else {
      return "Basecamp Guide";
    }
  }
}
