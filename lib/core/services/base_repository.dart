import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'app_logger_service.dart';

/// Base Repository — provides common Supabase query wrappers with robust error handling.
abstract class BaseRepository {
  final String tableName;
  final SupabaseClient client;

  BaseRepository(this.tableName, this.client);

  /// Wrap any Supabase call in common error handling and logging.
  Future<T> safeQuery<T>(
    Future<T> Function() query, {
    required String methodName,
    String? controllerName,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLoggerService.debugTrace(
      className: controllerName ?? tableName,
      method: methodName,
      feature: tableName,
      status: 'INFO',
      message: 'Supabase query started',
      params: {'table': tableName},
    );
    try {
      final result = await query();
      stopwatch.stop();
      final rowCount = _estimateRowCount(result);
      AppLoggerService.debugTrace(
        className: controllerName ?? tableName,
        method: methodName,
        feature: tableName,
        status: 'SUCCESS',
        durationMs: stopwatch.elapsedMilliseconds,
        params: {
          'table': tableName,
          if (rowCount != null) 'rows': rowCount,
        },
      );
      if (stopwatch.elapsedMilliseconds > 2000) {
        AppLoggerService.debugTrace(
          className: controllerName ?? tableName,
          method: methodName,
          feature: 'Performance',
          status: 'WARNING',
          message: 'Slow database query detected',
          durationMs: stopwatch.elapsedMilliseconds,
          params: {'table': tableName},
        );
      }
      return result;
    } on PostgrestException catch (e, stackTrace) {
      stopwatch.stop();
      _logException(e, stackTrace, methodName, controllerName);
      rethrow;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logGeneralError(e, stackTrace, methodName, controllerName);
      rethrow;
    }
  }

  static int? _estimateRowCount(dynamic result) {
    if (result is List) return result.length;
    return null;
  }

  /// Generic paginated fetcher.
  /// [from] and [to] are 0-indexed range indices.
  Future<List<T>> getPaginated<T>({
    required String methodName,
    required T Function(Map<String, dynamic>) fromJson,
    String select = '*',
    int from = 0,
    int to = 19,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    return safeQuery(
      () async {
        final response = await client
            .from(tableName)
            .select(select)
            .range(from, to)
            .order(orderBy, ascending: ascending);

        return (response as List).map((json) => fromJson(json)).toList();
      },
      methodName: methodName,
    );
  }

  /// Generic update method
  Future<void> update(String id, Map<String, dynamic> data) async {
    await safeQuery(
      () => client.from(tableName).update(data).eq('id', id),
      methodName: 'update',
    );
  }

  void _logException(
    PostgrestException e,
    StackTrace stackTrace,
    String method,
    String? controller,
  ) {
    AppLoggerService.logError(
      controller: controller ?? tableName,
      method: method,
      error: 'PostgrestException: ${e.message} (Code: ${e.code}, Hint: ${e.hint})',
      stackTrace: stackTrace,
    );
  }

  void _logGeneralError(
    dynamic e,
    StackTrace stackTrace,
    String method,
    String? controller,
  ) {
    AppLoggerService.logError(
      controller: controller ?? tableName,
      method: method,
      error: 'Unexpected Error: $e',
      stackTrace: stackTrace,
    );
  }
}
