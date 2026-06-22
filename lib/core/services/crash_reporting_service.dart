import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'crash_reporting/crash_breadcrumb.dart';
import 'crash_reporting/crash_error_category.dart';
import 'app_logger_service.dart';
import 'supabase_service.dart';
import 'permission_service.dart';

/// Production crash monitoring via Firebase Crashlytics for the Admin App.
///
/// Disabled in debug builds. All reporting flows through this service.
class CrashReportingService {
  CrashReportingService._();

  static bool _initialized = false;
  static bool _handlersInstalled = false;

  static String? _lastFingerprint;
  static DateTime? _lastFingerprintAt;

  static String _currentModule = 'unknown';
  static String _currentOperation = 'unknown';

  static bool get isInitialized => _initialized;

  static bool get isCollectionEnabled => !kDebugMode;

  static Future<void> initialize({required bool firebaseReady}) async {
    if (!firebaseReady || _initialized) return;
    _initialized = true;

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(isCollectionEnabled);

    if (isCollectionEnabled) {
      await setCustomKey(CrashCustomKey.appVersion, AppLoggerService.appVersion);
      await setCustomKey(CrashCustomKey.buildNumber, AppLoggerService.appVersion);
      _installGlobalHandlers();
    }
  }

  static Future<void> init({required bool firebaseReady}) =>
      initialize(firebaseReady: firebaseReady);

  static void runAppWithCrashGuards(Future<void> Function() appRunner) {
    runZonedGuarded(
      () {
        unawaited(appRunner());
      },
      (error, stack) {
        unawaited(recordFatal(
          error,
          stack,
          reason: 'Zone.runGuarded',
          category: CrashErrorCategory.admin,
        ));
      },
    );
  }

