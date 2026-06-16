import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'supabase_service.dart';

/// App Logger Service — writes admin actions to the system_logs table
/// for audit trail and production monitoring.
class AppLoggerService {
  AppLoggerService._();

  static String appVersion = '1.0.0';
  static Map<String, dynamic> deviceInfo = {};

  /// Structured debug trace for the Admin App (console only, no DB write).
  static void debugTrace({
    required String className,
    required String method,
    String status = 'INFO',
    String? feature,
    String? message,
    int? durationMs,
    Map<String, Object?>? params,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer(
      '[Kasby][AdminApp][${feature ?? className}][$className][$method]\n'
      'STATUS: $status',
    );
    if (durationMs != null) buffer.write('\nDuration: ${durationMs}ms');
    if (message != null) buffer.write('\n$message');
    if (params != null && params.isNotEmpty) {
      for (final entry in params.entries) {
        buffer.write('\n${entry.key}: ${entry.value}');
      }
    }
    if (error != null) buffer.write('\nError: $error');
    if (stackTrace != null) buffer.write('\nStackTrace: $stackTrace');
    debugPrint(buffer.toString());
  }

  /// Logs GetX route transitions.
  static void logRoute(Routing? routing) {
    if (!kDebugMode || routing == null) return;
    debugTrace(
      className: 'Navigation',
      method: 'routeChange',
      feature: 'Navigation',
      status: 'INFO',
      params: {
        'current': routing.current,
        'previous': routing.previous,
        'args': _safeArgs(routing.args),
      },
    );
  }

  static String _safeArgs(dynamic args) {
    if (args == null) return 'none';
    final text = args.toString();
    return text.length > 200 ? '${text.substring(0, 200)}...' : text;
  }

  /// Wraps async work with duration and success/failure tracing.
  static Future<T> traceAsync<T>({
    required String className,
    required String method,
    required Future<T> Function() operation,
    String? feature,
    Map<String, Object?>? params,
    Map<String, Object?>? Function(T result)? onSuccessParams,
  }) async {
    if (!kDebugMode) return operation();
    final stopwatch = Stopwatch()..start();
    debugTrace(
      className: className,
      method: method,
      feature: feature ?? className,
      status: 'INFO',
      message: 'Operation started',
      params: params,
    );
    try {
      final result = await operation();
      stopwatch.stop();
      final successParams = <String, Object?>{
        ...?params,
        ...?onSuccessParams?.call(result),
      };
      debugTrace(
        className: className,
        method: method,
        feature: feature ?? className,
        status: 'SUCCESS',
        durationMs: stopwatch.elapsedMilliseconds,
        params: successParams.isEmpty ? null : successParams,
      );
      if (stopwatch.elapsedMilliseconds > 2000) {
        debugTrace(
          className: className,
          method: method,
          feature: 'Performance',
          status: 'WARNING',
          message: 'Slow operation detected',
          durationMs: stopwatch.elapsedMilliseconds,
          params: params,
        );
      }
      return result;
    } catch (e, st) {
      stopwatch.stop();
      debugTrace(
        className: className,
        method: method,
        feature: feature ?? className,
        status: 'FAILED',
        durationMs: stopwatch.elapsedMilliseconds,
        params: params,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<void> init() async {
    // Version is set from pubspec during app startup
  }

  static Future<void> logError({
    required String controller,
    required String method,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    debugTrace(
      className: controller,
      method: method,
      status: 'FAILED',
      error: error,
      stackTrace: stackTrace,
    );
    await _writeLog(
      action: 'error',
      severity: 'error',
      details: {
        'controller': controller,
        'method': method,
        'error': error.toString(),
        if (stackTrace != null)
          'stack_trace': stackTrace.toString().split('\n').take(5).join('\n'),
      },
    );
  }

  static Future<void> logActivity({
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? details,
    String severity = 'info',
  }) async {
    await _writeLog(
      action: action,
      entityType: entityType,
      entityId: entityId,
      severity: severity,
      details: details,
    );
  }

  static Future<void> logChatPerformance({
    required String conversationId,
    required String action,
    required int latencyMs,
    String severity = 'info',
    Map<String, dynamic>? details,
  }) async {
    await _writeLog(
      action: 'chat:$action',
      entityType: 'chat_conversation',
      entityId: conversationId,
      severity: severity,
      details: {
        'latency_ms': latencyMs,
        ...?details,
      },
    );
  }

  static Future<void> logInfo({
    required String controller,
    required String method,
    required String message,
  }) async {
    debugTrace(
      className: controller,
      method: method,
      status: 'SUCCESS',
      message: message,
    );
    await _writeLog(
      action: '$controller.$method',
      severity: 'info',
      details: {'message': message},
    );
  }

  static Future<void> _writeLog({
    required String action,
    String? entityType,
    String? entityId,
    String severity = 'info',
    Map<String, dynamic>? details,
  }) async {
    try {
      final userId = SupabaseService.userId;
      if (userId == null) return;

      await SupabaseService.client.from('system_logs').insert({
        'actor_id': userId,
        'actor_role': 'admin',
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'severity': severity,
        'details': {
          ...?details,
          'app_version': appVersion,
          'source': 'admin_app',
        },
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppLogger] Failed to write log: $e');
      }
    }
  }
}

/// Tracks screen open/close lifecycle for route-level observability.
class AdminTrackedScreen extends StatefulWidget {
  final String screenName;
  final Widget child;

  const AdminTrackedScreen({
    super.key,
    required this.screenName,
    required this.child,
  });

  @override
  State<AdminTrackedScreen> createState() => _AdminTrackedScreenState();
}

class _AdminTrackedScreenState extends State<AdminTrackedScreen> {
  @override
  void initState() {
    super.initState();
    AppLoggerService.debugTrace(
      className: widget.screenName,
      method: 'initState',
      feature: widget.screenName,
      status: 'INFO',
      message: 'Screen opened',
      params: {
        'route': Get.currentRoute,
        'hasArgs': Get.arguments != null,
      },
    );
  }

  @override
  void dispose() {
    AppLoggerService.debugTrace(
      className: widget.screenName,
      method: 'dispose',
      feature: widget.screenName,
      status: 'INFO',
      message: 'Screen closed',
      params: {'route': Get.currentRoute},
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
