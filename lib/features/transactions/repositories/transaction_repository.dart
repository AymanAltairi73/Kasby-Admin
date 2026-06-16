import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/base_repository.dart';
import '../models/transaction_model.dart';

/// Transaction Repository — handles financial transactions and their relationships.
class TransactionRepository extends BaseRepository {
  TransactionRepository(SupabaseClient client) : super('transactions', client);

  /// Fetch paginated transactions with user names.
  Future<List<Transaction>> getTransactionsPaginated({
    int from = 0,
    int to = 499,
    String? type,
    String? status,
  }) async {
    AppLoggerService.debugTrace(
      className: 'TransactionRepository',
      method: 'getTransactionsPaginated',
      feature: 'Transactions',
      status: 'INFO',
      params: {'from': from, 'to': to, 'type': type ?? 'all', 'status': status ?? 'all'},
    );
    return safeQuery<List<Transaction>>(
      () async {
        var query = client
            .from(tableName)
            .select('*, profiles!transactions_user_id_fkey(full_name), counterpart_profile:profiles!transactions_counterpart_user_id_fkey(full_name)');

        if (type != null && type != 'Both' && type != 'all') {
          query = query.eq('type', type);
        }
        if (status != null && status != 'all') {
          query = query.eq('status', status);
        }

        final response = await query
            .range(from, to)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => Transaction.fromSupabase(json))
            .toList();
      },
      methodName: 'getTransactionsPaginated',
      controllerName: 'TransactionRepository',
    );
  }

  /// Call a transaction processing RPC.
  Future<void> processTransaction(String fnName, Map<String, dynamic> params) async {
    AppLoggerService.debugTrace(
      className: 'TransactionRepository',
      method: 'processTransaction',
      feature: 'Transactions',
      status: 'INFO',
      params: {'rpc': fnName},
    );
    await safeQuery(
      () => client.rpc(fnName, params: params),
      methodName: 'rpc:$fnName',
      controllerName: 'TransactionRepository',
    );
  }
}
