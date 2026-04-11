import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'audio_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/auth/controllers/auth_controller.dart';

class AdminListenerService extends GetxService {
  RealtimeChannel? _transactionChannel;
  RealtimeChannel? _applicationChannel;
  RealtimeChannel? _kycChannel;
  RealtimeChannel? _loanChannel;
  Timer? _reconnectTimer;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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
              _showLocalNotification(
                title: '💰 معاملة جديدة',
                body: 'لديك طلب ${type == 'deposit' ? 'إيداع' : 'سحب'} جديد بانتظار الموافقة',
              );
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
              _showLocalNotification(
                title: '🌟 طلب وكالة',
                body: 'هناك طلب انضمام وكيل جديد بانتظار المراجعة',
              );
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
            Get.printError(info: '[AdminListener] Application stream status: $status, error: $error');
            _handleRetry();
          }
        });

    // 3. Listen for new KYC submissions
    _kycChannel = SupabaseService.client
        .channel('admin-kyc')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            final newKyc = payload.newRecord['kyc_status'];
            final oldKyc = payload.oldRecord['kyc_status'];
            if (newKyc == 'pending' && oldKyc != 'pending') {
              Get.find<AudioService>().playNotification();
              _showLocalNotification(
                title: '🆔 توثيق جديد',
                body: 'قام مستخدم برفع مستندات توثيق جديدة، يرجى مراجعتها',
              );
            }
          },
        )
        .subscribe();

    // 4. Listen for new Loan applications
    _loanChannel = SupabaseService.client
        .channel('admin-loans')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'loans',
          callback: (payload) {
            final status = payload.newRecord['status'];
            if (status == 'pending') {
              Get.find<AudioService>().playNotification();
              _showLocalNotification(
                title: '💸 طلب قرض',
                body: 'قام مستخدم بتقديم طلب قرض جديد، تفقد قائمة القروض',
              );
            }
          },
        )
        .subscribe();
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
    _kycChannel?.unsubscribe();
    _kycChannel = null;
    _loanChannel?.unsubscribe();
    _loanChannel = null;
  }

  Future<void> _showLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  void onClose() {
    _cleanupListeners();
    super.onClose();
  }
}