  static void _installGlobalHandlers() {
    if (_handlersInstalled) return;
    _handlersInstalled = true;

    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterHandler?.call(details);
      FlutterError.presentError(details);
      if (kDebugMode) {
        AppLoggerService.debugTrace(
          className: 'FlutterError',
          method: 'onError',
          feature: 'ErrorHandling',
          status: 'FAILED',
          error: details.exceptionAsString(),
          stackTrace: details.stack,
        );
      }
      if (isCollectionEnabled &&
          _shouldReport(details.exception, details.stack, source: 'flutter')) {
        unawaited(FirebaseCrashlytics.instance
            .recordFlutterFatalError(details));
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        AppLoggerService.debugTrace(
          className: 'PlatformDispatcher',
          method: 'onError',
          feature: 'ErrorHandling',
          status: 'FAILED',
          error: error,
          stackTrace: stack,
        );
      }
      if (isCollectionEnabled && _shouldReport(error, stack, source: 'platform')) {
        unawaited(FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
          reason: 'PlatformDispatcher.onError',
        ));
      }
      return true;
    };
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    CrashErrorCategory category = CrashErrorCategory.admin,
    Map<String, Object?>? context,
  }) async {
    await _applyCategory(category);
    await _applyAdminContext();
    if (context != null) {
      await _applyContextKeys(context);
    }

    if (!isCollectionEnabled || !_initialized) {
      if (kDebugMode) {
        AppLoggerService.debugTrace(
          className: 'CrashReportingService',
          method: 'recordError',
          feature: 'ErrorHandling',
          status: 'FAILED',
          message: reason,
          error: error,
          stackTrace: stack,
          params: {'fatal': fatal, 'category': category.key},
        );
      }
      return;
    }

    if (!_shouldReport(error, stack, source: reason ?? 'recordError')) {
      return;
    }

    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: _buildReason(reason, category),
      fatal: fatal,
    );
  }

  static Future<void> recordFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
    CrashErrorCategory category = CrashErrorCategory.admin,
    Map<String, Object?>? context,
  }) =>
      recordError(
        error,
        stack,
        reason: reason,
        fatal: true,
        category: category,
        context: context,
      );

  static Future<void> recordException(
    Object exception,
    StackTrace? stack, {
    String? reason,
    CrashErrorCategory category = CrashErrorCategory.admin,
    Map<String, Object?>? context,
  }) =>
      recordError(
        exception,
        stack,
        reason: reason,
        fatal: false,
        category: category,
        context: context,
      );

  static Future<void> recordNetworkError(
    Object error,
    StackTrace? stack, {
    String? operation,
    bool isTimeout = false,
  }) =>
      recordError(
        error,
        stack,
        reason: operation ?? 'Network failure',
        category: CrashErrorCategory.network,
        context: {
          if (operation != null) 'operation': operation,
          'is_timeout': isTimeout,
        },
      );

  static Future<void> recordSupabaseError(
    Object error, {
    StackTrace? stack,
    String? rpcName,
    String? tableName,
    String? operation,
    CrashErrorCategory category = CrashErrorCategory.supabase,
  }) async {
    final context = <String, Object?>{
      CrashCustomKey.supabaseErrorType: error.runtimeType.toString(),
      if (rpcName != null) CrashCustomKey.rpcName: rpcName,
      if (tableName != null) CrashCustomKey.tableName: tableName,
      if (operation != null) 'operation': operation,
    };

    if (error is PostgrestException) {
      context[CrashCustomKey.postgrestCode] = error.code ?? 'unknown';
      context[CrashCustomKey.httpStatus] = error.code ?? 'unknown';
    } else if (error is AuthException) {
      context[CrashCustomKey.httpStatus] =
          error.statusCode?.toString() ?? 'unknown';
    } else if (error is FunctionException) {
      context[CrashCustomKey.httpStatus] = error.status.toString();
    }

    await recordError(
      error,
      stack ?? StackTrace.current,
      reason: _sanitizeMessage(error.toString()),
      category: category,
      context: context,
    );
  }

  static Future<void> recordAuthError(
    Object error, {
    StackTrace? stack,
    String? authMethod,
    bool expectedFailure = false,
  }) async {
    if (expectedFailure && error is AuthException) return;

    await recordError(
      error,
      stack ?? StackTrace.current,
      reason: 'Admin authentication failure',
      category: CrashErrorCategory.authentication,
      context: {
        if (authMethod != null) 'auth_method': authMethod,
      },
    );
  }

  static Future<void> recordBusinessError(
    Object error, {
    StackTrace? stack,
    required CrashErrorCategory category,
    String? operation,
    Map<String, Object?>? context,
  }) =>
      recordError(
        error,
        stack ?? StackTrace.current,
        reason: operation ?? 'Admin business logic failure',
        category: category,
        context: context,
      );

  static Future<void> log(String message) async {
    final sanitized = _sanitizeMessage(message);
    if (!isCollectionEnabled || !_initialized) {
      if (kDebugMode) {
        AppLoggerService.debugTrace(
          className: 'CrashReportingService',
          method: 'log',
          feature: 'ErrorHandling',
          status: 'INFO',
          message: sanitized,
        );
      }
      return;
    }
    await FirebaseCrashlytics.instance.log(sanitized);
  }

  static Future<void> setUser({
    String? adminId,
    String? adminRole,
    String? adminPrivilege,
  }) async {
    if (!isCollectionEnabled || !_initialized) return;

    if (adminId != null && adminId.isNotEmpty) {
      await FirebaseCrashlytics.instance.setUserIdentifier(adminId);
      await setCustomKey(CrashCustomKey.adminId, adminId);
    }
    if (adminRole != null) {
      await setCustomKey(CrashCustomKey.adminRole, adminRole);
    }
    if (adminPrivilege != null) {
      await setCustomKey(CrashCustomKey.adminPrivilege, adminPrivilege);
    }
  }

  static Future<void> clearUser() async {
    if (!isCollectionEnabled || !_initialized) return;
    await FirebaseCrashlytics.instance.setUserIdentifier('');
    await setCustomKey(CrashCustomKey.adminRole, 'anonymous');
    await setCustomKey(CrashCustomKey.adminPrivilege, 'none');
    await setCustomKey(CrashCustomKey.adminId, 'none');
  }

  static Future<void> setCustomKey(String key, Object value) async {
    if (!isCollectionEnabled || !_initialized) return;
    await FirebaseCrashlytics.instance.setCustomKey(
      key,
      _sanitizeCustomValue(value),
    );
  }

  static Future<void> setCustomKeys(Map<String, Object?> keys) async {
    for (final entry in keys.entries) {
      final value = entry.value;
      if (value != null) {
        await setCustomKey(entry.key, value);
      }
    }
  }

  static Future<void> setAdminContext({
    String? module,
    String? operation,
  }) async {
    if (module != null && module.isNotEmpty) {
      _currentModule = module;
      await setCustomKey(CrashCustomKey.currentModule, module);
    }
    if (operation != null && operation.isNotEmpty) {
      _currentOperation = operation;
      await setCustomKey(CrashCustomKey.currentOperation, operation);
    }
  }

  static Future<void> syncAdminContextFromSession() async {
    final userId = SupabaseService.userId;
    if (userId == null) {
      await clearUser();
      return;
    }

    String privilege = 'admin';
    if (Get.isRegistered<PermissionService>()) {
      privilege = PermissionService.to.adminPrivilege.value;
    }

    await setUser(
      adminId: userId,
      adminRole: 'admin',
      adminPrivilege: privilege,
    );
  }

  static Future<void> updateRouteContext(String? route, {String? screenName}) async {
    if (route != null && route.isNotEmpty) {
      await setCustomKey(CrashCustomKey.currentRoute, route);
    }
    if (screenName != null && screenName.isNotEmpty) {
      await setCustomKey(CrashCustomKey.screenName, screenName);
      await setAdminContext(module: _moduleFromScreen(screenName));
    }
  }

  static String _moduleFromScreen(String screenName) {
    final name = screenName.toLowerCase();
    if (name.contains('user')) return AdminModule.userManagement;
    if (name.contains('wallet') || name.contains('transaction')) {
      return AdminModule.walletManagement;
    }
    if (name.contains('invest')) return AdminModule.investments;
    if (name.contains('kyc')) return AdminModule.kyc;
    if (name.contains('report') || name.contains('revenue')) {
      return AdminModule.reports;
    }
    if (name.contains('notif')) return AdminModule.notifications;
    if (name.contains('loan')) return AdminModule.loans;
    if (name.contains('chat')) return AdminModule.chat;
    if (name.contains('setting')) return AdminModule.settings;
    if (name.contains('approval')) return AdminModule.approvals;
    if (name.contains('health')) return AdminModule.systemHealth;
    return _currentModule;
  }

  static CrashErrorCategory categoryFromFeature(String? feature) {
    if (feature == null) return CrashErrorCategory.admin;
    final normalized = feature.toLowerCase();
    if (normalized.contains('auth')) return CrashErrorCategory.authentication;
    if (normalized.contains('wallet') || normalized.contains('transaction')) {
      return CrashErrorCategory.wallet;
    }
    if (normalized.contains('invest')) return CrashErrorCategory.investments;
    if (normalized.contains('kyc')) return CrashErrorCategory.profile;
    if (normalized.contains('notif')) return CrashErrorCategory.notifications;
    if (normalized.contains('network')) return CrashErrorCategory.network;
    return CrashErrorCategory.admin;
  }

  static Future<void> _applyCategory(CrashErrorCategory category) async {
    await setCustomKey(CrashCustomKey.errorCategory, category.key);
  }

  static Future<void> _applyAdminContext() async {
    await setCustomKey(CrashCustomKey.currentModule, _currentModule);
    await setCustomKey(CrashCustomKey.currentOperation, _currentOperation);
  }

  static Future<void> _applyContextKeys(Map<String, Object?> context) async {
    for (final entry in context.entries) {
      final value = entry.value;
      if (value != null) {
        await setCustomKey(entry.key, _sanitizeCustomValue(value));
      }
    }
  }

  static String _buildReason(String? reason, CrashErrorCategory category) {
    final base = reason ?? category.key;
    return '${category.key}: $base';
  }

  static bool _shouldReport(Object error, StackTrace? stack, {String? source}) {
    final fingerprint =
        '${error.runtimeType}|${error.hashCode}|${stack?.hashCode ?? 0}|$source';
    final now = DateTime.now();
    if (_lastFingerprint == fingerprint &&
        _lastFingerprintAt != null &&
        now.difference(_lastFingerprintAt!) < const Duration(seconds: 3)) {
      return false;
    }
    _lastFingerprint = fingerprint;
    _lastFingerprintAt = now;
    return true;
  }

  static Object _sanitizeCustomValue(Object value) {
    if (value is num || value is bool) return value;
    return _sanitizeMessage(value.toString());
  }

  static String _sanitizeMessage(String message) {
    var sanitized = message;
    final sensitivePatterns = [
      RegExp(r'password\s*[:=]\s*\S+', caseSensitive: false),
      RegExp(r'token\s*[:=]\s*\S+', caseSensitive: false),
      RegExp(r'otp\s*[:=]\s*\S+', caseSensitive: false),
      RegExp(r'bearer\s+\S+', caseSensitive: false),
      RegExp(r'api[_-]?key\s*[:=]\s*\S+', caseSensitive: false),
    ];
    for (final pattern in sensitivePatterns) {
      sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
    }
    if (sanitized.length > 500) {
      sanitized = '${sanitized.substring(0, 500)}...';
    }
    return sanitized;
  }
}
