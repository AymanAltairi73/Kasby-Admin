import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/loan_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

/// Loan Controller — manages loans from Supabase `loans` table
/// All status changes use RPCs for atomicity and ledger integrity
class LoanController extends GetxController {
  final loans = <Loan>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLoans();
  }

  /// Load loans from Supabase with user names
  Future<void> loadLoans() async {
    debugPrint('[LoanController] ▶ Loading loans from Supabase...');
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('loans')
          .select('*, profiles!loans_user_id_fkey(full_name)')
          .order('created_at', ascending: false);

      loans.assignAll(
        (response as List).map((e) => Loan.fromSupabase(e)).toList(),
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'LoanController',
        method: 'loadLoans',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل القروض',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  List<Loan> get currentLoans => _filterLoans(LoanStatus.current);
  List<Loan> get paidLoans => _filterLoans(LoanStatus.paid);
  List<Loan> get delayedLoans => _filterLoans(LoanStatus.delayed);

  List<Loan> _filterLoans(LoanStatus status) {
    return loans.where((loan) {
      final matchesStatus = loan.status == status;
      final query = searchQuery.value.toLowerCase();
      final matchesSearch =
          loan.userName.toLowerCase().contains(query) ||
          loan.amount.toString().contains(query) ||
          loan.id.contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  /// Approve a pending loan via RPC (atomic: credits wallet + logs transaction)
  Future<void> approveLoan(String loanId) async {
    try {
      isLoading.value = true;
      debugPrint('[LoanController] ▶ Approving loan: $loanId');
      final adminId = SupabaseService.auth.currentUser?.id;

      await SupabaseService.client.rpc(
        'fn_approve_loan',
        params: {'p_loan_id': loanId, 'p_admin_id': adminId},
      );

      await loadLoans();
      Get.snackbar('نجح', 'تم الموافقة على القرض بنجاح');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'LoanController',
        method: 'approveLoan',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في الموافقة على القرض',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update loan status (Admin Action) — uses RPC for financial actions
  Future<void> updateLoanStatus(String loanId, LoanStatus newStatus) async {
    try {
      isLoading.value = true;

      if (newStatus == LoanStatus.current) {
        // Approving a loan: use RPC
        await approveLoan(loanId);
        return;
      }

      // For non-financial status changes (delayed, etc.)
      // These don't affect wallets so direct update is acceptable
      String statusStr;
      switch (newStatus) {
        case LoanStatus.paid:
          statusStr = 'paid';
          break;
        case LoanStatus.delayed:
          statusStr = 'delayed';
          break;
        default:
          statusStr = 'current';
      }

      await SupabaseService.client
          .from('loans')
          .update({'status': statusStr})
          .eq('id', loanId);

      final index = loans.indexWhere((l) => l.id == loanId);
      if (index != -1) {
        loans[index] = loans[index].copyWith(status: newStatus);
      }

      Get.snackbar('نجح', 'تم تحديث حالة القرض بنجاح');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'LoanController',
        method: 'updateLoanStatus',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة القرض',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
