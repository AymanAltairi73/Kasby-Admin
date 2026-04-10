/// No-op Audit Logger — system removed
class AuditLogger {
  static Future<void> log({
    required String action,
    String? details,
    String type = 'admin',
    String status = 'success',
    String? targetId,
    String? targetType,
    String? adminName,
  }) async {
    // System removed
  }

  static Future<List<Map<String, dynamic>>> getLogs({int limit = 50}) async {
    return [];
  }
}
