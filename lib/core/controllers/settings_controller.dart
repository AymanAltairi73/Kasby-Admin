import 'package:get/get.dart';
import '../../core/services/audit_logger.dart';

/// Settings Controller
/// Manages system-wide emergency controls and settings
class SettingsController extends GetxController {
  // Emergency Controls
  final pauseWithdrawals = false.obs;
  final pauseProfits = false.obs;
  final systemFreeze = false.obs;

  final isLoading = false.obs;

  /// Toggle emergency control
  Future<void> toggleControl(String controlKey) async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));

    String action = '';
    bool newValue = false;

    switch (controlKey) {
      case 'withdrawals':
        pauseWithdrawals.value = !pauseWithdrawals.value;
        newValue = pauseWithdrawals.value;
        action = newValue ? 'إيقاف السحب' : 'استئناف السحب';
        break;
      case 'profits':
        pauseProfits.value = !pauseProfits.value;
        newValue = pauseProfits.value;
        action = newValue ? 'إيقاف توزيع الأرباح' : 'استئناف توزيع الأرباح';
        break;
      case 'freeze':
        systemFreeze.value = !systemFreeze.value;
        newValue = systemFreeze.value;
        action = newValue ? 'تجميد النظام' : 'إلغاء تجميد النظام';
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
