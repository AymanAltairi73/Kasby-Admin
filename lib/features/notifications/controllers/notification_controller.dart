import 'package:get/get.dart';

class NotificationController extends GetxController {
  final sentNotifications = <Map<String, dynamic>>[].obs;

  void sendNotification(String title, String message, String target) {
    sentNotifications.insert(0, {
      'title': title,
      'message': message,
      'target': target,
      'sentAt': DateTime.now(),
      'status': 'Sent',
    });
  }

  void scheduleNotification(
    String title,
    String message,
    String target,
    DateTime scheduledTime,
  ) {
    sentNotifications.insert(0, {
      'title': title,
      'message': message,
      'target': target,
      'sentAt': scheduledTime,
      'status': 'Scheduled',
    });
  }
}
