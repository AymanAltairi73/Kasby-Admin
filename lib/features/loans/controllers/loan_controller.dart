import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/loan_model.dart';
import '../models/loan_repayment_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../notifications/controllers/notification_controller.dart';

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
    debugPrint('[LoanController][loadLoans] Fetching data from /loans');
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('loans')
          .select('''
            *,
            profiles!loans_user_id_fkey!left(
              full_name,
              email,
              phone
            )
          ''')
          .order('created_at', ascending: false);

      debugPrint('[LoanController][loadLoans] Response: ${response.length} loans');
      
      loans.assignAll(
        (response as List?)?.map((e) => Loan.fromSupabase(e)).toList() ?? [],
      );
      
      debugPrint('[LoanController][loadLoans] Successfully loaded ${loans.length} loans');
    } catch (e, stackTrace) {
      debugPrint('[LoanController][loadLoans] Error: $e');
      debugPrint('[LoanController][loadLoans] Stack trace: $stackTrace');
      debugPrint('[LoanController][loadLoans] Endpoint: /loans');
      AppLoggerService.logError(
        controller: 'LoanController',
        method: 'loadLoans',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل القروض: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  List<Loan> get pendingLoans => _filterLoansByStatuses([LoanStatus.pending]);

  List<Loan> get currentLoans => _filterLoansByStatuses([
        LoanStatus.active,
        LoanStatus.partialPaid,
        LoanStatus.approved,
      ]);

  List<Loan> get paidLoans => _filterLoansByStatuses([LoanStatus.paid]);

  List<Loan> get delayedLoans =>
      _filterLoansByStatuses([LoanStatus.overdue, LoanStatus.defaulted]);

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

  /// Fetch repayment history for a specific loan
  Future<List<LoanRepayment>> fetchRepayments(String loanId) async {
    debugPrint('[LoanController][fetchRepayments] Fetching repayments for loan: $loanId');
    try {
      final response = await SupabaseService.client
          .from('loan_repayments')
          .select('''
            *,
            admin_profiles:profiles!loan_repayments_recorded_by_fkey(
              full_name,
              email
            )
          ''')
          .eq('loan_id', loanId)
          .order('created_at', ascending: false);

      final repayments = (response as List?)
          ?.map((e) => LoanRepayment.fromSupabase(e))
          .toList() ?? [];
          
      debugPrint('[LoanController][fetchRepayments] Successfully loaded ${repayments.length} repayments');
      return repayments;
    } catch (e, stackTrace) {
      debugPrint('[LoanController][fetchRepayments] Error: $e');
      debugPrint('[LoanController][fetchRepayments] Stack trace: $stackTrace');
      debugPrint('[LoanController][fetchRepayments] Endpoint: /loan_repayments');
      AppLoggerService.logError(
        controller: 'LoanController',
        method: 'fetchRepayments',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل في تحميل سجل السداد: ${e.toString()}');
      return [];
    }
  }

  /// Record a manual repayment (Admin Action)
  Future<void> recordRepayment({
    required String loanId,
    required double amount,
    required String paymentMethod,
    String? notes,
    String? receiptId,
    required RepaymentType type,
  }) async {
    try {
      isLoading.value = true;
      final adminId = SupabaseService.auth.currentUser?.id;

      // 1. Record the repayment in DB
      await SupabaseService.client.from('loan_repayments').insert({
        'loan_id': loanId,
        'amount': amount,
        'payment_method': paymentMethod,
        'notes': notes,
        'receipt_id': receiptId,
        'type': type == RepaymentType.full ? 'full' : 'partial',
        'recorded_by': adminId,
      });

      // 2. Trigger RPC to balance the loan and update status
      // This RPC should update loans.paid_amount, remaining_amount, and potentially final status
      await SupabaseService.client.rpc(
        'fn_process_loan_repayment',
        params: {
          'p_loan_id': loanId,
          'p_amount': amount,
          'p_admin_id': adminId,
        },
      );

      // 3. Send Notification to user
      final loan = loans.firstWhereOrNull((l) => l.id == loanId);
      if (loan != null) {
        Get.find<NotificationController>().sendNotification(
          '💳 تأكيد سداد قسط',
          'تم استلام مبلغ $amount قسطاً قرضكم. شكراً لالتزامكم.',
          'specific',
          specificUserId: loan.userId,
        );
      }

      await loadLoans();
      Get.snackbar('نجح', 'تم تسجيل دفعة السداد وتحديث حالة القرض');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'LoanController',
        method: 'recordRepayment',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل في تسجيل الدفعة: $e');
    } finally {
      isLoading.value = false;
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

      await SupabaseService.client.rpc(
        'fn_approve_loan',
        params: {'p_loan_id': loanId, 'p_admin_id': adminId},
      );

      // Send User Notification
      final loan = loans.firstWhereOrNull((l) => l.id == loanId);
      if (loan != null) {
        Get.find<NotificationController>().sendNotification(
          '💰 مبروك!',
          'تمت الموافقة على طلب القرض الخاص بك، تم إضافة المبلغ إلى محفظتك.',
          'specific',
          specificUserId: loan.userId,
        );
      }

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

      await SupabaseService.client.rpc(
        'fn_update_loan_status',
        params: {
          'p_loan_id': loanId,
          'p_admin_id': adminId,
          'p_new_status': newStatus.toDbStatus(),
        },
      );

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
      debugPrint(
        '[LoanController] ▶ Rejecting loan: $loanId with reason: $reason',
      );

      final adminId = SupabaseService.auth.currentUser?.id;

      await SupabaseService.client.rpc(
        'fn_reject_loan',
        params: {
          'p_loan_id': loanId,
          'p_admin_id': adminId,
          'p_reason': reason,
        },
      );

      // Send User Notification
      final loan = loans.firstWhereOrNull((l) => l.id == loanId);
      if (loan != null) {
        Get.find<NotificationController>().sendNotification(
          '⚠️ طلب القرض',
          'تم رفض طلب القرض الخاص بك. يمكنك التواصل مع الدعم الفني لمزيد من المعلومات.',
          'specific',
          specificUserId: loan.userId,
        );
      }

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
