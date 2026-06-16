import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_notification_navigation_service.dart';
import 'app_logger_service.dart';
import 'supabase_service.dart';
import 'audio_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/auth/controllers/auth_controller.dart';

class AdminListenerService extends GetxService {
  RealtimeChannel? _adminChannel;
  RealtimeChannel? _notificationChannel;
  Timer? _reconnectTimer;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<AdminListenerService> init() async {
    AppLoggerService.debugTrace(
      className: 'AdminListenerService',
      method: 'init',
      feature: 'Core',
      status: 'INFO',
    );
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        AdminNotificationNavigationService.navigateFromLocalPayload(
          details.payload,
        );
      },
    );

    final authController = Get.find<AuthController>();

    ever(authController.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        _setupListeners();
        AdminNotificationNavigationService.processPendingNavigation();
      } else {
        _cleanupListeners();
      }
    });

    if (authController.isLoggedIn.value) {
      _setupListeners();
    }

    return this;
  }

  void _setupListeners() {
    AppLoggerService.debugTrace(
      className: 'AdminListenerService',
      method: '_setupListeners',
      feature: 'Core',
      status: 'INFO',
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanupListeners();

    _adminChannel = SupabaseService.client.channel('admin-global');

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
            body:
                'لديك طلب ${type == 'deposit' ? 'إيداع' : 'سحب'} جديد بانتظار الموافقة',
            route: '/transactions',
            entityId: payload.newRecord['id']?.toString(),
            entityType: 'transaction',
          );
        }
      },
    );

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
            route: '/agents',
            entityId: payload.newRecord['id']?.toString(),
            entityType: 'agent_application',
          );
        }
      },
    );

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
            route: '/kyc',
            entityId: payload.newRecord['id']?.toString(),
            entityType: 'profile',
          );
        }
      },
    );

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
            route: '/loans',
            entityId: payload.newRecord['id']?.toString(),
            entityType: 'loan',
          );
        }
      },
    );

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
            route: '/user-investments',
            entityId: payload.newRecord['id']?.toString(),
            entityType: 'investment',
          );
        }
      },
    );

    _notificationChannel =
        SupabaseService.client.channel('admin-notifications');
    _notificationChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (payload) {
        final roleTarget = payload.newRecord['role_target'] as String?;
        if (roleTarget != 'admin') return;

        _showAdminAlert(
          title: payload.newRecord['title']?.toString() ?? 'إشعار جديد',
          body: payload.newRecord['message']?.toString() ?? '',
          route: AdminNotificationNavigationService.resolveRoute(
            type: payload.newRecord['type']?.toString(),
            deepLink: payload.newRecord['deep_link']?.toString(),
            entityType: payload.newRecord['entity_type']?.toString(),
          ),
          entityId: payload.newRecord['entity_id']?.toString(),
          entityType: payload.newRecord['entity_type']?.toString(),
          notificationType: payload.newRecord['type']?.toString(),
        );
      },
    );

    _adminChannel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        AppLoggerService.debugTrace(
          className: 'AdminListenerService',
          method: 'subscribe',
          feature: 'Core',
          status: 'FAILED',
          params: {'status': status.name},
          error: error,
        );
        _handleRetry();
      } else if (status == RealtimeSubscribeStatus.subscribed) {
        AppLoggerService.debugTrace(
          className: 'AdminListenerService',
          method: 'subscribe',
          feature: 'Core',
          status: 'SUCCESS',
          message: 'Admin global channel subscribed',
        );
      }
    });

    _notificationChannel!.subscribe();
  }

  void _handleRetry() {
    if (_reconnectTimer != null) return;
    AppLoggerService.debugTrace(
      className: 'AdminListenerService',
      method: '_handleRetry',
      feature: 'Core',
      status: 'WARNING',
      message: 'Scheduling listener reconnect in 10s',
    );
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      if (Get.find<AuthController>().isLoggedIn.value) {
        _setupListeners();
      }
    });
  }

  void _cleanupListeners() {
    AppLoggerService.debugTrace(
      className: 'AdminListenerService',
      method: '_cleanupListeners',
      feature: 'Core',
      status: 'INFO',
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _adminChannel?.unsubscribe();
    _adminChannel = null;
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
  }

  void _showAdminAlert({
    required String title,
    required String body,
    required String route,
    String? entityId,
    String? entityType,
    String? notificationType,
  }) {
    AppLoggerService.debugTrace(
      className: 'AdminListenerService',
      method: '_showAdminAlert',
      feature: 'Core',
      status: 'INFO',
      params: {
        'route': route,
        'entityType': entityType ?? '',
        'entityId': entityId ?? '',
      },
    );
    Get.find<AudioService>().playNotification();

    _showLocalNotification(
      title: title,
      body: body,
      route: route,
      entityId: entityId,
      entityType: entityType,
      notificationType: notificationType,
    );

    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF16161E).withValues(alpha: 0.95),
        colorText: const Color(0xFFC9A24D),
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
        borderRadius: 16,
        onTap: (_) {
          AdminNotificationNavigationService.navigateFromRealtimeAlert(
            route: route,
            entityId: entityId,
            entityType: entityType,
          );
        },
      );
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String route,
    String? entityId,
    String? entityType,
    String? notificationType,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
    );
    const platformDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: jsonEncode({
        'route': route,
        'entity_id': entityId ?? '',
        'entity_type': entityType ?? '',
        'type': notificationType ?? 'admin_alert',
        'role_target': 'admin',
      }),
    );
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'AdminListenerService',
      method: 'onClose',
      feature: 'Core',
      status: 'INFO',
    );
    _cleanupListeners();
    super.onClose();
  }
}
