import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/logger.dart';
import '../model/personal_contact_model.dart';

class SettingsController extends ChangeNotifier {
  // SOS Settings
  bool _autoCallSos = false;
  bool _autoSmsSos = false;
  bool _shareLiveLocation = true;
  int _sosCountdownTimer = 5;

  // Notifications Settings
  bool _pushNotifications = true;
  bool _roadClosureAlerts = true;
  bool _weatherAlerts = true;
  bool _emergencyAlerts = true;

  // Appearance
  bool _isDarkMode = false;

  // Language
  String _selectedLanguage = "English";

  // Emergency Contacts
  List<PersonalContact> _personalContacts = [];

  // Getters
  bool get autoCallSos => _autoCallSos;
  bool get autoSmsSos => _autoSmsSos;
  bool get shareLiveLocation => _shareLiveLocation;
  int get sosCountdownTimer => _sosCountdownTimer;

  bool get pushNotifications => _pushNotifications;
  bool get roadClosureAlerts => _roadClosureAlerts;
  bool get weatherAlerts => _weatherAlerts;
  bool get emergencyAlerts => _emergencyAlerts;

  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;
  List<PersonalContact> get personalContacts => _personalContacts;

  SettingsController() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _autoCallSos = prefs.getBool('settings_auto_call_sos') ?? false;
      _autoSmsSos = prefs.getBool('settings_auto_sms_sos') ?? false;
      _shareLiveLocation = prefs.getBool('settings_share_location') ?? true;
      _sosCountdownTimer = prefs.getInt('settings_countdown_timer') ?? 5;

      _pushNotifications = prefs.getBool('settings_push_notifications') ?? true;
      _roadClosureAlerts = prefs.getBool('settings_road_closure') ?? true;
      _weatherAlerts = prefs.getBool('settings_weather') ?? true;
      _emergencyAlerts = prefs.getBool('settings_emergency') ?? true;

      _isDarkMode = prefs.getBool('settings_dark_mode') ?? false;
      _selectedLanguage = prefs.getString('settings_language') ?? "English";

      // Load Contacts
      final contactsJson = prefs.getString('settings_personal_contacts');
      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        _personalContacts = decoded
            .map((item) => PersonalContact.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Preload default contacts if empty (so the user has non-empty initial data)
        _personalContacts = [
          PersonalContact(
            id: 'contact-default-1',
            name: 'Local Emergency Partner',
            phone: '+92 355 1234567',
            category: 'Local Rescue',
            location: 'Gilgit City',
          ),
          PersonalContact(
            id: 'contact-default-2',
            name: 'Family Coordinator',
            phone: '+92 300 9876543',
            category: 'Family',
            location: 'Hunza Valley',
          ),
        ];
        await _saveContactsToPrefs(prefs);
      }

      AppLogger.success("Settings loaded successfully.");
      notifyListeners();
    } catch (e) {
      AppLogger.error("Failed to load settings preferences", e);
    }
  }

  // Setters with persistence
  Future<void> toggleAutoCallSos(bool value) async {
    _autoCallSos = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_auto_call_sos', value);
  }

  Future<void> toggleAutoSmsSos(bool value) async {
    _autoSmsSos = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_auto_sms_sos', value);
  }

  Future<void> toggleShareLiveLocation(bool value) async {
    _shareLiveLocation = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_share_location', value);
  }

  Future<void> setSosCountdownTimer(int value) async {
    _sosCountdownTimer = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_countdown_timer', value);
  }

  Future<void> togglePushNotifications(bool value) async {
    _pushNotifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_push_notifications', value);
  }

  Future<void> toggleRoadClosureAlerts(bool value) async {
    _roadClosureAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_road_closure', value);
  }

  Future<void> toggleWeatherAlerts(bool value) async {
    _weatherAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_weather', value);
  }

  Future<void> toggleEmergencyAlerts(bool value) async {
    _emergencyAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_emergency', value);
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_dark_mode', value);
  }

  Future<void> setLanguage(String value) async {
    _selectedLanguage = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_language', value);
  }

  // Personal Contacts CRUD Operations
  Future<void> addContact(PersonalContact contact) async {
    _personalContacts.add(contact);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await _saveContactsToPrefs(prefs);
    NotificationService.instance.showSuccessSnackbar("Contact added: ${contact.name}");
  }

  Future<void> updateContact(PersonalContact updatedContact) async {
    final index = _personalContacts.indexWhere((c) => c.id == updatedContact.id);
    if (index != -1) {
      _personalContacts[index] = updatedContact;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await _saveContactsToPrefs(prefs);
      NotificationService.instance.showSuccessSnackbar("Contact updated: ${updatedContact.name}");
    }
  }

  Future<void> deleteContact(String id) async {
    final index = _personalContacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      final name = _personalContacts[index].name;
      _personalContacts.removeAt(index);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await _saveContactsToPrefs(prefs);
      NotificationService.instance.showSuccessSnackbar("Contact deleted: $name");
    }
  }

  Future<void> _saveContactsToPrefs(SharedPreferences prefs) async {
    final list = _personalContacts.map((c) => c.toJson()).toList();
    await prefs.setString('settings_personal_contacts', jsonEncode(list));
  }
}
