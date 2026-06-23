import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

class AuditLogEntry {
  final String id;
  final String? actorId;
  final String? actorRole;
  final String action;
  final String? entityType;
  final String? entityId;
  final String severity;
  final Map<String, dynamic>? details;
  final DateTime createdAt;
  final String? actorName;

  AuditLogEntry({
    required this.id,
    this.actorId,
    this.actorRole,
    required this.action,
    this.entityType,
    this.entityId,
    required this.severity,
    this.details,
    required this.createdAt,
    this.actorName,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    final profiles = map['profiles'];
    String? name;
    if (profiles is Map) {
      name = profiles['full_name'] as String?;
    }

    return AuditLogEntry(
      id: (map['id'] ?? '').toString(),
      actorId: map['actor_id'] as String?,
      actorRole: map['actor_role'] as String?,
      action: map['action'] as String? ?? '',
      entityType: map['entity_type'] as String?,
      entityId: map['entity_id'] as String?,
      severity: map['severity'] as String? ?? 'info',
      details: map['details'] is Map<String, dynamic>
          ? map['details'] as Map<String, dynamic>
          : null,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      actorName: name,
    );
  }
}

class AuditLogController extends GetxController {
  static const int _pageSize = 50;

  final logs = <AuditLogEntry>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;

  final searchQuery = ''.obs;
  final selectedAction = ''.obs;
  final dateFrom = Rxn<DateTime>();
  final dateTo = Rxn<DateTime>();

  final searchController = TextEditingController();

  final actionTypes = <String>[
    'admin_block_user',
    'admin_unblock_user',
    'admin_delete_user',
    'admin_add_balance',
    'admin_deduct_balance',
    'admin_verify_kyc',
    'admin_reject_kyc',
    'admin_approve_deposit',
    'admin_approve_withdrawal',
    'admin_reject_transaction',
    'admin_approve_loan',
    'admin_reject_loan',
    'admin_record_loan_repayment',
    'admin_approve_investment',
    'admin_reject_investment',
    'admin_approve_agent',
    'admin_reject_agent',
    'admin_toggle_system_control',
    'error',
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadLogs();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadLogs() async {
    AppLoggerService.debugTrace(
      className: 'AuditLogController',
      method: 'loadLogs',
      feature: 'Audit',
      status: 'INFO',
    );
    isLoading.value = true;
    hasMore.value = true;
    try {
      final data = await _fetchPage(0);
      logs.assignAll(data);
      if (data.length < _pageSize) hasMore.value = false;
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'AuditLogController',
        method: 'loadLogs',
        feature: 'Audit',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل في تحميل سجل العمليات',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final data = await _fetchPage(logs.length);
      if (data.isEmpty) {
        hasMore.value = false;
      } else {
        logs.addAll(data);
        if (data.length < _pageSize) hasMore.value = false;
      }
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuditLogController',
        method: 'loadMore',
        feature: 'Audit',
        status: 'FAILED',
        error: e,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<List<AuditLogEntry>> _fetchPage(int offset) async {
    var query = SupabaseService.client
        .from('system_logs')
        .select('''
          *,
          profiles:actor_id(full_name)
        ''');

    if (searchQuery.value.isNotEmpty) {
      query = query.ilike('action', '%${searchQuery.value}%');
    }
    if (selectedAction.value.isNotEmpty) {
      query = query.eq('action', selectedAction.value);
    }
    if (dateFrom.value != null) {
      query = query.gte('created_at', dateFrom.value!.toIso8601String());
    }
    if (dateTo.value != null) {
      final endOfDay = DateTime(
        dateTo.value!.year,
        dateTo.value!.month,
        dateTo.value!.day,
        23, 59, 59,
      );
      query = query.lte('created_at', endOfDay.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + _pageSize - 1);

    return (response as List)
        .map((e) => AuditLogEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  void applySearch(String query) {
    searchQuery.value = query;
    loadLogs();
  }

  void setActionFilter(String action) {
    selectedAction.value = action;
    loadLogs();
  }

  void clearActionFilter() {
    selectedAction.value = '';
    loadLogs();
  }

  Future<void> pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: dateFrom.value != null && dateTo.value != null
          ? DateTimeRange(start: dateFrom.value!, end: dateTo.value!)
          : null,
    );
    if (picked != null) {
      dateFrom.value = picked.start;
      dateTo.value = picked.end;
      loadLogs();
    }
  }

  void clearDateRange() {
    dateFrom.value = null;
    dateTo.value = null;
    loadLogs();
  }

  void clearAllFilters() {
    searchQuery.value = '';
    selectedAction.value = '';
    dateFrom.value = null;
    dateTo.value = null;
    searchController.clear();
    loadLogs();
  }
}
