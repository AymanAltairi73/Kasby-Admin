import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'base_repository.dart';

/// System Repository — handles system settings and global configurations.
class SystemRepository extends BaseRepository {
  SystemRepository(SupabaseClient client) : super('system_settings', client);

  /// Fetch the first row of system settings.
  Future<Map<String, dynamic>?> getSettings() async {
    return safeQuery(
      () => client.from(tableName).select().limit(1).maybeSingle(),
      methodName: 'getSettings',
    );
  }

  /// Create initial settings row.
  Future<void> createSettings(Map<String, dynamic> data) async {
    await safeQuery(
      () => client.from(tableName).insert(data),
      methodName: 'createSettings',
    );
  }

  /// Update settings row by ID.
  Future<void> updateSettings(dynamic id, Map<String, dynamic> data) async {
    await safeQuery(
      () => client.from(tableName).update(data).eq('id', id),
      methodName: 'updateSettings',
    );
  }
}
