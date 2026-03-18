import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../core/services/base_repository.dart';

/// Dashboard Repository — handles aggregated statistics and system-wide metrics.
class DashboardRepository extends BaseRepository {
  DashboardRepository(SupabaseClient client) : super('profiles', client); // Base table doesn't matter for RPCs

  /// Fetch aggregated dashboard statistics via RPC.
  Future<Map<String, dynamic>> getDashboardStats() async {
    return safeQuery(
      () async {
        final response = await client.rpc('fn_admin_dashboard');
        // fn_admin_dashboard returns TABLE(...) which Supabase sends as List<Map>
        if (response is List && response.isNotEmpty) {
          return Map<String, dynamic>.from(response[0] as Map);
        }
        return <String, dynamic>{};
      },
      methodName: 'getDashboardStats',
    );
  }

  /// Fetch charts data or other aggregated insights.
  Future<List<Map<String, dynamic>>> getMonthlyGrowth() async {
    // This could be another RPC or a complex query
    return safeQuery(
      () async {
        // Placeholder for future implementation
        return [];
      },
      methodName: 'getMonthlyGrowth',
    );
  }
}
