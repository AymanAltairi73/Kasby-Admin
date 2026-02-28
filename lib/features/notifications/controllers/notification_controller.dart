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
    debugPrint('[NotificationController] ▶ Loading notifications...');
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('notifications')
          .select()
          .order('sent_at', ascending: false)
          .limit(100);

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
    } catch (e, stackTrace) {
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
  Future<void> sendNotification(
    String title,
    String message,
    String target,
  ) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      target: target,
      sentAt: DateTime.now(),
      status: 'Sent',
    );

    sentNotifications.insert(0, notification);

    try {
      await SupabaseService.client.from('notifications').insert({
        'title': title,
        'message': message,
        'target': target,
        'sent_at': DateTime.now().toIso8601String(),
        'status': 'Sent',
        'sent_by': SupabaseService.auth.currentUser?.id,
      });
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'NotificationController',
        method: 'sendNotification',
        error: e,
        stackTrace: stackTrace,
      );
      // Notification is still shown locally even if persist fails
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
      status: 'Scheduled',
    );

    sentNotifications.insert(0, notification);

    try {
      await SupabaseService.client.from('notifications').insert({
        'title': title,
        'message': message,
        'target': target,
        'sent_at': scheduledTime.toIso8601String(),
        'status': 'Scheduled',
        'sent_by': SupabaseService.auth.currentUser?.id,
      });
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
