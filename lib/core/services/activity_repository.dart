import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../core/services/base_repository.dart';

/// Activity Repository — handles technical and business activity logs.
class ActivityRepository extends BaseRepository {
  ActivityRepository(SupabaseClient client) : super('activity_logs', client);

  /// Fetch paginated activity logs.
  /// Note: activity_logs.actor_id references auth.users (not profiles),
  /// so we cannot use FK-based JOINs. We fetch logs first, then
  /// resolve actor names separately.
  Future<List<Map<String, dynamic>>> getActivitiesPaginated({
    int from = 0,
    int to = 19,
    String? severity,
    String select = '*',
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

        final logs = List<Map<String, dynamic>>.from(response);

        // Resolve actor names from profiles table
        final actorIds = logs
            .map((l) => l['actor_id'] as String?)
            .where((id) => id != null)
            .toSet()
            .toList();

        if (actorIds.isNotEmpty) {
          try {
            final profiles = await client
                .from('profiles')
                .select('id, full_name')
                .inFilter('id', actorIds);

            final nameMap = <String, String>{};
            for (final p in profiles) {
              nameMap[p['id'] as String] = p['full_name'] ?? '';
            }

            for (var i = 0; i < logs.length; i++) {
              final actorId = logs[i]['actor_id'] as String?;
              logs[i] = Map<String, dynamic>.from(logs[i]);
              logs[i]['profiles'] = actorId != null
                  ? {'full_name': nameMap[actorId] ?? ''}
                  : null;
            }
          } catch (_) {
            // If profile lookup fails, just return logs without names
          }
        }

        return logs;
      },
      methodName: 'getActivitiesPaginated',
    );
  }
}
