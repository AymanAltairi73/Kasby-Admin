import 'dart:convert';

class ErrorLog {
  final String id;
  final String? userId;
  final String controllerName;
  final String methodName;
  final String errorMessage;
  final String? stackTrace;
  final Map<String, dynamic>? deviceInfo;
  final String appVersion;
  final DateTime createdAt;

  ErrorLog({
    required this.id,
    this.userId,
    required this.controllerName,
    required this.methodName,
    required this.errorMessage,
    this.stackTrace,
    this.deviceInfo,
    required this.appVersion,
    required this.createdAt,
  });

  factory ErrorLog.fromJson(Map<String, dynamic> json) {
    return ErrorLog(
      id: json['id'] ?? '',
      userId: json['user_id'],
      controllerName: json['controller_name'] ?? 'Unknown',
      methodName: json['method_name'] ?? 'Unknown',
      errorMessage: json['error_message'] ?? '',
      stackTrace: json['stack_trace'],
      deviceInfo: _parseDeviceInfo(json['device_info']),
      appVersion: json['app_version'] ?? '1.0.0',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  static Map<String, dynamic>? _parseDeviceInfo(dynamic info) {
    if (info == null) return null;
    if (info is Map<String, dynamic>) return info;
    if (info is String) {
      try {
        return json.decode(info) as Map<String, dynamic>;
      } catch (_) {
        return {'raw': info};
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'controller_name': controllerName,
      'method_name': methodName,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'device_info': deviceInfo,
      'app_version': appVersion,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get a readable summary of device info
  String get deviceSummary {
    if (deviceInfo == null) return 'Unknown Device';
    final platform = deviceInfo!['platform'] ?? 'Unknown';
    final model = deviceInfo!['model'] ?? '';
    final version = deviceInfo!['version'] ?? '';
    return '$platform ${model.isNotEmpty ? "($model)" : ""} ${version.isNotEmpty ? "v$version" : ""}';
  }
}
