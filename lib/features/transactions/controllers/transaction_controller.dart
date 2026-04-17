import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/models/time_filter.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../repositories/transaction_repository.dart';

/// Transaction Controller — manages financial transactions from Supabase
class TransactionController extends GetxController {
  final TransactionRepository _transactionRepo = TransactionRepository(SupabaseService.client);
  
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
    _listenToTransactions();
  }

  // ─── TRANSACTIONS LISTENER ────────────────────────────
  StreamSubscription? _transactionSubscription;

  void _listenToTransactions() {
    _transactionSubscription?.cancel();
    _transactionSubscription = SupabaseService.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) async {
          debugPrint('[TransactionController] ℹ️ Transactions updated via stream');
          
          // Re-fetch with joins to ensure user names are present (stream doesn't support joins)
          await loadTransactions();
        }, onError: (error) {
          debugPrint('[TransactionController] ❌ Stream error: $error');
        });
  }

  /// Pending deposits getter
  List<Transaction> get pendingDeposits => transactions
      .where((t) => t.status == 'pending' && t.type == 'deposit')
      .toList();

  /// Pending withdrawals getter
  List<Transaction> get pendingWithdrawals => transactions
      .where((t) => t.status == 'pending' && t.type == 'withdrawal')
      .toList();

  /// All deposits getter
  List<Transaction> get allDeposits => transactions
      .where((t) => t.type == 'deposit' || t.type == 'admin_credit' || t.type == 'profit')
      .toList();

  /// All withdrawals getter
  List<Transaction> get allWithdrawals => transactions

      .where((t) => t.type == 'withdrawal' || t.type == 'admin_debit')
      .toList();

  /// All transfers getter
  List<Transaction> get allTransfers => transactions
      .where((t) => t.type == 'transfer_in' || t.type == 'transfer_out')
      .toList();

  /// Load transactions from Supabase with user names
  Future<void> loadTransactions() async {
    debugPrint('[TransactionController] ▶ Loading transactions...');
    isLoading.value = true;
    try {
      final response = await _transactionRepo.getTransactionsPaginated();
      transactions.value = response;
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
        .where((t) => (t.type == 'deposit' || t.type == 'admin_credit') && (t.status == 'approved' || t.status == 'completed'))
        .fold(0.0, (sum, t) => sum + t.amount);
    totalWithdrawals.value = transactions
        .where((t) => (t.type == 'withdrawal' || t.type == 'admin_debit') && (t.status == 'approved' || t.status == 'completed'))
        .fold(0.0, (sum, t) => sum + t.amount);
    pendingCount.value = transactions
        .where((t) => t.status == 'pending')
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
      if (selectedType.value == 'transfer') {
        result = result.where((t) => t.type == 'transfer_in' || t.type == 'transfer_out').toList();
      } else {
        result = result.where((t) => t.type == selectedType.value).toList();
      }
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
    final txnIndex = transactions.indexWhere((t) => t.id == txnId);
    if (txnIndex == -1) return;
    final originalStatus = transactions[txnIndex].status;

    // Optimistic UI Update
    transactions[txnIndex] = transactions[txnIndex].copyWith(status: 'approved');
    _applyFilters();
    _calculateStats();

    try {
      debugPrint('[TransactionController] ▶ Approving deposit: $txnId (Optimistic)');
      final adminId = SupabaseService.auth.currentUser?.id;

      await _transactionRepo.processTransaction(
        'fn_process_deposit',
        {'p_txn_id': txnId, 'p_admin_id': adminId},
      );

      // Send User Notification
      Get.find<NotificationController>().sendNotification(
        '📥 إيداع ناجح',
        'تم تأكيد عملية الإيداع وإضافة الرصيد إلى حسابك بنجاح.',
        'specific',
        specificUserId: transactions[txnIndex].userId,
      );

      Get.snackbar(
        'تم',
        'تمت الموافقة على الإيداع',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      // Rollback
      transactions[txnIndex] = transactions[txnIndex].copyWith(status: originalStatus);
      _applyFilters();
      _calculateStats();

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
    }
  }

  /// Approve a withdrawal transaction via RPC
  Future<void> approveWithdrawal(String txnId) async {
    final txnIndex = transactions.indexWhere((t) => t.id == txnId);
    if (txnIndex == -1) return;
    final originalStatus = transactions[txnIndex].status;

    // Optimistic UI Update
    transactions[txnIndex] = transactions[txnIndex].copyWith(status: 'approved');
    _applyFilters();
    _calculateStats();

    try {
      final adminId = SupabaseService.auth.currentUser?.id;

      await _transactionRepo.processTransaction(
        'approve_withdrawal',
        {'p_txn_id': txnId, 'p_admin_id': adminId},
      );

      // Send User Notification
      Get.find<NotificationController>().sendNotification(
        '📤 سحب ناجح',
        'تمت الموافقة على طلب السحب الخاص بك، المبلغ في طريقه إليك.',
        'specific',
        specificUserId: transactions[txnIndex].userId,
      );

      Get.snackbar(
        'تم',
        'تمت الموافقة على السحب بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );
    } catch (e, stackTrace) {
      // Rollback
      transactions[txnIndex] = transactions[txnIndex].copyWith(status: originalStatus);
      _applyFilters();
      _calculateStats();

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
    }
  }

  /// Approve transaction (auto-detects type)
  Future<void> approveTransaction(String txnId) async {
    final txn = transactions.firstWhereOrNull((t) => t.id == txnId);
    if (txn == null) return;

    if (txn.type == 'deposit') {
      await approveDeposit(txnId);
    } else if (txn.type == 'withdrawal') {
      await approveWithdrawal(txnId);
    }
  }

  /// Reject a transaction via RPC
  Future<void> rejectTransaction(String txnId, [String reason = '']) async {
    final txnIndex = transactions.indexWhere((t) => t.id == txnId);
    if (txnIndex == -1) return;
    final txn = transactions[txnIndex];
    final originalStatus = txn.status;

    // Optimistic UI Update
    transactions[txnIndex] = transactions[txnIndex].copyWith(status: 'rejected');
    _applyFilters();
    _calculateStats();

    try {
      debugPrint('[TransactionController] ▶ Rejecting transaction: $txnId (Optimistic)');
      final adminId = SupabaseService.auth.currentUser?.id;
      final fnName = (txn.type == 'withdrawal') ? 'reject_withdrawal' : 'fn_reject_transaction';

      await _transactionRepo.processTransaction(
        fnName,
        {
          'p_txn_id': txnId,
          'p_admin_id': adminId,
          'p_reason': reason.isNotEmpty ? reason : 'رفض بواسطة المدير',
        },
      );

      // Send User Notification
      Get.find<NotificationController>().sendNotification(
        '⚠️ تنبيه مالي',
        'تم رفض المعاملة المالية رقم ${txn.id}. يرجى مراجعة السبب في قائمة المعاملات.',
        'specific',
        specificUserId: txn.userId,
      );

      Get.snackbar(
        'تم',
        'تم رفض المعاملة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } catch (e, stackTrace) {
      // Rollback
      transactions[txnIndex] = transactions[txnIndex].copyWith(status: originalStatus);
      _applyFilters();
      _calculateStats();

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
    }
  }

  @override
  void onClose() {
    _transactionSubscription?.cancel();
    super.onClose();
  }
}
