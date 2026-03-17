import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../core/services/base_repository.dart';

/// Activity Repository — handles technical and business activity logs.
class ActivityRepository extends BaseRepository {
  ActivityRepository(SupabaseClient client) : super('activity_logs', client);

  /// Fetch paginated activity logs.
  Future<List<Map<String, dynamic>>> getActivitiesPaginated({
    int from = 0,
    int to = 19,
    String? severity,
    String select = '*, profiles:actor_id(full_name)',
  }) async {
    return safeQuery(
      () async {
        var query = client.from(tableName).select(select);

        if (severity != null && severity != 'all') {
          query = query.eq('severity', severity);
        }

        final response = await query
            .range(from, to)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      },
      methodName: 'getActivitiesPaginated',
    );
  }
}
