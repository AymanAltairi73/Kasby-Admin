/// Notification Model
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String target; // e.g., "All Users", "Specific User ID", "Agents"
  final String type; // e.g., "financial", "system", "notification"
  final String? targetUserId;
  final DateTime sentAt;
  final String status; // Sent, Scheduled, Failed

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.target,
    this.type = 'notification',
    this.targetUserId,
    required this.sentAt,
    required this.status,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      target: json['target'] ?? 'All',
      type: json['type'] ?? 'notification',
      targetUserId: json['target_user_id'] ?? json['targetUserId'],
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      status: json['status'] ?? 'Sent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'target': target,
      'type': type,
      'target_user_id': targetUserId,
      'sentAt': sentAt.toIso8601String(),
      'status': status,
    };
  }
}
