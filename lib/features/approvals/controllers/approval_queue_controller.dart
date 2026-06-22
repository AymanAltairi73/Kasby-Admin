import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

enum ApprovalCategory { all, deposits, withdrawals, kyc, loans, agents }

class ApprovalItem {
  final String id;
  final ApprovalCategory category;
  final String userName;
  final String detail;
  final double? amount;
  final DateTime createdAt;
  final Map<String, dynamic> raw;

  const ApprovalItem({
    required this.id,
    required this.category,
    required this.userName,
    required this.detail,
    this.amount,
    required this.createdAt,
    required this.raw,
  });
}

class ApprovalQueueController extends GetxController {
  final items = <ApprovalItem>[].obs;
  final filteredItems = <ApprovalItem>[].obs;
  final isLoading = false.obs;
  final selectedCategory = ApprovalCategory.all.obs;
  final categoryCounts = <ApprovalCategory, int>{}.obs;

  StreamSubscription? _txnSub;
  StreamSubscription? _kycSub;
  StreamSubscription? _loanSub;
  StreamSubscription? _agentSub;
  Timer? _reloadDebounce;

  @override
  void onInit() {
    super.onInit();
    loadAllPending();
    _startListeners();
  }

  @override
  void onClose() {
    _txnSub?.cancel();
    _kycSub?.cancel();
    _loanSub?.cancel();
    _agentSub?.cancel();
    _reloadDebounce?.cancel();
    super.onClose();
  }

