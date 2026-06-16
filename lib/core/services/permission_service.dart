import 'package:get/get.dart';
import '../services/app_logger_service.dart';
import '../services/supabase_service.dart';

/// RBAC helper — reads `admin_profiles.role` for granular admin permissions.
class PermissionService extends GetxService {
  final adminPrivilege = 'superadmin'.obs;

  static PermissionService get to => Get.find<PermissionService>();

  Future<PermissionService> init() async {
    AppLoggerService.debugTrace(
      className: 'PermissionService',
      method: 'init',
      feature: 'Core',
      status: 'INFO',
    );
    await refreshPrivileges();
    return this;
  }

  Future<void> refreshPrivileges() async {
    AppLoggerService.debugTrace(
      className: 'PermissionService',
      method: 'refreshPrivileges',
      feature: 'Core',
      status: 'INFO',
    );
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) {
      adminPrivilege.value = 'viewer';
      AppLoggerService.debugTrace(
        className: 'PermissionService',
        method: 'refreshPrivileges',
        feature: 'Core',
        status: 'WARNING',
        message: 'No authenticated user — defaulting to viewer',
      );
      return;
    }

    try {
      final row = await SupabaseService.client
          .from('admin_profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final role = row?['role'] as String?;
      adminPrivilege.value = role ?? 'admin';
      AppLoggerService.debugTrace(
        className: 'PermissionService',
        method: 'refreshPrivileges',
        feature: 'Core',
        status: 'SUCCESS',
        params: {'role': adminPrivilege.value},
      );
    } catch (e) {
      adminPrivilege.value = 'admin';
      AppLoggerService.debugTrace(
        className: 'PermissionService',
        method: 'refreshPrivileges',
        feature: 'Core',
        status: 'FAILED',
        error: e,
        message: 'Fallback to admin role',
      );
    }
  }

  bool get isSuperAdmin =>
      adminPrivilege.value == 'superadmin' || adminPrivilege.value == 'admin';

  bool get isViewer => adminPrivilege.value == 'viewer';

  bool get canManageUsers => isSuperAdmin;

  bool get canAdjustBalance => isSuperAdmin;

  bool get canDeleteUsers => isSuperAdmin;

  bool get canManageSettings => !isViewer;

  bool get canApproveFinancials => !isViewer;

  void requirePermission(bool allowed, {String message = 'صلاحيات غير كافية'}) {
    if (!allowed) {
      AppLoggerService.debugTrace(
        className: 'PermissionService',
        method: 'requirePermission',
        feature: 'Core',
        status: 'FAILED',
        message: message,
      );
      throw Exception(message);
    }
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'PermissionService',
      method: 'onClose',
      feature: 'Core',
      status: 'INFO',
    );
    super.onClose();
  }
}
