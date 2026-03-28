import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'audio_service.dart';

class AdminListenerService extends GetxService {
  RealtimeChannel? _transactionChannel;
  RealtimeChannel? _applicationChannel;

  Future<AdminListenerService> init() async {
    _setupListeners();
    return this;
  }

  void _setupListeners() {
    // 1. Listen for new pending transactions (deposits/withdrawals)
    _transactionChannel = SupabaseService.client
        .channel('admin-transactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          callback: (payload) {
            final status = payload.newRecord['status'];
            final type = payload.newRecord['type'];
            
            // Play sound for new pending deposits/withdrawals
            if (status == 'pending' && (type == 'deposit' || type == 'withdrawal')) {
              Get.find<AudioService>().playNotification();
            }
          },
        )
        .subscribe();

    // 2. Listen for new agent applications
    _applicationChannel = SupabaseService.client
        .channel('admin-applications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'agent_applications',
          callback: (payload) {
            final status = payload.newRecord['status'];
            if (status == 'pending') {
              Get.find<AudioService>().playNotification();
            }
          },
        )
        .subscribe();
  }

  @override
  void onClose() {
    _transactionChannel?.unsubscribe();
    _applicationChannel?.unsubscribe();
    super.onClose();
  }
}
