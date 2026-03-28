import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Service — singleton wrapper for the Supabase client.
/// Call [init] once in main() before runApp().
///
/// Credentials are injected via --dart-define at build time:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=SUPABASE_SERVICE_ROLE_KEY=...
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

  /// Service role key — needed for admin operations (create/delete users)
  /// IMPORTANT: This key has FULL access, never expose in client apps.
  /// Only safe because this is an admin-only app.
  static const String _serviceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: '', // Must be set via --dart-define in production
  );

  /// Admin client (uses service role key for elevated privileges)
  static SupabaseClient? _adminClient;

  /// Initialize Supabase — must be called before runApp().
  static Future<void> init() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

    // Create admin client if service role key is available
    if (_serviceRoleKey.isNotEmpty) {
      _adminClient = SupabaseClient(_supabaseUrl, _serviceRoleKey);
    }
  }

  /// The Supabase client instance (uses anon key + current user session).
  static SupabaseClient get client => Supabase.instance.client;

  /// Admin client with service role key (bypasses RLS, full access).
  /// Falls back to regular client if service role key is not configured.
  static SupabaseClient get adminClient => _adminClient ?? client;

  /// Whether the admin client has elevated privileges.
  static bool get hasAdminClient => _adminClient != null;

  /// Shortcut for auth.
  static GoTrueClient get auth => client.auth;

  /// Listen to auth state changes.
  static Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;

  /// Current authenticated user's ID, or null if not logged in.
  static String? get userId => auth.currentUser?.id;

  /// Whether a user is currently logged in.
  static bool get isLoggedIn => auth.currentUser != null;
}
