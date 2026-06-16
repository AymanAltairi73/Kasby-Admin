import '../../../core/services/app_logger_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/user_model.dart';

/// Server-side user management via Supabase RPCs (audit + notifications).
class UserManagementService {
  UserManagementService._();

  static Future<Map<String, dynamic>> updateUserProfile(User user) async {
    return AppLoggerService.traceAsync(
      className: 'UserManagementService',
      method: 'updateUserProfile',
      feature: 'Users',
      params: {'userId': user.id},
      operation: () async {
        final result = await SupabaseService.client.rpc(
          'fn_admin_update_user_profile',
          params: {
            'p_target_user_id': user.id,
            'p_updates': user.toSupabase(),
          },
        );
        if (result is Map<String, dynamic>) return result;
        if (result is Map) return Map<String, dynamic>.from(result);
        return <String, dynamic>{};
      },
    );
  }

  static Future<void> blockUser(String userId, String reason) async {
    await AppLoggerService.traceAsync(
      className: 'UserManagementService',
      method: 'blockUser',
      feature: 'Users',
      params: {'userId': userId},
      operation: () => SupabaseService.client.rpc(
        'fn_admin_block_user',
        params: {
          'p_target_user_id': userId,
          'p_reason': reason.trim(),
        },
      ),
    );
  }

  static Future<void> unblockUser(String userId) async {
    await AppLoggerService.traceAsync(
      className: 'UserManagementService',
      method: 'unblockUser',
      feature: 'Users',
      params: {'userId': userId},
      operation: () => SupabaseService.client.rpc(
        'fn_admin_unblock_user',
        params: {'p_target_user_id': userId},
      ),
    );
  }

  static Future<User?> fetchUserById(String userId) async {
    final response = await SupabaseService.client
        .from('profiles')
        .select('*, wallets!wallets_user_id_fkey(*)')
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return User.fromSupabase(response);
  }
}
