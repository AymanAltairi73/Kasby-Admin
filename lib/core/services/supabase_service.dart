// import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_logger_service.dart';

/// Supabase Service — singleton wrapper for the Supabase client.
/// Call [init] once in main() before runApp().
///
/// Credentials are resolved in order:
/// 1. `--dart-define` (preferred for CI/production builds)
/// 2. `.env` file (local development)
///
/// NOTE: The service role key is NO LONGER embedded in the APK.
/// All admin-privileged operations are routed through the admin-proxy
/// Edge Function via [AdminProxyService].
class SupabaseService {
  SupabaseService._();

  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool _authListenerRegistered = false;

  static String _resolveUrl() =>
      _supabaseUrl.isNotEmpty ? _supabaseUrl : (dotenv.env['SUPABASE_URL'] ?? '');

  static String _resolveAnonKey() => _supabaseAnonKey.isNotEmpty
      ? _supabaseAnonKey
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

  static String _safeId(String? id) {
    if (id == null) return 'none';
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  /// Initialize Supabase — must be called before runApp().
  static Future<void> init() async {
    final stopwatch = Stopwatch()..start();
    AppLoggerService.debugTrace(
      className: 'SupabaseService',
      method: 'init',
      feature: 'Startup',
      status: 'INFO',
    );
    final url = _resolveUrl();
    final anonKey = _resolveAnonKey();

    if (url.isEmpty || anonKey.isEmpty) {
      AppLoggerService.debugTrace(
        className: 'SupabaseService',
        method: 'init',
        feature: 'Startup',
        status: 'FAILED',
        error: 'Missing SUPABASE_URL or SUPABASE_ANON_KEY',
      );
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be provided via .env or --dart-define.\n'
        'Local: copy .env.example to .env and fill in your values.\n'
        'CI/Release: flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key',
      );
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          timeout: Duration(seconds: 30),
        ),
      );
      registerAuthListener();
      stopwatch.stop();
      AppLoggerService.debugTrace(
        className: 'SupabaseService',
        method: 'init',
        feature: 'Startup',
        status: 'SUCCESS',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, st) {
      stopwatch.stop();
      AppLoggerService.debugTrace(
        className: 'SupabaseService',
        method: 'init',
        feature: 'Startup',
        status: 'FAILED',
        durationMs: stopwatch.elapsedMilliseconds,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static void registerAuthListener() {
    if (_authListenerRegistered) return;
    _authListenerRegistered = true;
    auth.onAuthStateChange.listen((state) {
      AppLoggerService.debugTrace(
        className: 'SupabaseService',
        method: 'onAuthStateChange',
        feature: 'Authentication',
        status: 'INFO',
        params: {
          'event': state.event.name,
          'userId': _safeId(state.session?.user.id),
        },
      );
    });
  }

  /// The Supabase client instance (uses anon key + current user session).
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut for auth.
  static GoTrueClient get auth => client.auth;

  /// Listen to auth state changes.
  static Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;

  /// Current authenticated user's ID, or null if not logged in.
  static String? get userId => auth.currentUser?.id;

  /// Whether a user is currently logged in.
  static bool get isLoggedIn => auth.currentUser != null;
}
