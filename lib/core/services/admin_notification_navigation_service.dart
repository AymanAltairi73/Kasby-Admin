import 'dart:convert';

import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/chat/models/chat_model.dart';
import '../../features/dashboard/controllers/main_controller.dart';
import 'app_logger_service.dart';
import 'supabase_service.dart';

/// Centralized notification deep-link router for the Kasby admin app.
class AdminNotificationNavigationService {
  AdminNotificationNavigationService._();

  static String? _lastNavigationKey;
  static Map<String, String>? _pendingPayload;

  static Future<void> navigateFromPayload(
    Map<String, dynamic> rawData, {
    bool fromUserTap = true,
  }) async {
    AppLoggerService.debugTrace(
      className: 'AdminNotificationNavigationService',
      method: 'navigateFromPayload',
      feature: 'Core',
      status: 'INFO',
      params: {
        'fromUserTap': fromUserTap,
        'route': rawData['route']?.toString() ?? '',
        'type': rawData['type']?.toString() ?? '',
      },
    );
    final data = rawData.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );

    if (!Get.find<AuthController>().isLoggedIn.value) {
      _pendingPayload = data;
      AppLoggerService.debugTrace(
        className: 'AdminNotificationNavigationService',
        method: 'navigateFromPayload',
        feature: 'Core',
        status: 'WARNING',
        message: 'User not logged in — payload deferred',
      );
      return;
    }

    await _executeNavigation(data, fromUserTap: fromUserTap);
  }

  static Future<void> processPendingNavigation() async {
    AppLoggerService.debugTrace(
      className: 'AdminNotificationNavigationService',
      method: 'processPendingNavigation',
      feature: 'Core',
      status: 'INFO',
    );
    final pending = _pendingPayload;
    if (pending == null) return;
    if (!Get.find<AuthController>().isLoggedIn.value) return;
    _pendingPayload = null;
    await _executeNavigation(pending, fromUserTap: true);
  }

  static Future<void> navigateFromLocalPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        await navigateFromPayload(decoded, fromUserTap: true);
      }
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AdminNotificationNavigationService',
        method: 'navigateFromLocalPayload',
        feature: 'Core',
        status: 'FAILED',
        error: e,
      );
    }
  }

  static Future<void> navigateFromRealtimeAlert({
    required String route,
    String? entityId,
    String? entityType,
  }) async {
    AppLoggerService.debugTrace(
      className: 'AdminNotificationNavigationService',
      method: 'navigateFromRealtimeAlert',
      feature: 'Core',
      status: 'INFO',
      params: {'route': route, 'entityType': entityType ?? ''},
    );
    await navigateFromPayload(
      {
        'route': route,
        'entity_id': entityId ?? '',
        'entity_type': entityType ?? '',
        'type': 'admin_alert',
      },
      fromUserTap: true,
    );
  }

  static String resolveRoute({
    required String? type,
    String? deepLink,
    String? entityType,
  }) {
    if (deepLink != null && deepLink.isNotEmpty) {
      return deepLink.startsWith('/') ? deepLink : '/$deepLink';
    }

    switch (type) {
      case 'admin_kyc_pending':
      case 'kyc_approved':
      case 'kyc_rejected':
        return '/kyc';
      case 'admin_withdrawal_pending':
      case 'withdrawal_requested':
      case 'withdrawal_approved':
      case 'withdrawal_rejected':
      case 'withdrawal_completed':
        return '/transactions';
      case 'admin_deposit_pending':
      case 'deposit_submitted':
      case 'deposit_approved':
      case 'deposit_rejected':
        return '/transactions';
      case 'admin_new_chat':
      case 'chat_new_message':
      case 'chat_admin_reply':
      case 'chat_escalated':
        return '/chat-list';
      case 'loan_requested':
      case 'loan_approved':
      case 'loan_rejected':
      case 'loan_repayment_due':
      case 'loan_overdue':
      case 'loan_paid':
        return '/loans';
      case 'investment_created':
      case 'investment_matured':
      case 'investment_cancelled':
        return '/user-investments';
      case 'admin_flagged_user':
        return '/users';
      case 'agent_deposit_pending':
      case 'agent_withdrawal_pending':
      case 'agent_role_change':
        return '/agents';
      default:
        if (entityType == 'conversation') return '/chat-list';
        return '/notifications-list';
    }
  }

  static Future<void> _executeNavigation(
    Map<String, String> data, {
    required bool fromUserTap,
  }) async {
    if (!fromUserTap) return;

    var route = data['route'];
    if (route == null || route.isEmpty) {
      route = resolveRoute(
        type: data['type'],
        deepLink: data['deep_link'],
        entityType: data['entity_type'],
      );
    }

    final navKey = '${route}_${data['id']}_${data['entity_id']}';
    if (_lastNavigationKey == navKey) {
      AppLoggerService.debugTrace(
        className: 'AdminNotificationNavigationService',
        method: '_executeNavigation',
        feature: 'Core',
        status: 'INFO',
        message: 'Duplicate navigation skipped',
        params: {'route': route},
      );
      return;
    }
    _lastNavigationKey = navKey;

    AppLoggerService.debugTrace(
      className: 'AdminNotificationNavigationService',
      method: '_executeNavigation',
      feature: 'Core',
      status: 'INFO',
      params: {'route': route, 'entityType': data['entity_type'] ?? ''},
    );

    await Future.delayed(const Duration(milliseconds: 350));

    if (Get.currentRoute == route) return;

    final entityType = data['entity_type'] ?? '';
    final entityId = data['entity_id'] ?? '';

    if (route == '/chat-details' ||
        (route == '/chat-list' &&
            entityType == 'conversation' &&
            entityId.isNotEmpty)) {
      final conversation = await _fetchConversation(entityId);
      if (conversation != null) {
        if (Get.currentRoute != '/chat-details') {
          await Get.toNamed('/chat-details', arguments: conversation);
        }
        return;
      }
    }

    if (Get.currentRoute != route) {
      const tabRoutes = {'/users': 1, '/transactions': 2, '/settings': 3};
      final tabIndex = tabRoutes[route];
      if (tabIndex != null && Get.isRegistered<MainController>()) {
        Get.find<MainController>().changePage(tabIndex);
      } else {
        await Get.toNamed(route);
      }
    }
  }

  static Future<ChatConversation?> _fetchConversation(String id) async {
    AppLoggerService.debugTrace(
      className: 'AdminNotificationNavigationService',
      method: '_fetchConversation',
      feature: 'Core',
      status: 'INFO',
      params: {'conversationId': id},
    );
    try {
      final response = await SupabaseService.client
          .from('chat_conversations')
          .select('*, profiles:user_id(full_name, avatar_url, role, last_seen_at, updated_at)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return ChatConversation.fromSupabase(response);
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AdminNotificationNavigationService',
        method: '_fetchConversation',
        feature: 'Core',
        status: 'FAILED',
        error: e,
      );
      return null;
    }
  }
}
