import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'audio_service.dart';
import '../../features/auth/controllers/auth_controller.dart';

class AdminListenerService extends GetxService {
  RealtimeChannel? _transactionChannel;
  RealtimeChannel? _applicationChannel;
  Timer? _reconnectTimer;

  Future<AdminListenerService> init() async {
    // Wait for AuthController to be ready
    final authController = Get.find<AuthController>();

    // Listen to login status to start/stop listeners
    ever(authController.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        _setupListeners();
      } else {
        _cleanupListeners();
      }
    });

    // Initial setup if already logged in (e.g. after hot reload)
    if (authController.isLoggedIn.value) {
      _setupListeners();
    }

    return this;
  }

  void _setupListeners() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanupListeners(); // Avoid duplicate subscriptions

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
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
            Get.printError(info: '[AdminListener] Transaction stream status: $status, error: $error');
            _handleRetry();
          }
        });

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
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
            Get.printError(info: '[AdminListener] Application stream status: $status, error: $error');
            _handleRetry();
          }
        });
  }

  void _handleRetry() {
    if (_reconnectTimer != null) return;
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      if (Get.find<AuthController>().isLoggedIn.value) {
        _setupListeners();
      }
    });
  }

  void _cleanupListeners() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _transactionChannel?.unsubscribe();
    _transactionChannel = null;
    _applicationChannel?.unsubscribe();
    _applicationChannel = null;
  }

  @override
  void onClose() {
    _cleanupListeners();
    super.onClose();
  }
}
