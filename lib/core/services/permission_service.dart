import 'package:get/get.dart';
import '../services/app_logger_service.dart';
import '../services/supabase_service.dart';

/// RBAC helper — determines admin privilege level from `admin_profiles.role`
/// with fallback to `profiles.role` for admins without an admin_profiles row.
class PermissionService extends GetxService {
  final adminPrivilege = 'viewer'.obs;

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

      if (row != null && row['role'] != null) {
        adminPrivilege.value = row['role'] as String;
        AppLoggerService.debugTrace(
          className: 'PermissionService',
          method: 'refreshPrivileges',
          feature: 'Core',
          status: 'SUCCESS',
          params: {'source': 'admin_profiles', 'role': adminPrivilege.value},
        );
        return;
      }

      final profileRow = await SupabaseService.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final profileRole = profileRow?['role'] as String?;
      if (profileRole == 'admin') {
        adminPrivilege.value = 'admin';
        AppLoggerService.debugTrace(
          className: 'PermissionService',
          method: 'refreshPrivileges',
          feature: 'Core',
          status: 'SUCCESS',
          params: {'source': 'profiles', 'role': 'admin'},
        );
      } else {
        adminPrivilege.value = 'viewer';
        AppLoggerService.debugTrace(
          className: 'PermissionService',
          method: 'refreshPrivileges',
          feature: 'Core',
          status: 'WARNING',
          params: {'profileRole': profileRole ?? 'null'},
          message: 'User is not an admin — viewer',
        );
      }
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
