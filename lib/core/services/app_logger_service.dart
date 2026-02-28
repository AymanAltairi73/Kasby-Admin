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
  /// Redirected to unified `activity_logs` table.
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
        return;
      }
      _recentLogs[key] = now;

      final sanitizedError = _sanitize(error.toString());
      final sanitizedStack = stackTrace != null
          ? _sanitize(stackTrace.toString())
          : null;

      // ── Persist to Unified Activity Logs ──
      final userId = SupabaseService.auth.currentUser?.id;
      await SupabaseService.client.from('activity_logs').insert({
        'actor_id': userId,
        'action': 'ERROR: $controller.$method',
        'entity_type': 'technical_error',
        'details': {
          'error': sanitizedError,
          'stack_trace': sanitizedStack,
          'app_version': appVersion,
          'device_info': deviceInfo,
        },
        'severity': 'critical',
      });
    } catch (_) {
      // Logging must NEVER crash the app
    }
  }

  /// Log a general activity or business action to the unified system.
  static Future<void> logActivity({
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? details,
    String severity = 'info',
  }) async {
    try {
      final userId = SupabaseService.auth.currentUser?.id;
      await SupabaseService.client.from('activity_logs').insert({
        'actor_id': userId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': {
          if (details != null) ...details,
          'app_version': appVersion,
          'device_info': deviceInfo,
        },
        'severity': severity,
      });
    } catch (_) {
      // Silently fail logging
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
      RegExp(r'(password|passwd|pwd)\s*[:=]\s*\S+', caseSensitive: false),
      r'$1=[REDACTED]',
    );

    // Remove OTP codes (4-6 digit patterns near "otp" keyword)
    result = result.replaceAll(
      RegExp(r'(otp|code|pin)\s*[:=]\s*\d{4,6}', caseSensitive: false),
      r'$1=[REDACTED]',
    );

    return result;
  }
}
