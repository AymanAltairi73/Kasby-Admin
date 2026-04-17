import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'audio_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/auth/controllers/auth_controller.dart';

class AdminListenerService extends GetxService {
  RealtimeChannel? _adminChannel;
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

    _adminChannel = SupabaseService.client.channel('admin-global');

    // 1. Listen for new pending transactions (deposits/withdrawals)
    _adminChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'transactions',
      callback: (payload) {
        final status = payload.newRecord['status'];
        final type = payload.newRecord['type'];
        if (status == 'pending' && (type == 'deposit' || type == 'withdrawal')) {
          _showAdminAlert(
            title: '💰 معاملة جديدة',
            body: 'لديك طلب ${type == 'deposit' ? 'إيداع' : 'سحب'} جديد بانتظار الموافقة',
          );
        }
      },
    );

    // 2. Listen for new agent applications
    _adminChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'agent_applications',
      callback: (payload) {
        final status = payload.newRecord['status'];
        if (status == 'pending') {
          _showAdminAlert(
            title: '🌟 طلب وكالة',
            body: 'هناك طلب انضمام وكيل جديد بانتظار المراجعة',
          );
        }
      },
    );

    // 3. Listen for new KYC submissions (profiles update)
    _adminChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      callback: (payload) {
        final newKyc = payload.newRecord['kyc_status'];
        final oldKyc = payload.oldRecord['kyc_status'];
        if (newKyc == 'pending' && oldKyc != 'pending') {
          _showAdminAlert(
            title: '🆔 توثيق جديد',
            body: 'قام مستخدم برفع مستندات توثيق جديدة، يرجى مراجعتها',
          );
        }
      },
    );

    // 4. Listen for new Loan applications
    _adminChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'loans',
      callback: (payload) {
        final status = payload.newRecord['status'];
        if (status == 'pending') {
          _showAdminAlert(
            title: '💸 طلب قرض',
            body: 'قام مستخدم بتقديم طلب قرض جديد، تفقد قائمة القروض',
          );
        }
      },
    );

    // 5. Listen for new Investment applications
    _adminChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'user_investments',
      callback: (payload) {
        final status = payload.newRecord['status'];
        if (status == 'pending') {
          _showAdminAlert(
            title: '📈 استثمار جديد',
            body: 'هناك طلب استثمار جديد بانتظار المراجعة والموافقة',
          );
        }
      },
    );

    _adminChannel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
        Get.printError(info: '[AdminListener] Global stream status: $status, error: $error');
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
    _adminChannel?.unsubscribe();
    _adminChannel = null;
  }

  void _showAdminAlert({required String title, required String body}) {
    // 1. Play sound
    Get.find<AudioService>().playNotification();

    // 2. Show Local OS Notification
    _showLocalNotification(title: title, body: body);

    // 3. Show In-App Snackbar for immediate visual feedback
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF16161E).withValues(alpha: 0.95),
        colorText: const Color(0xFFC9A24D), // Kasby Gold
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
        borderRadius: 16,
        boxShadows: [
          BoxShadow(
            color: const Color(0xFFC9A24D).withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      );
    }
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
