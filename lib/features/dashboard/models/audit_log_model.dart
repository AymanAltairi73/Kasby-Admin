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
