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
