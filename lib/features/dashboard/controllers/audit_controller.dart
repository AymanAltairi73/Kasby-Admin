import 'package:get/get.dart';

import '../models/audit_log_model.dart';
import '../../../core/models/time_filter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

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
    try {
      final response = await SupabaseService.client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(200);

      _allLogs.assignAll(
        (response as List).map((json) => AuditLog.fromJson(json)).toList(),
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuditController',
        method: 'fetchLogs',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل تحميل سجل العمليات');
    } finally {
      isLoading.value = false;
    }
  }
}
