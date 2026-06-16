import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/base_repository.dart';

class KspAnalyticsRepository extends BaseRepository {
  KspAnalyticsRepository(SupabaseClient client) : super('user_points', client);

  Future<Map<String, dynamic>> getKspOverviewMetrics() async {
    AppLoggerService.debugTrace(
      className: 'KspAnalyticsRepository',
      method: 'getKspOverviewMetrics',
      feature: 'KspAnalytics',
      status: 'INFO',
    );
    return safeQuery(() async {
      // 1. Fetch user points for total supply, total distributed (sum of total_earned), and top earner
      final pointsRes = await client.from('user_points').select('current_balance, total_earned, total_spent, user_id, profiles(full_name)');
      
      int totalSupply = 0;
      int totalDistributed = 0;
      int totalSpent = 0; // reserved for future metrics
      
      int maxEarned = -1;
      String topEarnerName = 'N/A';
      
      for (var row in pointsRes) {
        final balance = row['current_balance'] as int? ?? 0;
        final earned = row['total_earned'] as int? ?? 0;
        final spent = row['total_spent'] as int? ?? 0;
        
        totalSupply += balance;
        totalDistributed += earned;
        totalSpent += spent;
        
        if (earned > maxEarned) {
          maxEarned = earned;
          final profile = row['profiles'];
          if (profile is Map) {
            topEarnerName = profile['full_name'] as String? ?? 'N/A';
          }
        }
      }

      // 2. Fetch daily history for daily generated and daily rewards
      final now = DateTime.now().toUtc();
      final todayStart = DateTime(now.year, now.month, now.day).toUtc();
      
      final historyRes = await client
          .from('point_history')
          .select()
          .gte('created_at', todayStart.toIso8601String());

      int dailyKspGenerated = 0;
      int dailyKspRewards = 0;

      for (var row in historyRes) {
        final pts = row['points'] as int? ?? 0;
        final type = row['type'] as String? ?? '';
        final desc = (row['description'] as String? ?? '').toLowerCase();

        if (type == 'earn' || type == 'transfer_in') {
          dailyKspGenerated += pts;
          // check if description indicates a reward (spin wheel, daily check-in, referral)
          if (desc.contains('spin') || desc.contains('check') || desc.contains('referral') || desc.contains('reward') || desc.contains('bonus')) {
            dailyKspRewards += pts;
          }
        }
      }

      return {
        'totalSupply': totalSupply,
        'totalDistributed': totalDistributed,
        'dailyKspGenerated': dailyKspGenerated,
        'dailyKspRewards': dailyKspRewards,
        'topEarnerName': topEarnerName,
        'topEarnerAmount': maxEarned > 0 ? maxEarned : 0,
      };
    }, methodName: 'getKspOverviewMetrics', controllerName: 'KspAnalyticsRepository');
  }

  Future<List<Map<String, dynamic>>> getTopHolders() async {
    AppLoggerService.debugTrace(
      className: 'KspAnalyticsRepository',
      method: 'getTopHolders',
      feature: 'KspAnalytics',
      status: 'INFO',
    );
    return safeQuery(() async {
      final res = await client
          .from('user_points')
          .select('current_balance, total_earned, profiles(full_name, email)')
          .order('current_balance', ascending: false)
          .limit(10);
      
      return (res as List).map((row) {
        final profile = row['profiles'] as Map? ?? {};
        return {
          'name': profile['full_name'] ?? 'N/A',
          'email': profile['email'] ?? 'N/A',
          'balance': row['current_balance'] ?? 0,
          'totalEarned': row['total_earned'] ?? 0,
        };
      }).toList();
    }, methodName: 'getTopHolders', controllerName: 'KspAnalyticsRepository');
  }

  Future<List<Map<String, dynamic>>> getTopEarners() async {
    AppLoggerService.debugTrace(
      className: 'KspAnalyticsRepository',
      method: 'getTopEarners',
      feature: 'KspAnalytics',
      status: 'INFO',
    );
    return safeQuery(() async {
      final res = await client
          .from('user_points')
          .select('current_balance, total_earned, profiles(full_name, email)')
          .order('total_earned', ascending: false)
          .limit(10);
      
      return (res as List).map((row) {
        final profile = row['profiles'] as Map? ?? {};
        return {
          'name': profile['full_name'] ?? 'N/A',
          'email': profile['email'] ?? 'N/A',
          'balance': row['current_balance'] ?? 0,
          'totalEarned': row['total_earned'] ?? 0,
        };
      }).toList();
    }, methodName: 'getTopEarners', controllerName: 'KspAnalyticsRepository');
  }

  Future<List<Map<String, dynamic>>> getTopTransfers() async {
    AppLoggerService.debugTrace(
      className: 'KspAnalyticsRepository',
      method: 'getTopTransfers',
      feature: 'KspAnalytics',
      status: 'INFO',
    );
    return safeQuery(() async {
      final res = await client
          .from('point_history')
          .select('points, type, description, created_at, profiles(full_name, email)')
          .or('type.eq.transfer_in,type.eq.transfer_out')
          .order('points', ascending: false)
          .limit(10);
      
      return (res as List).map((row) {
        final profile = row['profiles'] as Map? ?? {};
        return {
          'name': profile['full_name'] ?? 'N/A',
          'email': profile['email'] ?? 'N/A',
          'amount': row['points'] ?? 0,
          'type': row['type'] ?? '',
          'description': row['description'] ?? '',
          'createdAt': DateTime.parse(row['created_at']),
        };
      }).toList();
    }, methodName: 'getTopTransfers', controllerName: 'KspAnalyticsRepository');
  }
}
