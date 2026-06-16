import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

class NotificationController extends GetxController {
  final sentNotifications = <NotificationModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'NotificationController',
      method: 'onInit',
      feature: 'Notifications',
      status: 'INFO',
    );
    super.onInit();
    loadNotifications();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'NotificationController',
      method: 'onClose',
      feature: 'Notifications',
      status: 'INFO',
    );
    super.onClose();
  }

  Future<void> loadNotifications() async {
    AppLoggerService.debugTrace(
      className: 'NotificationController',
      method: 'loadNotifications',
      feature: 'Notifications',
      status: 'INFO',
    );
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<String>> _resolveTargetUserIds(
    String target, {
    String? specificUserId,
  }) async {
    switch (target) {
      case 'all':
        final users = await SupabaseService.client.from('profiles').select('id');
        return (users as List).map((u) => u['id'] as String).toList();

      case 'active':
        final users = await SupabaseService.client
            .from('profiles')
            .select('id')
            .eq('status', 'active');
        return (users as List).map((u) => u['id'] as String).toList();

      case 'investors':
        final investors = await SupabaseService.client
            .from('user_investments')
            .select('user_id')
            .eq('status', 'active');
        return (investors as List)
            .map((u) => u['user_id'] as String)
            .toSet()
            .toList();

      case 'agents':
        final agents = await SupabaseService.client
            .from('agents')
            .select('user_id, id');
        return (agents as List)
            .map((a) => (a['user_id'] ?? a['id']) as String?)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

      case 'specific':
        if (specificUserId != null && specificUserId.isNotEmpty) {
          return [specificUserId];
        }
        return [];

      default:
        final users = await SupabaseService.client.from('profiles').select('id');
        return (users as List).map((u) => u['id'] as String).toList();
    }
  }

  String _dbTargetValue(String target) {
    const allowed = {'all', 'specific', 'social', 'chat'};
    if (allowed.contains(target)) return target;
    return 'specific';
  }

  Future<void> sendNotification(
    String title,
    String message,
    String target, {
    String? specificUserId,
  }) async {
    try {
      final userIds = await _resolveTargetUserIds(
        target,
        specificUserId: specificUserId,
      );

      if (userIds.isEmpty) {
        Get.snackbar('تنبيه', 'لا يوجد مستخدمون للهدف المحدد');
        return;
      }

      final sentBy = SupabaseService.auth.currentUser?.id;
      await SupabaseService.client.rpc(
        'fn_create_bulk_notification',
        params: {
          'p_user_ids': userIds,
          'p_title': title,
          'p_message': message,
          'p_target': _dbTargetValue(target),
          'p_sent_by': sentBy,
          'p_status': 'sent',
        },
      );

      await loadNotifications();
      Get.snackbar('نجح', 'تم إرسال الإشعار بنجاح');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'NotificationController',
        method: 'sendNotification',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل إرسال الإشعار');
      rethrow;
    }
  }

  Future<void> scheduleNotification(
    String title,
    String message,
    String target,
    DateTime scheduledTime,
  ) async {
    try {
      final userIds = await _resolveTargetUserIds(target);
      if (userIds.isEmpty) return;

      final sentBy = SupabaseService.auth.currentUser?.id;
      await SupabaseService.client.rpc(
        'fn_create_bulk_notification',
        params: {
          'p_user_ids': userIds,
          'p_title': title,
          'p_message': message,
          'p_target': _dbTargetValue(target),
          'p_sent_by': sentBy,
          'p_status': 'scheduled',
          'p_scheduled_at': scheduledTime.toIso8601String(),
        },
      );

      await loadNotifications();
      Get.snackbar('نجح', 'تم جدولة الإشعار بنجاح');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'NotificationController',
        method: 'scheduleNotification',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل جدولة الإشعار');
    }
  }
}
