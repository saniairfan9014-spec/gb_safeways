import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/supabase_client.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (will gracefully fall back to local mock storage if keys are blank)
  await SupabaseService.instance.initialize(
    url: "https://rfymouuwlqbscpxihbzj.supabase.co",      // Optional: Add Supabase Project URL here
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmeW1vdXV3bHFic2NweGloYnpqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNzI4OTEsImV4cCI6MjA5NDc0ODg5MX0.29Xl1p8LgyBr70LFNJgw0O8OE4rQe9zJRRLnTus90wQ",  // Optional: Add Supabase Anon API Key here
  );

  AppLogger.success("GB Safeway Alert starting up...");
  runApp(const MyApp());
}
