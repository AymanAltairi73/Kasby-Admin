import 'package:flutter/material.dart';

enum AuditLogType { security, financial, userManagement, investment, system }

class AuditLog {
  final String id;
  final String action;
  final String adminName;
  final DateTime timestamp;
  final String details;
  final AuditLogType type;
  final IconData icon;

  AuditLog({
    required this.id,
    required this.action,
    required this.adminName,
    required this.timestamp,
    required this.details,
    required this.type,
    required this.icon,
  });
}
