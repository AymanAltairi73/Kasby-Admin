import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/base_repository.dart';

class DashboardRepository extends BaseRepository {
  DashboardRepository(SupabaseClient client) : super('profiles', client);

  Future<Map<String, dynamic>> getDashboardStats() async {
    AppLoggerService.debugTrace(
      className: 'DashboardRepository',
      method: 'getDashboardStats',
      feature: 'Dashboard',
      status: 'INFO',
    );
    return safeQuery(
      () async {
        final response = await client.rpc('fn_admin_dashboard');
        if (response is List && response.isNotEmpty) {
          return Map<String, dynamic>.from(response[0] as Map);
        }
        return <String, dynamic>{};
      },
      methodName: 'getDashboardStats',
      controllerName: 'DashboardRepository',
    );
  }

  Future<List<Map<String, dynamic>>> getWeeklylyVolume() async {
    AppLoggerService.debugTrace(
      className: 'DashboardRepository',
      method: 'getWeeklylyVolume',
      feature: 'Dashboard',
      status: 'INFO',
    );
    return safeQuery(
      () async {
        final response = await client.rpc('fn_admin_weekly_volume');
        if (response is List) {
          return response
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        return [];
      },
      methodName: 'getWeeklylyVolume',
      controllerName: 'DashboardRepository',
    );
  }
}
