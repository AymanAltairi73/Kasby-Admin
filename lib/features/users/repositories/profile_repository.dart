import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../core/services/base_repository.dart';
import '../models/user_model.dart';
import '../../investments/models/investment_model.dart';
import '../../transactions/models/transaction_model.dart';
import '../models/user_activity_model.dart';

/// Profile Repository — handles all CRUD operations for the `profiles` table.
class ProfileRepository extends BaseRepository {
  ProfileRepository(SupabaseClient client) : super('profiles', client);

  /// Fetch all profiles with nested wallets (legacy).
  Future<List<User>> getAllProfiles() async {
    return safeQuery<List<User>>(
      () async {
        final response = await client
            .from(tableName)
            .select('*, wallets!wallets_user_id_fkey(*)')
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => User.fromSupabase(json))
            .toList();
      },
      methodName: 'getAllProfiles',
    );
  }

  /// Fetch paginated profiles with wallets.
  Future<List<User>> getProfilesPaginated({
    int from = 0,
    int to = 19,
  }) async {
    return safeQuery<List<User>>(
      () async {
        final response = await client
            .from(tableName)
            .select('*, wallets!wallets_user_id_fkey(*)')
            .range(from, to)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => User.fromSupabase(json))
            .toList();
      },
      methodName: 'getProfilesPaginated',
    );
  }

  /// Update a profile's data.
  Future<void> updateProfile(String id, Map<String, dynamic> data) async {
    await safeQuery(
      () => client.from(tableName).update(data).eq('id', id),
      methodName: 'updateProfile',
    );
  }

  /// Delete a profile.
  Future<void> deleteProfile(String id) async {
    await safeQuery(
      () => client.from(tableName).delete().eq('id', id),
      methodName: 'deleteProfile',
    );
  }

  /// Fetch a user's investments.
  Future<List<UserInvestment>> getUserInvestments(String userId) async {
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
    );
  }

  /// Fetch a user's transactions.
  Future<List<Transaction>> getUserTransactions(String userId) async {
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
    );
  }

  /// Fetch a user's activity logs.
  Future<List<UserActivity>> getUserActivities(String userId) async {
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
    );
  }

  /// Call a database function (RPC).
  Future<void> callRpc(String fnName, Map<String, dynamic> params) async {
    await safeQuery(
      () => client.rpc(fnName, params: params),
      methodName: 'rpc:$fnName',
    );
  }
}
