import 'package:get/get.dart';
import '../models/transaction_model.dart';
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
    await Future.delayed(const Duration(seconds: 1));
    transactions.value = Transaction.getMockTransactions();
    _applyFilters();
    isLoading.value = false;
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
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    // Log action
    await AuditLogger.log(
      adminName: 'Admin',
      action: 'موافقة على معاملة',
      details: 'تمت الموافقة على المعاملة $transactionId',
    );

    Get.snackbar(
      'نجح',
      'تمت الموافقة على المعاملة',
      snackPosition: SnackPosition.BOTTOM,
    );

    isLoading.value = false;
    loadTransactions();
  }

  /// Reject transaction
  Future<void> rejectTransaction(String transactionId, String reason) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    // Log action
    await AuditLogger.log(
      adminName: 'Admin',
      action: 'رفض معاملة',
      details: 'تم رفض المعاملة $transactionId. السبب: $reason',
    );

    Get.snackbar('نجح', 'تم رفض المعاملة', snackPosition: SnackPosition.BOTTOM);

    isLoading.value = false;
    loadTransactions();
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
