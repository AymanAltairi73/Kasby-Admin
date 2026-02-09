/// Notification Model
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String target; // e.g., "All Users", "Specific User ID", "Agents"
  final DateTime sentAt;
  final String status; // Sent, Scheduled, Failed

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.target,
    required this.sentAt,
    required this.status,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      target: json['target'] ?? 'All',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      status: json['status'] ?? 'Sent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'target': target,
      'sentAt': sentAt.toIso8601String(),
      'status': status,
    };
  }
}
