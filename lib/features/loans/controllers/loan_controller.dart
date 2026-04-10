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
          .select('*, profiles!loans_user_id_fkey!left(full_name)')
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

  List<Loan> get currentLoans => _filterLoansByStatuses([LoanStatus.active, LoanStatus.partial_paid, LoanStatus.approved, LoanStatus.overdue]);
  List<Loan> get paidLoans => _filterLoansByStatuses([LoanStatus.paid]);
  List<Loan> get delayedLoans => _filterLoansByStatuses([LoanStatus.overdue, LoanStatus.defaulted]);

  List<Loan> _filterLoansByStatuses(List<LoanStatus> statuses) {
    return loans.where((loan) {
      final matchesStatus = statuses.contains(loan.status);
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

  /// Fetch repayments for a specific loan
  Future<List<Map<String, dynamic>>> fetchRepayments(String loanId) async {
    try {
      final response = await SupabaseService.client
          .from('loan_repayments')
          .select()
          .eq('loan_id', loanId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error fetching repayments: $e');
      return [];
    }
  }

  /// Approve a pending loan via RPC (atomic: credits wallet + logs transaction)
  Future<void> approveLoan(String loanId) async {
    try {
      isLoading.value = true;
      debugPrint('[LoanController] ▶ Approving loan: $loanId');
      
      // We will use the existing approve logic but ensure the status updates correctly
      // In the hardened system, approval sets status to 'approved' or 'active'
      final adminId = SupabaseService.auth.currentUser?.id;
      
      await SupabaseService.client.rpc('fn_approve_loan', params: {
        'p_loan_id': loanId,
        'p_admin_id': adminId,
      });

      await loadLoans();
      Get.snackbar('نجح', 'تم الموافقة على القرض بنجاح');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'LoanController',
        method: 'approveLoan',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل في الموافقة على القرض');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update loan status (Admin Action)
  Future<void> updateLoanStatus(String loanId, LoanStatus newStatus) async {
    try {
      isLoading.value = true;
      
      final adminId = SupabaseService.auth.currentUser?.id;

      await SupabaseService.client.rpc('fn_update_loan_status', params: {
        'p_loan_id': loanId,
        'p_admin_id': adminId,
        'p_new_status': newStatus.name,
      });

      await loadLoans();
      Get.snackbar('نجح', 'تم تحديث حالة القرض بنجاح');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'LoanController',
        method: 'updateLoanStatus',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل في تحديث حالة القرض');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reject a loan with a reason
  Future<void> rejectLoan(String loanId, String reason) async {
    try {
      isLoading.value = true;
      debugPrint('[LoanController] ▶ Rejecting loan: $loanId with reason: $reason');
      
      final adminId = SupabaseService.auth.currentUser?.id;

      await SupabaseService.client.rpc('fn_reject_loan', params: {
        'p_loan_id': loanId,
        'p_admin_id': adminId,
        'p_reason': reason,
      });

      await loadLoans();
      Get.snackbar('نجح', 'تم رفض القرض وإرسال السبب');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'LoanController',
        method: 'rejectLoan',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل في رفض القرض');
    } finally {
      isLoading.value = false;
    }
  }
}