  void _startListeners() {
    void scheduleReload() {
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 800), loadAllPending);
    }

    _txnSub = SupabaseService.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});

    _kycSub = SupabaseService.client
        .from('kyc_documents')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});

    _loanSub = SupabaseService.client
        .from('loans')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});

    _agentSub = SupabaseService.client
        .from('agents')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});
  }

  Future<void> loadAllPending() async {
    AppLoggerService.debugTrace(
      className: 'ApprovalQueueController',
      method: 'loadAllPending',
      feature: 'Approvals',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _fetchPendingDeposits(),
        _fetchPendingWithdrawals(),
        _fetchPendingKYC(),
        _fetchPendingLoans(),
        _fetchPendingAgents(),
      ]);

      final all = <ApprovalItem>[];
      for (final batch in results) {
        all.addAll(batch);
      }
      all.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      items.value = all;
      _updateCounts();
      _applyFilter();

      AppLoggerService.debugTrace(
        className: 'ApprovalQueueController',
        method: 'loadAllPending',
        feature: 'Approvals',
        status: 'SUCCESS',
        params: {'total': all.length},
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'ApprovalQueueController',
        method: 'loadAllPending',
        feature: 'Approvals',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void setCategory(ApprovalCategory cat) {
    selectedCategory.value = cat;
    _applyFilter();
  }

  void _applyFilter() {
    if (selectedCategory.value == ApprovalCategory.all) {
      filteredItems.value = List.from(items);
    } else {
      filteredItems.value =
          items.where((i) => i.category == selectedCategory.value).toList();
    }
  }

  void _updateCounts() {
    final counts = <ApprovalCategory, int>{};
    for (final cat in ApprovalCategory.values) {
      if (cat == ApprovalCategory.all) {
        counts[cat] = items.length;
      } else {
        counts[cat] = items.where((i) => i.category == cat).length;
      }
    }
    categoryCounts.value = counts;
  }

  // ─── FETCH METHODS ─────────────────────────────────────

  Future<List<ApprovalItem>> _fetchPendingDeposits() async {
    try {
      final data = await SupabaseService.client
          .from('transactions')
          .select('id, user_id, amount, reference, created_at, profiles!transactions_user_id_fkey(full_name)')
          .eq('type', 'deposit')
          .eq('status', 'pending')
          .order('created_at');

      return (data as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.deposits,
          userName: profile?['full_name'] ?? 'مستخدم',
          detail: 'مرجع: ${row['reference'] ?? row['id']}',
          amount: (row['amount'] as num?)?.toDouble(),
          createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ApprovalItem>> _fetchPendingWithdrawals() async {
    try {
      final data = await SupabaseService.client
          .from('transactions')
          .select('id, user_id, amount, reference, created_at, profiles!transactions_user_id_fkey(full_name)')
          .eq('type', 'withdrawal')
          .eq('status', 'pending')
          .order('created_at');

      return (data as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.withdrawals,
          userName: profile?['full_name'] ?? 'مستخدم',
          detail: 'مرجع: ${row['reference'] ?? row['id']}',
          amount: (row['amount'] as num?)?.toDouble(),
          createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ApprovalItem>> _fetchPendingKYC() async {
    try {
      final data = await SupabaseService.client
          .from('kyc_documents')
          .select('id, user_id, document_type, created_at, profiles!kyc_documents_user_id_fkey(full_name)')
          .eq('status', 'pending')
          .order('created_at');

      return (data as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.kyc,
          userName: profile?['full_name'] ?? 'مستخدم',
          detail: 'نوع: ${row['document_type'] ?? 'وثيقة'}',
          createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ApprovalItem>> _fetchPendingLoans() async {
    try {
      final data = await SupabaseService.client
          .from('loans')
          .select('id, user_id, amount, status, created_at, profiles!loans_user_id_fkey(full_name)')
          .eq('status', 'pending')
          .order('created_at');

      return (data as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.loans,
          userName: profile?['full_name'] ?? 'مستخدم',
          detail: 'طلب سلفة',
          amount: (row['amount'] as num?)?.toDouble(),
          createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ApprovalItem>> _fetchPendingAgents() async {
    try {
      final data = await SupabaseService.client
          .from('agents')
          .select('id, name, phone, created_at')
          .eq('status', 'pending')
          .order('created_at');

      return (data as List).map((row) {
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.agents,
          userName: row['name'] ?? 'وكيل',
          detail: row['phone'] ?? '',
          createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── ACTIONS ───────────────────────────────────────────

  Future<void> approveItem(ApprovalItem item) async {
    AppLoggerService.debugTrace(
      className: 'ApprovalQueueController',
      method: 'approveItem',
      feature: 'Approvals',
      status: 'INFO',
      params: {'id': item.id, 'category': item.category.name},
    );
    try {
      switch (item.category) {
        case ApprovalCategory.deposits:
          final adminId = SupabaseService.auth.currentUser?.id;
          await SupabaseService.client.rpc('fn_process_deposit', params: {
            'p_txn_id': item.id,
            'p_admin_id': adminId,
          });
          break;
        case ApprovalCategory.withdrawals:
          final adminId = SupabaseService.auth.currentUser?.id;
          await SupabaseService.client.rpc('approve_withdrawal', params: {
            'p_txn_id': item.id,
            'p_admin_id': adminId,
          });
          break;
        case ApprovalCategory.kyc:
          await SupabaseService.client
              .from('kyc_documents')
              .update({'status': 'approved'})
              .eq('id', item.id);
          break;
        case ApprovalCategory.loans:
          await SupabaseService.client
              .from('loans')
              .update({'status': 'approved'})
              .eq('id', item.id);
          break;
        case ApprovalCategory.agents:
          await SupabaseService.client
              .from('agents')
              .update({'status': 'approved'})
              .eq('id', item.id);
          break;
        case ApprovalCategory.all:
          break;
      }

      items.remove(item);
      _updateCounts();
      _applyFilter();

      Get.snackbar('تم', 'تمت الموافقة بنجاح', snackPosition: SnackPosition.BOTTOM);
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'ApprovalQueueController',
        method: 'approveItem',
        feature: 'Approvals',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل في الموافقة', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> rejectItem(ApprovalItem item, [String reason = '']) async {
    AppLoggerService.debugTrace(
      className: 'ApprovalQueueController',
      method: 'rejectItem',
      feature: 'Approvals',
      status: 'INFO',
      params: {'id': item.id, 'category': item.category.name},
    );
    try {
      switch (item.category) {
        case ApprovalCategory.deposits:
        case ApprovalCategory.withdrawals:
          final adminId = SupabaseService.auth.currentUser?.id;
          final fnName = item.category == ApprovalCategory.withdrawals
              ? 'reject_withdrawal'
              : 'fn_reject_transaction';
          await SupabaseService.client.rpc(fnName, params: {
            'p_txn_id': item.id,
            'p_admin_id': adminId,
            'p_reason': reason.isNotEmpty ? reason : 'رفض بواسطة المدير',
          });
          break;
        case ApprovalCategory.kyc:
          await SupabaseService.client
              .from('kyc_documents')
              .update({'status': 'rejected'})
              .eq('id', item.id);
          break;
        case ApprovalCategory.loans:
          await SupabaseService.client
              .from('loans')
              .update({'status': 'rejected'})
              .eq('id', item.id);
          break;
        case ApprovalCategory.agents:
          await SupabaseService.client
              .from('agents')
              .update({'status': 'rejected'})
              .eq('id', item.id);
          break;
        case ApprovalCategory.all:
          break;
      }

      items.remove(item);
      _updateCounts();
      _applyFilter();

      Get.snackbar('تم', 'تم الرفض', snackPosition: SnackPosition.BOTTOM);
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'ApprovalQueueController',
        method: 'rejectItem',
        feature: 'Approvals',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل في الرفض', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
