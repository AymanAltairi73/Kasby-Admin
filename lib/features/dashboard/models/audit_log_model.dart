class AuditLog {
  final String id;
  final String action;
  final String adminName;
  final DateTime timestamp;
  final String details;
  final String severity; // info, warning, critical
  final String? actorRole; // admin, agent, user
  final String? entityType;
  final String? entityId;
  final String? ipAddress;
  final Map<String, dynamic>? metadata;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    // Handle JOIN from profiles
    final profile = json['profiles'] as Map<String, dynamic>?;
    final detailsRaw = json['details'];
    final Map<String, dynamic> detailsMap = detailsRaw is Map
        ? Map<String, dynamic>.from(detailsRaw)
        : <String, dynamic>{};

    return AuditLog(
      id: json['id'] ?? '',
      action: json['action'] ?? '',
      adminName: profile?['full_name'] ?? json['adminName'] ?? 'نظام',
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['timestamp'] != null
                ? DateTime.parse(json['timestamp'])
                : DateTime.now()),
      details: json['action'].toString().startsWith('ERROR')
          ? (detailsMap['error'] ?? json['details'] ?? '')
          : (json['details']?.toString() ?? ''),
      severity: json['severity'] ?? 'info',
      actorRole: json['actor_role'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      ipAddress: json['ip_address'],
      metadata: detailsMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'adminName': adminName,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      'severity': severity,
      'actor_role': actorRole,
      'entity_type': entityType,
      'entity_id': entityId,
      'ip_address': ipAddress,
      'metadata': metadata,
    };
  }

  AuditLog({
    required this.id,
    required this.action,
    required this.adminName,
    required this.timestamp,
    required this.details,
    this.severity = 'info',
    this.actorRole,
    this.entityType,
    this.entityId,
    this.ipAddress,
    this.metadata,
  });
}
