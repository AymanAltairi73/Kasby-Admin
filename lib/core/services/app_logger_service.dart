import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'supabase_service.dart';

/// AppLoggerService — Centralized error logging for production Fintech apps.
///
/// Features:
///  • Logs errors to Supabase `error_logs` table
///  • Rate-limited: max 1 log per controller+method per 10 seconds
///  • Sanitizes sensitive data (passwords, tokens, OTP)
///  • Debug-mode console output with full stack traces
///  • Never crashes the app — all logging is fire-and-forget
class AppLoggerService {
  AppLoggerService._();

  // ─────────── Rate Limiting ───────────
  static final _recentLogs = HashMap<String, DateTime>();
  static const _cooldown = Duration(seconds: 10);

  /// The app version — set once at startup
  static String appVersion = '1.0.0';

  /// Device metadata (OS version, model, etc.)
  static Map<String, dynamic> deviceInfo = {};

  /// Initialize metadata (Version, Device Info)
  /// Call this in main() after WidgetsFlutterBinding.ensureInitialized();
  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';

      final devicePlugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final webInfo = await devicePlugin.webBrowserInfo;
        deviceInfo = {
          'platform': 'Web',
          'browser': webInfo.browserName.name,
          'platform_name': webInfo.platform,
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await devicePlugin.androidInfo;
        deviceInfo = {
          'platform': 'Android',
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await devicePlugin.iosInfo;
        deviceInfo = {
          'platform': 'iOS',
          'model': iosInfo.utsname.machine,
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      } else {
        deviceInfo = {'platform': Platform.operatingSystem};
      }
    } catch (_) {
      // Initialization should not block app startup
    }
  }

  /// Log an error from a controller method.
  ///
  /// [controller] — class name (e.g. 'UserController')
  /// [method]     — method name (e.g. 'loadUsers')
  /// [error]      — the caught exception/error
  /// [stackTrace] — optional stack trace for debugging
  static Future<void> logError({
    required String controller,
    required String method,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    try {
      // ── Debug console output ──
      if (kDebugMode) {
        debugPrint('═══ ERROR LOG ═══');
        debugPrint('Controller: $controller');
        debugPrint('Method: $method');
        debugPrint('Error: $error');
        if (stackTrace != null) {
          debugPrint('StackTrace: $stackTrace');
        }
        debugPrint('═════════════════');
      }

      // ── Rate limit check ──
      final key = '$controller.$method';
      final now = DateTime.now();
      final lastLog = _recentLogs[key];
      if (lastLog != null && now.difference(lastLog) < _cooldown) {
        // Skip — duplicate within cooldown window
        return;
      }
      _recentLogs[key] = now;

      // ── Clean up old entries (keep map small) ──
      if (_recentLogs.length > 100) {
        _recentLogs.removeWhere(
          (_, time) => now.difference(time) > const Duration(minutes: 5),
        );
      }

      // ── Sanitize error message ──
      final sanitizedError = _sanitize(error.toString());
      final sanitizedStack = stackTrace != null
          ? _sanitize(stackTrace.toString())
          : null;

      // ── Persist to Supabase ──
      final userId = SupabaseService.auth.currentUser?.id;
      await SupabaseService.client.from('error_logs').insert({
        'user_id': userId,
        'controller_name': controller,
        'method_name': method,
        'error_message': sanitizedError,
        'stack_trace': sanitizedStack,
        'app_version': appVersion,
        'device_info': deviceInfo, // Store complete metadata map
        'created_at': now.toIso8601String(),
      });
    } catch (_) {
      // Logging must NEVER crash the app
    }
  }

  /// Sanitize sensitive data from error messages
  static String _sanitize(String input) {
    String result = input;

    // Remove access/refresh tokens (JWT pattern)
    result = result.replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
      '[REDACTED_TOKEN]',
    );

    // Remove password values
    result = result.replaceAll(
      RegExp(r'(?i)(password|passwd|pwd)\s*[:=]\s*\S+'),
      r'$1=[REDACTED]',
    );

    // Remove OTP codes (4-6 digit patterns near "otp" keyword)
    result = result.replaceAll(
      RegExp(r'(?i)(otp|code|pin)\s*[:=]\s*\d{4,6}'),
      r'$1=[REDACTED]',
    );

    return result;
  }
}
