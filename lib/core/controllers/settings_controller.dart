import 'package:get/get.dart';
import '../../core/services/audit_logger.dart';
import '../../core/services/supabase_service.dart';
import '../models/system_settings_model.dart';

/// Settings Controller
/// Manages system-wide emergency controls from Supabase `system_settings` table
/// (Single Source of Truth — no local storage)
class SettingsController extends GetxController {
  final settings = SystemSettings(
    pauseWithdrawals: false,
    pauseProfits: false,
    systemFreeze: false,
    updatedAt: DateTime.now(),
    updatedBy: 'Admin',
  ).obs;

  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Load settings from Supabase `system_settings` table
  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('system_settings')
          .select()
          .eq('id', 'global')
          .maybeSingle();

      if (response != null) {
        settings.value = SystemSettings(
          pauseWithdrawals: response['pause_withdrawals'] ?? false,
          pauseProfits: response['pause_profits'] ?? false,
          systemFreeze: response['system_freeze'] ?? false,
          updatedAt:
              DateTime.tryParse(response['updated_at'] ?? '') ?? DateTime.now(),
          updatedBy: response['updated_by'] ?? 'Admin',
        );
      } else {
        // Create initial row if not exists
        await _createInitialSettings();
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل إعدادات النظام: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  /// Create initial settings row in Supabase
  Future<void> _createInitialSettings() async {
    try {
      await SupabaseService.client.from('system_settings').insert({
        'id': 'global',
        'pause_withdrawals': false,
        'pause_profits': false,
        'system_freeze': false,
        'updated_by': 'System',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Row may already exist, ignore
    }
  }

  /// Save settings to Supabase
  Future<void> _saveSettings() async {
    try {
      final adminId = SupabaseService.auth.currentUser?.id ?? 'Admin';
      await SupabaseService.client
          .from('system_settings')
          .update({
            'pause_withdrawals': settings.value.pauseWithdrawals,
            'pause_profits': settings.value.pauseProfits,
            'system_freeze': settings.value.systemFreeze,
            'updated_by': adminId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', 'global');
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حفظ الإعدادات: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool get pauseWithdrawals => settings.value.pauseWithdrawals;
  bool get pauseProfits => settings.value.pauseProfits;
  bool get systemFreeze => settings.value.systemFreeze;

  /// Toggle emergency control
  Future<void> toggleControl(String controlKey) async {
    isLoading.value = true;

    String action = '';
    SystemSettings current = settings.value;

    switch (controlKey) {
      case 'withdrawals':
        settings.value = current.copyWith(
          pauseWithdrawals: !current.pauseWithdrawals,
          updatedAt: DateTime.now(),
        );
        action = settings.value.pauseWithdrawals
            ? 'إيقاف السحب'
            : 'استئناف السحب';
        break;
      case 'profits':
        settings.value = current.copyWith(
          pauseProfits: !current.pauseProfits,
          updatedAt: DateTime.now(),
        );
        action = settings.value.pauseProfits
            ? 'إيقاف توزيع الأرباح'
            : 'استئناف توزيع الأرباح';
        break;
      case 'freeze':
        settings.value = current.copyWith(
          systemFreeze: !current.systemFreeze,
          updatedAt: DateTime.now(),
        );
        action = settings.value.systemFreeze
            ? 'تجميد النظام'
            : 'إلغاء تجميد النظام';
        break;
    }

    await _saveSettings();

    await AuditLogger.log(
      adminName: 'SuperAdmin',
      action: 'تغيير حالة النظام',
      details: 'تم إجراء $action بنجاح.',
    );

    isLoading.value = false;
    Get.snackbar(
      'تنبيه النظام',
      'تم $action بنجاح',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
