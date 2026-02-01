import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/audit_log_model.dart';

class AuditController extends GetxController {
  final logs = <AuditLog>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    isLoading.value = true;

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data for Masterpiece feel
    logs.value = [
      AuditLog(
        id: '1',
        action: 'موافقة على عملية سحب',
        adminName: 'أحمد علي (المدير العام)',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        details: 'تمت الموافقة على سحب مبلغ \$500.00 للمستخدم محمد حسن',
        type: AuditLogType.financial,
        icon: FontAwesomeIcons.moneyBillTransfer,
      ),
      AuditLog(
        id: '2',
        action: 'حظر مستخدم',
        adminName: 'سارة خالد',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        details: 'تم حظر المستخدم خالد محمود بسبب نشاط مشبوه',
        type: AuditLogType.userManagement,
        icon: FontAwesomeIcons.userSlash,
      ),
      AuditLog(
        id: '3',
        action: 'تعديل خطة استثمار',
        adminName: 'أحمد علي (المدير العام)',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        details: 'تحديث العائد السنوي لخطة "النمو الذكي" إلى 12%',
        type: AuditLogType.investment,
        icon: FontAwesomeIcons.chartLine,
      ),
      AuditLog(
        id: '4',
        action: 'تسجيل دخول مسؤول',
        adminName: 'ناصر فهد',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        details: 'سجل المسؤول ناصر فهد الدخول من جهاز جديد',
        type: AuditLogType.security,
        icon: FontAwesomeIcons.shieldHalved,
      ),
      AuditLog(
        id: '5',
        action: 'إرسال إشعار عام',
        adminName: 'سارة خالد',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        details: 'تم إرسال إشعار لجميع المستخدمين بخصوص الصيانة الدورية',
        type: AuditLogType.system,
        icon: FontAwesomeIcons.bullhorn,
      ),
    ];

    isLoading.value = false;
  }
}
