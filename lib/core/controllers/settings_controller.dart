import 'package:get/get.dart';
import '../../core/services/audit_logger.dart';
import '../models/system_settings_model.dart';

/// Settings Controller
/// Manages system-wide emergency controls and settings
class SettingsController extends GetxController {
  final settings = SystemSettings(
    pauseWithdrawals: false,
    pauseProfits: false,
    systemFreeze: false,
    updatedAt: DateTime.now(),
    updatedBy: 'Admin',
  ).obs;

  final isLoading = false.obs;

  bool get pauseWithdrawals => settings.value.pauseWithdrawals;
  bool get pauseProfits => settings.value.pauseProfits;
  bool get systemFreeze => settings.value.systemFreeze;

  /// Toggle emergency control
  Future<void> toggleControl(String controlKey) async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));

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
