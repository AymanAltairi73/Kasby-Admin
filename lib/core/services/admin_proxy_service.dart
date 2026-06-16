import 'app_logger_service.dart';
import 'supabase_service.dart';

/// Admin Proxy Service — routes privileged admin operations through
/// the admin-proxy Edge Function instead of embedding the service role key.
///
/// This eliminates the security risk of shipping service role credentials
/// inside the APK. The Edge Function validates the caller is an admin
/// before executing any operation.
class AdminProxyService {
  AdminProxyService._();

  static Map<String, Object?> _safeRpcParams(Map<String, dynamic> params) {
    final safe = <String, Object?>{};
    for (final entry in params.entries) {
      final key = entry.key;
      if (key == 'password' || key == 'attributes' || key == 'user_metadata') {
        continue;
      }
      final value = entry.value;
      if (key == 'user_id' || key == 'email') {
        final text = value?.toString() ?? '';
        safe[key] = text.length > 8 ? '${text.substring(0, 8)}...' : text;
      } else {
        safe[key] = value;
      }
    }
    return safe;
  }

  static Future<Map<String, dynamic>> _invoke(
    String operation,
    Map<String, dynamic> params,
  ) {
    return AppLoggerService.traceAsync(
      className: 'AdminProxyService',
      method: operation,
      feature: 'Core',
      params: {
        'operation': operation,
        ..._safeRpcParams(params),
      },
      operation: () async {
        final response = await SupabaseService.client.functions.invoke(
          'admin-proxy',
          body: {'operation': operation, 'params': params},
        );

        if (response.status != 200) {
          final errorBody = response.data;
          String message;
          if (errorBody is Map) {
            final raw = errorBody['error'];
            if (raw is String && raw.isNotEmpty) {
              message = raw;
            } else if (raw != null) {
              message = raw.toString();
            } else {
              message = 'Admin proxy error (${response.status})';
            }
          } else {
            message = 'Admin proxy error (${response.status})';
          }
          throw Exception(message);
        }

        return response.data as Map<String, dynamic>;
      },
      onSuccessParams: (result) {
        final users = result['users'];
        if (users is List) {
          return {'userCount': users.length};
        }
        final user = result['user'];
        if (user is Map && user['id'] != null) {
          final id = user['id'].toString();
          return {
            'userId': id.length > 8 ? '${id.substring(0, 8)}...' : id,
          };
        }
        return <String, dynamic>{};
      },
    );
  }

  /// Create a new auth user via Edge Function
  static Future<String?> createUser({
    required String email,
    required String password,
    Map<String, dynamic>? userMetadata,
  }) async {
    final result = await _invoke('create_user', {
      'email': email,
      'password': password,
      'user_metadata': userMetadata ?? {},
    });

    return result['user']?['id'] as String?;
  }

  /// Delete an auth user via Edge Function
  static Future<void> deleteUser(String userId) async {
    await _invoke('delete_user', {'user_id': userId});
  }

  /// Update an auth user's attributes via Edge Function
  static Future<void> updateUser(
    String userId,
    Map<String, dynamic> attributes,
  ) async {
    await _invoke('update_user', {
      'user_id': userId,
      'attributes': attributes,
    });
  }

  /// List auth users (paginated) via Edge Function
  static Future<List<Map<String, dynamic>>> listUsers({
    int page = 1,
    int perPage = 50,
  }) async {
    final result = await _invoke('list_users', {
      'page': page,
      'per_page': perPage,
    });

    return List<Map<String, dynamic>>.from(result['users'] ?? []);
  }

  /// Get a single auth user by ID via Edge Function
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final result = await _invoke('get_user', {'user_id': userId});
    return result['user'] as Map<String, dynamic>?;
  }

  /// Add balance to a user wallet via admin-proxy (service_role RPC)
  static Future<void> addBalance(String userId, double amount) async {
    await _invoke('add_balance', {
      'user_id': userId,
      'amount': amount,
    });
  }

  /// Deduct balance from a user wallet via admin-proxy (service_role RPC)
  static Future<void> deductBalance(String userId, double amount) async {
    await _invoke('deduct_balance', {
      'user_id': userId,
      'amount': amount,
    });
  }
}
