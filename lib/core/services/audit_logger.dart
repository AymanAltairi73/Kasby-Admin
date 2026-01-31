import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Audit Log Entry Model
class AuditEntry {
  final String adminName;
  final String action;
  final String details;
  final DateTime timestamp;

  AuditEntry({
    required this.adminName,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'adminName': adminName,
    'action': action,
    'details': details,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    adminName: json['adminName'],
    action: json['action'],
    details: json['details'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

/// Audit Logger Service
/// Logs sensitive administrative actions to local storage (mock for production DB)
class AuditLogger {
  static const String _storageKey = 'audit_logs';

  /// Log an action
  static Future<void> log({
    required String adminName,
    required String action,
    required String details,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = AuditEntry(
      adminName: adminName,
      action: action,
      details: details,
      timestamp: DateTime.now(),
    );

    final List<String> logs = prefs.getStringList(_storageKey) ?? [];
    logs.add(jsonEncode(entry.toJson()));

    // Keep only last 1000 logs for local storage efficiency
    if (logs.length > 1000) {
      logs.removeAt(0);
    }

    await prefs.setStringList(_storageKey, logs);
    // Use debugPrint instead of print for production apps
    // debugPrint('Audit Log: [$action] by $adminName - $details');
  }

  /// Get all logs
  static Future<List<AuditEntry>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> logs = prefs.getStringList(_storageKey) ?? [];
    return logs
        .map((l) => AuditEntry.fromJson(jsonDecode(l)))
        .toList()
        .reversed
        .toList();
  }
}
