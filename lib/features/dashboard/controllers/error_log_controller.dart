import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/error_log_model.dart';
import '../../../core/models/time_filter.dart';

class ErrorLogController extends GetxController {
  final _allLogs = <ErrorLog>[].obs;
  final filteredLogs = <ErrorLog>[].obs;
  final isLoading = false.obs;

  final searchQuery = ''.obs;
  final selectedController = RxnString();
  final selectedTimeFilter = TimeFilter.all.obs;

  List<String> get availableControllers =>
      _allLogs.map((log) => log.controllerName).toSet().toList()..sort();

  @override
  void onInit() {
    super.onInit();
    fetchLogs();

    // Re-apply filters when search, selection or time filter changes
    everAll([
      searchQuery,
      selectedController,
      selectedTimeFilter,
      _allLogs,
    ], (_) => _applyFilters());
  }

  Future<void> fetchLogs() async {
    debugPrint(
      '[ErrorLogController] ▶ Fetching error logs from Unified system...',
    );
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('activity_logs')
          .select()
          .eq('entity_type', 'technical_error')
          .order('created_at', ascending: false)
          .limit(200);

      _allLogs.assignAll(
        (response as List).map((json) => ErrorLog.fromJson(json)).toList(),
      );
      debugPrint('[ErrorLogController] ✓ Loaded ${_allLogs.length} logs');
    } catch (e, stackTrace) {
      debugPrint('[ErrorLogController] ✗ FETCH ERROR: $e');
      debugPrint('[ErrorLogController] StackTrace: $stackTrace');
      Get.snackbar('خطأ', 'فشل تحميل سجلات الأخطاء');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    var result = _allLogs.toList();

    // Time Filter
    if (selectedTimeFilter.value != TimeFilter.all) {
      final now = DateTime.now();
      result = result.where((log) {
        final diff = now.difference(log.createdAt);
        switch (selectedTimeFilter.value) {
          case TimeFilter.daily:
            return diff.inDays == 0 && log.createdAt.day == now.day;
          case TimeFilter.weekly:
            return diff.inDays <= 7;
          case TimeFilter.monthly:
            return diff.inDays <= 30;
          default:
            return true;
        }
      }).toList();
    }

    // Controller Filter
    if (selectedController.value != null) {
      result = result
          .where((log) => log.controllerName == selectedController.value)
          .toList();
    }

    // Search Query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result
          .where(
            (log) =>
                log.errorMessage.toLowerCase().contains(query) ||
                log.controllerName.toLowerCase().contains(query) ||
                log.methodName.toLowerCase().contains(query),
          )
          .toList();
    }

    filteredLogs.assignAll(result);
  }

  Future<void> purgeLogs() async {
    debugPrint('[ErrorLogController] ▶ Purging old logs...');
    try {
      isLoading.value = true;
      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String();
      await SupabaseService.client
          .from('activity_logs')
          .delete()
          .eq('entity_type', 'technical_error')
          .lt('created_at', thirtyDaysAgo);

      await fetchLogs();
      debugPrint('[ErrorLogController] ✓ Purge complete');
      Get.snackbar('نجاح', 'تم تنظيف السجلات القديمة');
    } catch (e, stackTrace) {
      debugPrint('[ErrorLogController] ✗ PURGE ERROR: $e');
      debugPrint('[ErrorLogController] StackTrace: $stackTrace');
      Get.snackbar('خطأ', 'فشل في تنظيف السجلات');
    } finally {
      isLoading.value = false;
    }
  }
}
