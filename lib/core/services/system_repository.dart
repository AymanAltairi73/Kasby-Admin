import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'app_logger_service.dart';
import 'base_repository.dart';

/// System Repository — handles system settings and global configurations.
class SystemRepository extends BaseRepository {
  SystemRepository(SupabaseClient client) : super('system_settings', client);

  /// Fetch the first row of system settings.
  Future<Map<String, dynamic>?> getSettings() async {
    AppLoggerService.debugTrace(
      className: 'SystemRepository',
      method: 'getSettings',
      feature: 'Settings',
      status: 'INFO',
    );
    return safeQuery(
      () => client.from(tableName).select().limit(1).maybeSingle(),
      methodName: 'getSettings',
      controllerName: 'SystemRepository',
    );
  }

  /// Create initial settings row.
  Future<void> createSettings(Map<String, dynamic> data) async {
    AppLoggerService.debugTrace(
      className: 'SystemRepository',
      method: 'createSettings',
      feature: 'Settings',
      status: 'INFO',
    );
    await safeQuery(
      () => client.from(tableName).insert(data),
      methodName: 'createSettings',
      controllerName: 'SystemRepository',
    );
  }

  /// Update settings row by ID.
  Future<void> updateSettings(dynamic id, Map<String, dynamic> data) async {
    AppLoggerService.debugTrace(
      className: 'SystemRepository',
      method: 'updateSettings',
      feature: 'Settings',
      status: 'INFO',
      params: {'id': id.toString()},
    );
    await safeQuery(
      () => client.from(tableName).update(data).eq('id', id),
      methodName: 'updateSettings',
      controllerName: 'SystemRepository',
    );
  }

  /// Update the first row of settings (singleton pattern).
  Future<void> updateFirstSettings(Map<String, dynamic> data) async {
    AppLoggerService.debugTrace(
      className: 'SystemRepository',
      method: 'updateFirstSettings',
      feature: 'Settings',
      status: 'INFO',
    );
    final settings = await getSettings();
    if (settings != null && settings['id'] != null) {
      await updateSettings(settings['id'], data);
    }
  }
}
