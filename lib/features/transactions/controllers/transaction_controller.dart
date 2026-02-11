import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../../users/controllers/user_controller.dart';
import '../../../core/controllers/settings_controller.dart';
import '../../../core/services/audit_logger.dart';
import '../../../core/models/time_filter.dart';

/// Transaction Controller
/// Manages deposits and withdrawals
class TransactionController extends GetxController {
  final transactions = <Transaction>[].obs;
  final filteredTransactions = <Transaction>[].obs;
  final selectedStatus = 'All'.obs;
  final selectedType = 'Both'.obs;
  final selectedTimeFilter = TimeFilter.all.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  /// Load transactions
  Future<void> loadTransactions() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    final transData = prefs.getString('transactions');

    if (transData != null) {
      final List decoded = jsonDecode(transData);
      transactions.assignAll(
        decoded.map((e) => Transaction.fromJson(e)).toList(),
      );
    } else {
      transactions.assignAll(Transaction.getMockTransactions());
      saveTransactions();
    }
    _applyFilters();
    isLoading.value = false;
  }

  Future<void> saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'transactions',
      jsonEncode(transactions.map((e) => e.toJson()).toList()),
    );
  }

  /// Apply all filters
  void _applyFilters() {
    var result = transactions.toList();

    // Time Filter
    final now = DateTime.now();
    if (selectedTimeFilter.value != TimeFilter.all) {
      result = result.where((t) {
        final difference = now.difference(t.createdAt);
        switch (selectedTimeFilter.value) {
          case TimeFilter.daily:
            return difference.inDays == 0 && t.createdAt.day == now.day;
          case TimeFilter.weekly:
            return difference.inDays <= 7;
          case TimeFilter.monthly:
            return difference.inDays <= 30;
          default:
            return true;
        }
      }).toList();
    }

    // Status Filter
    if (selectedStatus.value != 'All') {
      result = result.where((t) => t.status == selectedStatus.value).toList();
    }

    // Type Filter
    if (selectedType.value != 'Both') {
      result = result.where((t) => t.type == selectedType.value).toList();
    }

    filteredTransactions.value = result;
  }

  /// Change Status Filter
  void setStatusFilter(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  /// Change Type Filter
  void setTypeFilter(String type) {
    selectedType.value = type;
    _applyFilters();
  }

  /// Change Time Filter
  void setTimeFilter(TimeFilter filter) {
    selectedTimeFilter.value = filter;
    _applyFilters();
  }

  /// Get pending deposits
  List<Transaction> get pendingDeposits {
    return transactions
        .where((t) => t.type == 'Deposit' && t.status == 'Pending')
        .toList();
  }

  /// Get pending withdrawals
  List<Transaction> get pendingWithdrawals {
    return transactions
        .where((t) => t.type == 'Withdrawal' && t.status == 'Pending')
        .toList();
  }

  /// Get all deposits
  List<Transaction> get allDeposits {
    return transactions.where((t) => t.type == 'Deposit').toList();
  }

  /// Get all withdrawals
  List<Transaction> get allWithdrawals {
    return transactions.where((t) => t.type == 'Withdrawal').toList();
  }

  /// Approve transaction
  Future<void> approveTransaction(String transactionId) async {
    final settingsController = Get.find<SettingsController>();

    final index = transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      final transaction = transactions[index];

      // Check for emergency pause if it's a withdrawal
      if (transaction.type == 'Withdrawal' &&
          settingsController.pauseWithdrawals) {
        Get.snackbar(
          'تنبيه النظام',
          'لا يمكن الموافقة على السحب حالياً بسبب إيقاف عمليات السحب من الإعدادات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;

      // Update transaction status
      transactions[index] = transaction.copyWith(
        status: 'Approved',
        processedAt: DateTime.now(),
      );

      // If it's an adjustment, update the user wallet
      if (transaction.type == 'Adjustment') {
        final userController = Get.find<UserController>();
        final userIndex = userController.users.indexWhere(
          (u) => u.id == transaction.userId,
        );
        if (userIndex != -1) {
          final user = userController.users[userIndex];
          userController.users[userIndex] = user.copyWith(
            walletBalance: user.walletBalance + transaction.amount,
          );
          // UserController _saveUsers will be called inside updateUser or similar if we use that,
          // but here we are directly modifying the list.
          // We should ideally call a method on userController to update and save.
          await userController.updateUser(userController.users[userIndex]);
        }
      }

      await saveTransactions();

      // Log action
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'موافقة على معاملة',
        details:
            'تم الاعتماد والمصادقة على المعاملة $transactionId من نوع ${transaction.type} بمبلغ ${transaction.amount}',
      );

      Get.snackbar(
        'نجح',
        'تم الاعتماد والمصادقة على المعاملة',
        snackPosition: SnackPosition.BOTTOM,
      );

      _applyFilters();
      isLoading.value = false;
    }
  }

  /// Reject transaction
  Future<void> rejectTransaction(String transactionId, String reason) async {
    final index = transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      isLoading.value = true;

      transactions[index] = transactions[index].copyWith(
        status: 'Rejected',
        reason: reason,
        processedAt: DateTime.now(),
      );

      await saveTransactions();

      // Log action
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'رفض معاملة',
        details: 'تم رفض المعاملة $transactionId. السبب: $reason',
      );

      Get.snackbar(
        'نجح',
        'تم رفض المعاملة',
        snackPosition: SnackPosition.BOTTOM,
      );

      _applyFilters();
      isLoading.value = false;
    }
  }

  /// Filter transactions by status
  List<Transaction> filterByStatus(String status) {
    return transactions.where((t) => t.status == status).toList();
  }

  /// Filter transactions by type
  List<Transaction> filterByType(String type) {
    return transactions.where((t) => t.type == type).toList();
  }
}
