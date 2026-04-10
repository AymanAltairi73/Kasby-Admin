import 'package:get/get.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/system_repository.dart';
import '../models/system_settings_model.dart';

/// Settings Controller
/// Manages system-wide emergency controls from Supabase `system_settings` table
/// (Single Source of Truth — no local storage)
class SettingsController extends GetxController {
  final SystemRepository _systemRepo = SystemRepository(SupabaseService.client);
  
  final settings = SystemSettings(
    pauseDeposits: false,
    pauseWithdrawals: false,
    pauseProfits: false,
    pauseInvestments: false,
    pauseLoans: false,
    systemFreeze: false,
    isMaintenanceMode: false,
    maintenanceMessage: '',
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
      final response = await _systemRepo.getSettings();

      if (response != null) {
        settings.value = SystemSettings.fromJson(response);
      } else {
        // Create initial row if not exists
        await _createInitialSettings();
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل إعدادات النظام',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  /// Create initial settings row in Supabase
  Future<void> _createInitialSettings() async {
    try {
      final adminId = SupabaseService.auth.currentUser?.id;
      await _systemRepo.createSettings({
        'pause_deposits': false,
        'pause_withdrawals': false,
        'pause_profits': false,
        'pause_investments': false,
        'pause_loans': false,
        'system_freeze': false,
        'is_maintenance_mode': false,
        'maintenance_message': '',
        'updated_by': adminId,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Row may already exist, ignore
    }
  }

  /// Save settings to Supabase
  Future<void> _saveSettings() async {
    try {
      final adminId = SupabaseService.auth.currentUser?.id;
      // Get the settings row ID first
      final existing = await _systemRepo.getSettings();
      if (existing == null) return;

      await _systemRepo.updateSettings(existing['id'], {
        'pause_deposits': settings.value.pauseDeposits,
        'pause_withdrawals': settings.value.pauseWithdrawals,
        'pause_profits': settings.value.pauseProfits,
        'pause_investments': settings.value.pauseInvestments,
        'pause_loans': settings.value.pauseLoans,
        'system_freeze': settings.value.systemFreeze,
        'is_maintenance_mode': settings.value.isMaintenanceMode,
        'maintenance_message': settings.value.maintenanceMessage,
        'updated_by': adminId,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حفظ الإعدادات',
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
      case 'deposits':
        settings.value = current.copyWith(
          pauseDeposits: !current.pauseDeposits,
          updatedAt: DateTime.now(),
        );
        action = settings.value.pauseDeposits
            ? 'إيقاف الإيداع'
            : 'استئناف الإيداع';
        break;
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
      case 'investments':
        settings.value = current.copyWith(
          pauseInvestments: !current.pauseInvestments,
          updatedAt: DateTime.now(),
        );
        action = settings.value.pauseInvestments
            ? 'إيقاف الاستثمارات'
            : 'استئناف الاستثمارات';
        break;
      case 'loans':
        settings.value = current.copyWith(
          pauseLoans: !current.pauseLoans,
          updatedAt: DateTime.now(),
        );
        action = settings.value.pauseLoans ? 'إيقاف القروض' : 'استئناف القروض';
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
      case 'maintenance':
        settings.value = current.copyWith(
          isMaintenanceMode: !current.isMaintenanceMode,
          updatedAt: DateTime.now(),
        );
        action = settings.value.isMaintenanceMode
            ? 'تفعيل الصيانة'
            : 'إيقاف الصيانة';
        break;
    }

    await _saveSettings();

    isLoading.value = false;
    Get.snackbar(
      'تنبيه النظام',
      'تم $action بنجاح',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
