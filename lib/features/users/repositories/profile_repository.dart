import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/base_repository.dart';
import '../models/user_model.dart';
import '../../investments/models/investment_model.dart';
import '../../transactions/models/transaction_model.dart';
import '../models/user_activity_model.dart';

/// Profile Repository — handles all CRUD operations for the `profiles` table.
class ProfileRepository extends BaseRepository {
  ProfileRepository(SupabaseClient client) : super('profiles', client);

  /// Fetch paginated profiles with optional server-side filters.
  Future<List<User>> getProfilesPaginated({
    int from = 0,
    int to = 49,
    String? search,
    String? status,
    String? kycStatus,
    String? country,
    bool excludeAdmins = true,
  }) async {
    AppLoggerService.debugTrace(
      className: 'ProfileRepository',
      method: 'getProfilesPaginated',
      feature: 'Users',
      status: 'INFO',
      params: {'from': from, 'to': to},
    );
    return safeQuery<List<User>>(
      () async {
        dynamic query = client
            .from(tableName)
            .select('*, wallets!wallets_user_id_fkey(*)');

        if (excludeAdmins) {
          query = query.neq('role', 'admin');
        }
        if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
          query = query.eq('status', status);
        }
        if (kycStatus != null && kycStatus.isNotEmpty && kycStatus.toLowerCase() != 'all') {
          query = query.eq('kyc_status', kycStatus);
        }
        if (country != null && country.isNotEmpty) {
          query = query.eq('country_code', country);
        }
        if (search != null && search.trim().isNotEmpty) {
          final q = '%${search.trim()}%';
          query = query.or(
            'full_name.ilike.$q,email.ilike.$q,phone.ilike.$q',
          );
        }

        final response = await query
            .range(from, to)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => User.fromSupabase(json))
            .toList();
      },
      methodName: 'getProfilesPaginated',
      controllerName: 'ProfileRepository',
    );
  }

  /// Update a profile's data.
  Future<void> updateProfile(String id, Map<String, dynamic> data) async {
    AppLoggerService.debugTrace(
      className: 'ProfileRepository',
      method: 'updateProfile',
      feature: 'Users',
      status: 'INFO',
      params: {'profileId': id},
    );
    await safeQuery(
      () => client.from(tableName).update(data).eq('id', id),
      methodName: 'updateProfile',
      controllerName: 'ProfileRepository',
    );
  }

  /// Delete a profile.
  Future<void> deleteProfile(String id) async {
    AppLoggerService.debugTrace(
      className: 'ProfileRepository',
      method: 'deleteProfile',
      feature: 'Users',
      status: 'INFO',
      params: {'profileId': id},
    );
    await safeQuery(
      () => client.from(tableName).delete().eq('id', id),
      methodName: 'deleteProfile',
      controllerName: 'ProfileRepository',
    );
  }

  /// Fetch a user's investments.
  Future<List<UserInvestment>> getUserInvestments(String userId) async {
    AppLoggerService.debugTrace(
      className: 'ProfileRepository',
      method: 'getUserInvestments',
      feature: 'Users',
      status: 'INFO',
      params: {'userId': userId},
    );
    return safeQuery<List<UserInvestment>>(
      () async {
        final response = await client
            .from('user_investments')
            .select('*, investment_plans!user_investments_plan_id_fkey(*)')
            .eq('user_id', userId)
            .order('start_date', ascending: false);

        return (response as List)
            .map((json) => UserInvestment.fromSupabase(json))
            .toList();
      },
      methodName: 'getUserInvestments',
      controllerName: 'ProfileRepository',
    );
  }

  /// Fetch a user's transactions.
  Future<List<Transaction>> getUserTransactions(String userId) async {
    AppLoggerService.debugTrace(
      className: 'ProfileRepository',
      method: 'getUserTransactions',
      feature: 'Users',
      status: 'INFO',
      params: {'userId': userId},
    );
    return safeQuery<List<Transaction>>(
      () async {
        final response = await client
            .from('transactions')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => Transaction.fromSupabase(json))
            .toList();
      },
      methodName: 'getUserTransactions',
      controllerName: 'ProfileRepository',
    );
  }

  /// Fetch a user's activity logs.
  Future<List<UserActivity>> getUserActivities(String userId) async {
    AppLoggerService.debugTrace(
      className: 'ProfileRepository',
      method: 'getUserActivities',
      feature: 'Users',
      status: 'INFO',
      params: {'userId': userId},
    );
    return safeQuery<List<UserActivity>>(
      () async {
        final response = await client
            .from('user_activities')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => UserActivity.fromJson(json))
            .toList();
      },
      methodName: 'getUserActivities',
      controllerName: 'ProfileRepository',
    );
  }

  /// Call a database function (RPC).
  Future<void> callRpc(String fnName, Map<String, dynamic> params) async {
    AppLoggerService.debugTrace(
      className: 'ProfileRepository',
      method: 'callRpc',
      feature: 'Users',
      status: 'INFO',
      params: {'rpc': fnName},
    );
    await safeQuery(
      () => client.rpc(fnName, params: params),
      methodName: 'rpc:$fnName',
      controllerName: 'ProfileRepository',
    );
  }
}
