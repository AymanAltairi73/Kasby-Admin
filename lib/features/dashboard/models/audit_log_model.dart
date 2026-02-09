import 'package:flutter/material.dart';

enum AuditLogType { security, financial, userManagement, investment, system }

enum AuditLogStatus { success, warning, failure }

class AuditLog {
  final String id;
  final String action;
  final String adminName;
  final DateTime timestamp;
  final String details;
  final AuditLogType type;
  final AuditLogStatus status;
  final IconData icon;
  final String? ipAddress;
  final String? device;
  final String? targetId;
  final String? targetType;
  final Map<String, dynamic>? metadata;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] ?? '',
      action: json['action'] ?? '',
      adminName: json['adminName'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      details: json['details'] ?? '',
      type: AuditLogType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AuditLogType.system,
      ),
      status: AuditLogStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => AuditLogStatus.success,
      ),
      icon: Icons.history, // Placeholder as IconData is not easily serializable
      ipAddress: json['ipAddress'],
      device: json['device'],
      targetId: json['targetId'],
      targetType: json['targetType'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'adminName': adminName,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      'type': type.toString(),
      'status': status.toString(),
      'ipAddress': ipAddress,
      'device': device,
      'targetId': targetId,
      'targetType': targetType,
      'metadata': metadata,
    };
  }

  AuditLog({
    required this.id,
    required this.action,
    required this.adminName,
    required this.timestamp,
    required this.details,
    required this.type,
    this.status = AuditLogStatus.success,
    required this.icon,
    this.ipAddress,
    this.device,
    this.targetId,
    this.targetType,
    this.metadata,
  });
}
