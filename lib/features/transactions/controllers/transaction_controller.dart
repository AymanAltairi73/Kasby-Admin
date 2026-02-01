import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../../../core/services/audit_logger.dart';

/// Transaction Controller
/// Manages deposits and withdrawals
class TransactionController extends GetxController {
  final transactions = <Transaction>[].obs;
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
    isLoading.value = false;
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
