import 'package:flutter/material.dart';
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
  final selectedTimeFilter = TimeFilter.all.obs;
  final selectedRoleFilter = 'الكل'.obs; // admin, agent, user, system (null)
  final selectedSeverityFilter = 'الكل'.obs; // info, warning, critical

  @override
  void onInit() {
    super.onInit();
    fetchLogs();

    // Set up filtering listeners
    everAll([
      searchQuery,
      selectedTimeFilter,
      selectedRoleFilter,
      selectedSeverityFilter,
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

    // Role-based filtering
    if (selectedRoleFilter.value != 'الكل') {
      result = result.where((log) {
        if (selectedRoleFilter.value == 'نظام') return log.actorRole == null;
        final roleMap = {'مشرف': 'admin', 'وكيل': 'agent', 'مستخدم': 'user'};
        return log.actorRole == roleMap[selectedRoleFilter.value];
      }).toList();
    }

    // Severity-based filtering
    if (selectedSeverityFilter.value != 'الكل') {
      result = result.where((log) {
        final severityMap = {
          'معلومات': 'info',
          'تحذير': 'warning',
          'خطير': 'critical',
        };
        return log.severity == severityMap[selectedSeverityFilter.value];
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where(
            (log) =>
                log.action.toLowerCase().contains(q) ||
                log.adminName.toLowerCase().contains(q) ||
                log.details.toLowerCase().contains(q),
          )
          .toList();
    }

    logs.value = result;
  }

  Future<void> fetchLogs() async {
    debugPrint(
      '[AuditController] ▶ Fetching Activity logs from unified table...',
    );
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('activity_logs')
          .select('*, profiles:actor_id(full_name)')
          .order('created_at', ascending: false)
          .limit(200);

      _allLogs.assignAll(
        (response as List).map((json) => AuditLog.fromJson(json)).toList(),
      );
      debugPrint('[AuditController] ✓ Loaded ${_allLogs.length} activity logs');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuditController',
        method: 'fetchLogs',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل تحميل سجل النشاط الموحد');
    } finally {
      isLoading.value = false;
    }
  }
}
