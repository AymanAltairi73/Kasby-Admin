import 'package:get/get.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  final sentNotifications = <NotificationModel>[].obs;

  void sendNotification(String title, String message, String target) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      target: target,
      sentAt: DateTime.now(),
      status: 'Sent',
    );
    sentNotifications.insert(0, notification);
  }

  void scheduleNotification(
    String title,
    String message,
    String target,
    DateTime scheduledTime,
  ) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      target: target,
      sentAt: scheduledTime,
      status: 'Scheduled',
    );
    sentNotifications.insert(0, notification);
  }
}
