import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

/// Notification Controller — manages notifications via Supabase
/// Notifications are persisted and can be audited
class NotificationController extends GetxController {
  final sentNotifications = <NotificationModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  /// Load notifications from Supabase
  Future<void> loadNotifications() async {
    debugPrint('[NotificationController][loadNotifications] Fetching data from /notifications');
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('notifications')
          .select()
          .order('sent_at', ascending: false)
          .limit(100);

      debugPrint('[NotificationController][loadNotifications] Response: ${response.length} notifications');
      sentNotifications.assignAll(
        (response as List).map(
          (e) => NotificationModel(
            id: e['id'].toString(),
            title: e['title'] ?? '',
            message: e['message'] ?? '',
            target: e['target'] ?? 'all',
            sentAt: DateTime.tryParse(e['sent_at'] ?? '') ?? DateTime.now(),
            status: e['status'] ?? 'Sent',
          ),
        ),
      );
      debugPrint('[NotificationController][loadNotifications] Successfully loaded ${sentNotifications.length} notifications');
    } catch (e, stackTrace) {
      debugPrint('[NotificationController][loadNotifications] Error: $e');
      debugPrint('[NotificationController][loadNotifications] Stack trace: $stackTrace');
      debugPrint('[NotificationController][loadNotifications] Endpoint: /notifications');
      AppLoggerService.logError(
        controller: 'NotificationController',
        method: 'loadNotifications',
        error: e,
        stackTrace: stackTrace,
      );
      // Keep existing list if load fails
    }
    isLoading.value = false;
  }

  /// Send notification — persisted to Supabase
  /// Inserts one row per target user (user_id is NOT NULL in DB)
  Future<void> sendNotification(
    String title,
    String message,
    String target, {
    String? specificUserId,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      target: target,
      sentAt: DateTime.now(),
      status: 'sent',
    );

    sentNotifications.insert(0, notification);

    try {
      // Determine which user IDs to send to
      List<String> userIds = [];

      switch (target) {
        case 'all':
          final users = await SupabaseService.client
              .from('profiles')
              .select('id');
          userIds = (users as List).map((u) => u['id'] as String).toList();
          break;

        case 'active':
          final users = await SupabaseService.client
              .from('profiles')
              .select('id')
              .eq('is_active', true);
          userIds = (users as List).map((u) => u['id'] as String).toList();
          break;

        case 'investors':
          // Users who have active investments
          final investors = await SupabaseService.client
              .from('user_investments')
              .select('user_id')
              .eq('status', 'active');
          userIds = (investors as List)
              .map((u) => u['user_id'] as String)
              .toSet()
              .toList(); // unique IDs
          break;

        case 'agents':
          // Fetch agent user IDs from agents table
          final agents = await SupabaseService.client
              .from('agents')
              .select('user_id');
          userIds = (agents as List)
              .where((a) => a['user_id'] != null)
              .map((a) => a['user_id'] as String)
              .toSet()
              .toList();
          break;

        case 'specific':
          if (specificUserId != null && specificUserId.isNotEmpty) {
            userIds = [specificUserId];
          } else {
            debugPrint('[NotificationController] ⚠ No user selected for specific target');
            return;
          }
          break;

        default:
          final users = await SupabaseService.client
              .from('profiles')
              .select('id');
          userIds = (users as List).map((u) => u['id'] as String).toList();
      }

      if (userIds.isEmpty) {
        debugPrint('[NotificationController] ⚠ No users found for target: $target');
        return;
      }

      // Build batch rows
      final now = DateTime.now().toIso8601String();
      final sentBy = SupabaseService.auth.currentUser?.id;
      final rows = userIds.map((uid) => {
        'user_id': uid,
        'title': title,
        'message': message,
        'target': target,
        'type': 'notification',
        'sent_at': now,
        'status': 'sent',
        'sent_by': sentBy,
      }).toList();

      // Insert all at once (batch)
      await SupabaseService.client.from('notifications').insert(rows);
      debugPrint('[NotificationController] √ Sent notification to ${userIds.length} users');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'NotificationController',
        method: 'sendNotification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Schedule notification — persisted to Supabase
  Future<void> scheduleNotification(
    String title,
    String message,
    String target,
    DateTime scheduledTime,
  ) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      target: target,
      sentAt: scheduledTime,
      status: 'scheduled',
    );

    sentNotifications.insert(0, notification);

    try {
      // Fetch target users
      final users = await SupabaseService.client
          .from('profiles')
          .select('id');
      final userIds = (users as List).map((u) => u['id'] as String).toList();

      if (userIds.isEmpty) return;

      final sentBy = SupabaseService.auth.currentUser?.id;
      final rows = userIds.map((uid) => {
        'user_id': uid,
        'title': title,
        'message': message,
        'target': target,
        'type': 'notification',
        'sent_at': scheduledTime.toIso8601String(),
        'status': 'scheduled',
        'sent_by': sentBy,
      }).toList();

      await SupabaseService.client.from('notifications').insert(rows);
      debugPrint('[NotificationController] √ Scheduled notification for ${userIds.length} users');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'NotificationController',
        method: 'scheduleNotification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
