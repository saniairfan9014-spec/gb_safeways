import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/supabase_client.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (will gracefully fall back to local mock storage if keys are blank)
  await SupabaseService.instance.initialize(
    url: "",      // Optional: Add Supabase Project URL here
    anonKey: "",  // Optional: Add Supabase Anon API Key here
  );

  AppLogger.success("GB Safeway Alert starting up...");
  runApp(const MyApp());
}
