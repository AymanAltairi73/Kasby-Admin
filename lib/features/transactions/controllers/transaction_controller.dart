import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/models/time_filter.dart';

/// Transaction Controller — manages financial transactions from Supabase
class TransactionController extends GetxController {
  final transactions = <Transaction>[].obs;
  final filteredTransactions = <Transaction>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedType = 'Both'.obs;
  final selectedStatus = 'all'.obs;
  final selectedTimeFilter = TimeFilter.all.obs;

  // Stats
  final totalDeposits = 0.0.obs;
  final totalWithdrawals = 0.0.obs;
  final pendingCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  /// Pending deposits getter
  List<Transaction> get pendingDeposits => transactions
      .where((t) => t.status == 'Pending' && t.type == 'Deposit')
      .toList();

  /// Pending withdrawals getter
  List<Transaction> get pendingWithdrawals => transactions
      .where((t) => t.status == 'Pending' && t.type == 'Withdrawal')
      .toList();

  /// Load transactions from Supabase with user names
  Future<void> loadTransactions() async {
    debugPrint('[TransactionController] ▶ Loading transactions...');
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('transactions')
          .select('*, profiles!transactions_user_id_fkey(full_name)')
          .order('created_at', ascending: false);

      transactions.value = (response as List)
          .map((json) => Transaction.fromSupabase(json))
          .toList();
      _applyFilters();
      _calculateStats();
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'TransactionController',
        method: 'loadTransactions',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل المعاملات',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateStats() {
    totalDeposits.value = transactions
        .where((t) => t.type == 'Deposit' && t.status == 'Approved')
        .fold(0.0, (sum, t) => sum + t.amount);
    totalWithdrawals.value = transactions
        .where((t) => t.type == 'Withdrawal' && t.status == 'Approved')
        .fold(0.0, (sum, t) => sum + t.amount);
    pendingCount.value = transactions
        .where((t) => t.status == 'Pending')
        .length;
  }

  /// Search transactions
  void searchTransactions(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  /// Filter by type
  void filterByType(String type) {
    selectedType.value = type;
    _applyFilters();
  }

  /// Set type filter (alias used by UI)
  void setTypeFilter(String type) {
    selectedType.value = type;
    _applyFilters();
  }

  /// Filter by status
  void filterByStatus(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  /// Set time filter
  void setTimeFilter(TimeFilter filter) {
    selectedTimeFilter.value = filter;
    _applyFilters();
  }

  void _applyFilters() {
    List<Transaction> result = List.from(transactions);

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where(
            (t) => t.userName.toLowerCase().contains(q) || t.id.contains(q),
          )
          .toList();
    }

    if (selectedType.value != 'Both' && selectedType.value != 'all') {
      result = result.where((t) => t.type == selectedType.value).toList();
    }

    if (selectedStatus.value != 'all') {
      result = result.where((t) => t.status == selectedStatus.value).toList();
    }

    // Apply time filter
    final now = DateTime.now();
    switch (selectedTimeFilter.value) {
      case TimeFilter.daily:
        result = result
            .where(
              (t) =>
                  t.createdAt.year == now.year &&
                  t.createdAt.month == now.month &&
                  t.createdAt.day == now.day,
            )
            .toList();
        break;
      case TimeFilter.weekly:
        final weekAgo = now.subtract(const Duration(days: 7));
        result = result.where((t) => t.createdAt.isAfter(weekAgo)).toList();
        break;
      case TimeFilter.monthly:
        final monthAgo = now.subtract(const Duration(days: 30));
        result = result.where((t) => t.createdAt.isAfter(monthAgo)).toList();
        break;
      case TimeFilter.all:
        break;
    }

    filteredTransactions.value = result;
  }

  /// Approve a deposit transaction via RPC
  Future<void> approveDeposit(String txnId) async {
    try {
      isLoading.value = true;
      debugPrint('[TransactionController] ▶ Approving deposit: $txnId');
      final adminId = SupabaseService.auth.currentUser?.id;

      await SupabaseService.client.rpc(
        'fn_process_deposit',
        params: {'p_txn_id': txnId, 'p_admin_id': adminId},
      );

      await loadTransactions();
      Get.snackbar(
        'تم',
        'تمت الموافقة على الإيداع',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'TransactionController',
        method: 'approveDeposit',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في الموافقة على الإيداع',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Approve a withdrawal transaction via RPC
  Future<void> approveWithdrawal(String txnId) async {
    try {
      isLoading.value = true;
      final adminId = SupabaseService.auth.currentUser?.id;

      await SupabaseService.client.rpc(
        'fn_process_withdrawal',
        params: {'p_txn_id': txnId, 'p_admin_id': adminId},
      );

      await loadTransactions();
      Get.snackbar(
        'تم',
        'تمت الموافقة على السحب',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'TransactionController',
        method: 'approveWithdrawal',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في الموافقة على السحب',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Approve transaction (auto-detects type)
  Future<void> approveTransaction(String txnId) async {
    final txn = transactions.firstWhereOrNull((t) => t.id == txnId);
    if (txn == null) return;

    if (txn.type == 'Deposit') {
      await approveDeposit(txnId);
    } else if (txn.type == 'Withdrawal') {
      await approveWithdrawal(txnId);
    }
  }

  /// Reject a transaction via RPC — positional reason parameter for UI compat
  Future<void> rejectTransaction(String txnId, [String reason = '']) async {
    try {
      isLoading.value = true;
      debugPrint('[TransactionController] ▶ Rejecting transaction: $txnId');
      final adminId = SupabaseService.auth.currentUser?.id;

      await SupabaseService.client.rpc(
        'fn_reject_transaction',
        params: {
          'p_txn_id': txnId,
          'p_admin_id': adminId,
          'p_reason': reason.isNotEmpty ? reason : 'رفض بواسطة المدير',
        },
      );

      await loadTransactions();
      Get.snackbar(
        'تم',
        'تم رفض المعاملة',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'TransactionController',
        method: 'rejectTransaction',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في رفض المعاملة',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
