import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/audit_log_model.dart';
import '../../../core/models/time_filter.dart';

class AuditController extends GetxController {
  final _allLogs = <AuditLog>[].obs;
  final logs = <AuditLog>[].obs;
  final isLoading = false.obs;

  final searchQuery = ''.obs;
  final selectedType = Rxn<AuditLogType>();
  final selectedStatus = Rxn<AuditLogStatus>();
  final selectedTimeFilter = TimeFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLogs();

    // Set up filtering listeners
    everAll([
      searchQuery,
      selectedType,
      selectedStatus,
      selectedTimeFilter,
      _allLogs,
    ], (_) => _applyFilters());
  }

  void _applyFilters() {
    var result = _allLogs.toList();

    // Time-based filtering
    final now = DateTime.now();
    if (selectedTimeFilter.value != TimeFilter.all) {
      result = result.where((log) {
        final difference = now.difference(log.timestamp);
        switch (selectedTimeFilter.value) {
          case TimeFilter.daily:
            return difference.inDays == 0 && log.timestamp.day == now.day;
          case TimeFilter.weekly:
            return difference.inDays <= 7;
          case TimeFilter.monthly:
            return difference.inDays <= 30;
          default:
            return true;
        }
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      result = result
          .where(
            (log) =>
                log.action.contains(searchQuery.value) ||
                log.adminName.contains(searchQuery.value) ||
                log.details.contains(searchQuery.value),
          )
          .toList();
    }

    if (selectedType.value != null) {
      result = result.where((log) => log.type == selectedType.value).toList();
    }

    if (selectedStatus.value != null) {
      result = result
          .where((log) => log.status == selectedStatus.value)
          .toList();
    }

    logs.value = result;
  }

  Future<void> fetchLogs() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    _allLogs.value = [
      AuditLog(
        id: '1',
        action: 'موافقة على عملية سحب',
        adminName: 'أحمد علي (المدير العام)',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        details: 'تمت الموافقة على سحب مبلغ \$500.00 للمستخدم محمد حسن',
        type: AuditLogType.financial,
        status: AuditLogStatus.success,
        icon: FontAwesomeIcons.moneyBillTransfer,
        ipAddress: '192.168.1.45',
        device: 'macOS Monterey (Chrome)',
        targetId: 'TXN_99283',
        targetType: 'Transaction',
        metadata: {'amount': 500.0, 'currency': 'USD', 'user_id': 'USR_552'},
      ),
      AuditLog(
        id: '2',
        action: 'حظر مستخدم',
        adminName: 'سارة خالد',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        details: 'تم حظر المستخدم خالد محمود بسبب نشاط مشبوه',
        type: AuditLogType.userManagement,
        status: AuditLogStatus.warning,
        icon: FontAwesomeIcons.userSlash,
        ipAddress: '10.5.0.22',
        device: 'iPhone 15 Pro (App)',
        targetId: 'USR_112',
        targetType: 'User',
        metadata: {'reason': 'Suspicious Activity', 'duration': 'Permanent'},
      ),
      AuditLog(
        id: '6',
        action: 'إضافة وكيل جديد',
        adminName: 'ناصر فهد',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        details: 'تمت إضافة الوكيل "سالم العلي" إلى شبكة الوكلاء في دبي',
        type: AuditLogType.userManagement,
        status: AuditLogStatus.success,
        icon: FontAwesomeIcons.userPlus,
        ipAddress: '45.12.88.9',
        device: 'Windows 11 (Firefox)',
        targetId: 'AGENT_771',
        targetType: 'Agent',
      ),
      AuditLog(
        id: '3',
        action: 'تعديل خطة استثمار',
        adminName: 'أحمد علي (المدير العام)',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        details: 'تحديث العائد السنوي لخطة "النمو الذكي" إلى 12%',
        type: AuditLogType.investment,
        status: AuditLogStatus.success,
        icon: FontAwesomeIcons.chartLine,
        ipAddress: '192.168.1.45',
        device: 'macOS Monterey (Chrome)',
        targetId: 'PLAN_002',
        targetType: 'InvestmentPlan',
        metadata: {'old_rate': 10.5, 'new_rate': 12.0},
      ),
      AuditLog(
        id: '4',
        action: 'فشل تسجيل دخول مسؤول',
        adminName: 'ناصر فهد',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        details: 'محاولة فاشلة لتسجيل الدخول بكلمة مرور خاطئة 3 مرات',
        type: AuditLogType.security,
        status: AuditLogStatus.failure,
        icon: FontAwesomeIcons.shieldHalved,
        ipAddress: '45.12.88.9',
        device: 'Windows 11 (Firefox)',
        metadata: {'attempts': 3, 'location': 'Dubai, UAE'},
      ),
      AuditLog(
        id: '5',
        action: 'إرسال إشعار عام',
        adminName: 'سارة خالد',
        timestamp: DateTime.now().subtract(const Duration(days: 25)),
        details: 'تم إرسال إشعار لجميع المستخدمين بخصوص الصيانة الدورية',
        type: AuditLogType.system,
        status: AuditLogStatus.success,
        icon: FontAwesomeIcons.bullhorn,
        ipAddress: '10.5.0.22',
        device: 'iPhone 15 Pro (App)',
        metadata: {'recipient_count': 12543, 'template_id': 'maint_01'},
      ),
    ];

    isLoading.value = false;
  }
}
