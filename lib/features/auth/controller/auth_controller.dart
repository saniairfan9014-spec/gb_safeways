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
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

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
        final contributions = prefs.getInt('user_contributions') ?? 3;
        final badge = _calculateBadge(contributions);

        _currentUser = UserModel(
          id: 'mock-uuid-1234',
          email: email,
          fullName: name,
          avatarUrl: AppHelpers.getRandomAvatarUrl(name),
          contributionsCount: contributions,
          badge: badge,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        );
        AppLogger.success("Session loaded: ${_currentUser!.fullName}");
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

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception("Please fill in all fields.");
      }

      if (!email.contains('@') || password.length < 6) {
        throw Exception("Invalid credentials. Password must be at least 6 characters.");
      }

      // Handle Mock login success
      final name = email.split('@')[0].toUpperCase();
      _currentUser = UserModel(
        id: 'mock-uuid-1234',
        email: email,
        fullName: name,
        avatarUrl: AppHelpers.getRandomAvatarUrl(name),
        contributionsCount: 4,
        badge: _calculateBadge(4),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_session', true);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name);
      await prefs.setInt('user_contributions', 4);

      NotificationService.instance.showSuccessSnackbar("Welcome, traveler $name!");
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

    await Future.delayed(const Duration(milliseconds: 1800));

    try {
      if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception("Please fill in all fields.");
      }
      if (password.length < 6) {
        throw Exception("Password must be at least 6 characters.");
      }

      _currentUser = UserModel(
        id: 'mock-uuid-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
        avatarUrl: AppHelpers.getRandomAvatarUrl(fullName),
        contributionsCount: 0,
        badge: _calculateBadge(0),
        createdAt: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_session', true);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', fullName);
      await prefs.setInt('user_contributions', 0);

      NotificationService.instance.showSuccessSnackbar("Account created! Welcome to GB Safeway.");
      return true;
    } catch (e) {
      NotificationService.instance.showErrorSnackbar(e.toString().replaceAll("Exception: ", ""));
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
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
