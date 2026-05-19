import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

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

  /// Initialize Supabase with local fallback capability
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
      AppLogger.error("Failed to initialize Supabase, falling back to LOCAL MOCK MODE", e);
      _isInitialized = false;
    }
  }
}
