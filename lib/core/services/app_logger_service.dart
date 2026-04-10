import 'package:flutter/foundation.dart';

/// No-op App Logger Service — system removed
class AppLoggerService {
  AppLoggerService._();

  static String appVersion = '1.0.0';
  static Map<String, dynamic> deviceInfo = {};

  static Future<void> init() async {
    // No-op
  }

  static Future<void> logError({
    required String controller,
    required String method,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    if (kDebugMode) {
      debugPrint('═══ [REMOVED] ERROR LOG (NO-OP) ═══');
      debugPrint('Controller: $controller');
      debugPrint('Method: $method');
      debugPrint('Error: $error');
      debugPrint('═════════════════════════════════');
    }
  }

  static Future<void> logActivity({
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? details,
    String severity = 'info',
  }) async {
    // No-op
  }

  static Future<void> logChatPerformance({
    required String conversationId,
    required String action,
    required int latencyMs,
    String severity = 'info',
    Map<String, dynamic>? details,
  }) async {
    // No-op
  }

  static Future<void> logInfo({
    required String controller,
    required String method,
    required String message,
  }) async {
    // No-op
  }
}
