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
    try {
      return await query();
    } on PostgrestException catch (e, stackTrace) {
      _logException(e, stackTrace, methodName, controllerName);
      rethrow;
    } catch (e, stackTrace) {
      _logGeneralError(e, stackTrace, methodName, controllerName);
      rethrow;
    }
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
