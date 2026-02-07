/// User Activity Model
/// Represents a single action performed by a user
class UserActivity {
  final String id;
  final String action; // e.g., "Login", "Transfer", "Profile Update"
  final String
  details; // e.g., "Logged in from IP 192.168.1.1", "Sent $50 to User B"
  final DateTime timestamp;
  final String type; // e.g., "Security", "Transaction", "System", "Support"

  UserActivity({
    required this.id,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.type,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] ?? '',
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'] ?? 'System',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }
}
