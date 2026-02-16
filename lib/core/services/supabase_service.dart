import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Service — singleton wrapper for the Supabase client.
/// Call [init] once in main() before runApp().
class SupabaseService {
  SupabaseService._();

  static const String _supabaseUrl = 'https://rsegwzpnloixfpxwxywe.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzZWd3enBubG9peGZweHd4eXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4NDYwNTcsImV4cCI6MjA4NjQyMjA1N30.zVjjiB0YjUpaoztzpY7_HB3Xp0KNKbKzA4GwELDMnjE';

  /// Initialize Supabase — must be called before runApp().
  static Future<void> init() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  /// The Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut for auth.
  static GoTrueClient get auth => client.auth;
}
