import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';

class AdminStaffMember {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final DateTime? createdAt;

  AdminStaffMember({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.createdAt,
  });

  factory AdminStaffMember.fromJson(Map<String, dynamic> json) {
    return AdminStaffMember(
      id: json['id'] ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] as String?,
      role: json['role'] ?? 'viewer',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class StaffController extends GetxController {
  final staffMembers = <AdminStaffMember>[].obs;
  final isLoading = false.obs;

  static const List<String> adminRoles = [
    'superadmin',
    'admin',
    'viewer',
    'finance_ops',
    'support',
  ];

  static const Map<String, String> roleLabels = {
    'superadmin': 'مدير عام',
    'admin': 'مدير',
    'viewer': 'مشاهد',
    'finance_ops': 'عمليات مالية',
    'support': 'دعم فني',
  };

  static const Map<String, Map<String, bool>> permissionMatrix = {
    'superadmin': {
      'manage_staff': true,
      'manage_settings': true,
      'manage_users': true,
      'approve_financials': true,
      'view_reports': true,
      'manage_chat': true,
    },
    'admin': {
      'manage_staff': false,
      'manage_settings': true,
      'manage_users': true,
      'approve_financials': true,
      'view_reports': true,
      'manage_chat': true,
    },
    'finance_ops': {
      'manage_staff': false,
      'manage_settings': false,
      'manage_users': false,
      'approve_financials': true,
      'view_reports': true,
      'manage_chat': false,
    },
    'support': {
      'manage_staff': false,
      'manage_settings': false,
      'manage_users': true,
      'approve_financials': false,
      'view_reports': false,
      'manage_chat': true,
    },
    'viewer': {
      'manage_staff': false,
      'manage_settings': false,
      'manage_users': false,
      'approve_financials': false,
      'view_reports': true,
      'manage_chat': false,
    },
  };

  static const Map<String, String> permissionLabels = {
    'manage_staff': 'إدارة الموظفين',
    'manage_settings': 'إدارة الإعدادات',
    'manage_users': 'إدارة المستخدمين',
    'approve_financials': 'الموافقة المالية',
    'view_reports': 'عرض التقارير',
    'manage_chat': 'إدارة المحادثات',
  };

  @override
  void onInit() {
    super.onInit();
    loadStaff();
  }

  Future<void> loadStaff() async {
    AppLoggerService.debugTrace(
      className: 'StaffController',
      method: 'loadStaff',
      feature: 'Staff',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final data = await SupabaseService.client
          .from('admin_profiles')
          .select()
          .inFilter('role', adminRoles)
          .order('created_at', ascending: false);

      staffMembers.assignAll(
        (data as List).map((e) => AdminStaffMember.fromJson(e)).toList(),
      );

      AppLoggerService.debugTrace(
        className: 'StaffController',
        method: 'loadStaff',
        feature: 'Staff',
        status: 'SUCCESS',
        params: {'count': staffMembers.length},
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'StaffController',
        method: 'loadStaff',
        feature: 'Staff',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateRole(String userId, String newRole) async {
    final permService = Get.find<PermissionService>();
    if (permService.adminPrivilege.value != 'superadmin') {
      Get.snackbar(
        'غير مسموح',
        'فقط المدير العام يمكنه تعديل الصلاحيات',
        backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );
      return;
    }

    final currentUserId = SupabaseService.auth.currentUser?.id;
    if (userId == currentUserId) {
      Get.snackbar(
        'غير مسموح',
        'لا يمكنك تغيير صلاحيتك بنفسك',
        backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );
      return;
    }

    try {
      await SupabaseService.client
          .from('admin_profiles')
          .update({'role': newRole})
          .eq('id', userId);

      final index = staffMembers.indexWhere((s) => s.id == userId);
      if (index != -1) {
        final old = staffMembers[index];
        staffMembers[index] = AdminStaffMember(
          id: old.id,
          name: old.name,
          email: old.email,
          phone: old.phone,
          role: newRole,
          avatarUrl: old.avatarUrl,
          createdAt: old.createdAt,
        );
        staffMembers.refresh();
      }

      Get.snackbar(
        'تم التحديث',
        'تم تغيير الصلاحية بنجاح',
        backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );

      AppLoggerService.debugTrace(
        className: 'StaffController',
        method: 'updateRole',
        feature: 'Staff',
        status: 'SUCCESS',
        params: {'userId': userId, 'newRole': newRole},
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'StaffController',
        method: 'updateRole',
        feature: 'Staff',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل تحديث الصلاحية');
    }
  }

  Future<void> removeAdmin(String userId) async {
    final permService = Get.find<PermissionService>();
    if (permService.adminPrivilege.value != 'superadmin') {
      Get.snackbar(
        'غير مسموح',
        'فقط المدير العام يمكنه إزالة المسؤولين',
        backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );
      return;
    }

    final currentUserId = SupabaseService.auth.currentUser?.id;
    if (userId == currentUserId) {
      Get.snackbar(
        'غير مسموح',
        'لا يمكنك إزالة نفسك',
        backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );
      return;
    }

    try {
      await SupabaseService.client
          .from('admin_profiles')
          .update({'role': 'user'})
          .eq('id', userId);

      staffMembers.removeWhere((s) => s.id == userId);
      staffMembers.refresh();

      Get.snackbar(
        'تم الإزالة',
        'تم إزالة صلاحيات المسؤول',
        backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );

      AppLoggerService.debugTrace(
        className: 'StaffController',
        method: 'removeAdmin',
        feature: 'Staff',
        status: 'SUCCESS',
        params: {'userId': userId},
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'StaffController',
        method: 'removeAdmin',
        feature: 'Staff',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل إزالة المسؤول');
    }
  }

  Future<void> inviteAdmin(String identifier) async {
    final permService = Get.find<PermissionService>();
    if (permService.adminPrivilege.value != 'superadmin') {
      Get.snackbar(
        'غير مسموح',
        'فقط المدير العام يمكنه إضافة مسؤولين',
        backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );
      return;
    }

    try {
      final results = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, email, phone')
          .or('email.eq.$identifier,phone.eq.$identifier')
          .limit(1);

      if ((results as List).isEmpty) {
        Get.snackbar('غير موجود', 'لم يتم العثور على المستخدم');
        return;
      }

      final user = results.first;
      final userId = user['id'] as String;

      final existing = await SupabaseService.client
          .from('admin_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing != null) {
        Get.snackbar('موجود مسبقاً', 'هذا المستخدم لديه صلاحيات إدارية بالفعل');
        return;
      }

      await SupabaseService.client.from('admin_profiles').insert({
        'id': userId,
        'name': user['full_name'] ?? user['email'] ?? '',
        'email': user['email'] ?? '',
        'phone': user['phone'],
        'role': 'viewer',
      });

      await loadStaff();

      Get.snackbar(
        'تمت الإضافة',
        'تم إضافة المسؤول بصلاحية مشاهد',
        backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );

      AppLoggerService.debugTrace(
        className: 'StaffController',
        method: 'inviteAdmin',
        feature: 'Staff',
        status: 'SUCCESS',
        params: {'identifier': identifier},
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'StaffController',
        method: 'inviteAdmin',
        feature: 'Staff',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل إضافة المسؤول');
    }
  }
}
