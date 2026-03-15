import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../core/services/base_repository.dart';
import '../models/user_model.dart';

/// Profile Repository — handles all CRUD operations for the `profiles` table.
class ProfileRepository extends BaseRepository {
  ProfileRepository(SupabaseClient client) : super('profiles', client);

  /// Fetch all profiles with nested wallets.
  Future<List<User>> getAllProfiles() async {
    return safeQuery<List<User>>(
      () async {
        final response = await client
            .from(tableName)
            .select('*, wallets(*)')
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => User.fromSupabase(json))
            .toList();
      },
      methodName: 'getAllProfiles',
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

  /// Call a database function (RPC).
  Future<void> callRpc(String fnName, Map<String, dynamic> params) async {
    await safeQuery(
      () => client.rpc(fnName, params: params),
      methodName: 'rpc:$fnName',
    );
  }
}
