import 'supabase_service.dart';

/// Audit Logger — logs admin actions to Supabase `audit_logs` table
class AuditLogger {
  static Future<void> log({
    required String action,
    String? details,
    String type = 'admin',
    String status = 'success',
    String? targetId,
    String? targetType,
    String? adminName, // kept for backward compatibility with callers
  }) async {
    try {
      final adminId = SupabaseService.auth.currentUser?.id;

      await SupabaseService.client.from('audit_logs').insert({
        'admin_id': adminId,
        'action': action,
        'details': details,
        'type': type,
        'status': status,
        'target_id': targetId,
        'target_type': targetType,
      });
    } catch (e) {
      // Silently fail — audit logging should not break user flow
    }
  }

  static Future<List<Map<String, dynamic>>> getLogs({int limit = 50}) async {
    try {
      final response = await SupabaseService.client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
