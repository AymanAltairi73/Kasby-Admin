import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Service — singleton wrapper for the Supabase client.
/// Call [init] once in main() before runApp().
///
/// Credentials are injected via --dart-define at build time:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseService {
  SupabaseService._();

  /// Read from --dart-define or fallback to hardcoded (dev only)
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://majnuiypsgosbzsaeefc.supabase.co',
  );
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ham51aXlwc2dvc2J6c2FlZWZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwNzA5NzUsImV4cCI6MjA4NzY0Njk3NX0.M9OIGMQVdF4EACNae8G4pObbumB1fz_kR_xOz1G7chc',
  );

  /// Initialize Supabase — must be called before runApp().
  static Future<void> init() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  /// The Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut for auth.
  static GoTrueClient get auth => client.auth;
}
