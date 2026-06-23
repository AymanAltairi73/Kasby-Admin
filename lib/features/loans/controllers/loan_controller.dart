import 'dart:async';
import 'package:get/get.dart';
import '../models/loan_model.dart';
import '../models/loan_repayment_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../../core/services/permission_service.dart';

/// Loan Controller — manages loans from Supabase `loans` table
/// All status changes use RPCs for atomicity and ledger integrity
class LoanController extends GetxController {
  final loans = <Loan>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  StreamSubscription? _loansSubscription;
  Timer? _reloadDebounce;
  Worker? _authWorker;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'LoanController',
      method: 'onInit',
      feature: 'Loans',
      status: 'INFO',
    );
    super.onInit();
    try {
      final auth = Get.find<AuthController>();
      _authWorker = ever(auth.isLoggedIn, (loggedIn) {
        if (loggedIn) {
          loadLoans();
          _listenToLoans();
        } else {
          _stopListening();
          loans.clear();
        }
      });
      if (auth.isLoggedIn.value) {
        loadLoans();
        _listenToLoans();
      }
    } catch (_) {
      loadLoans();
      _listenToLoans();
    }
  }

  void _listenToLoans() {
    _loansSubscription?.cancel();
    _loansSubscription = SupabaseService.client
        .from('loans')
        .stream(primaryKey: ['id'])
        .listen((_) {
          _reloadDebounce?.cancel();
          _reloadDebounce = Timer(const Duration(milliseconds: 750), loadLoans);
        }, onError: (_) {});
  }

  void _stopListening() {
    _reloadDebounce?.cancel();
    _loansSubscription?.cancel();
    _loansSubscription = null;
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'LoanController',
      method: 'onClose',
      feature: 'Loans',
      status: 'INFO',
    );
    _stopListening();
    _authWorker?.dispose();
    super.onClose();
  }

  /// Load loans from Supabase with user names
  Future<void> loadLoans() async {
    AppLoggerService.debugTrace(
      className: 'LoanController',
      method: 'loadLoans',
      feature: 'Loans',
      status: 'INFO',
    );
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

      loans.assignAll(
        (response as List?)?.map((e) => Loan.fromSupabase(e)).toList() ?? [],
      );

      AppLoggerService.debugTrace(
        className: 'LoanController',
        method: 'loadLoans',
        feature: 'Loans',
        status: 'SUCCESS',
        params: {'count': loans.length},
      );
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'LoanController',
        method: 'loadLoans',
        feature: 'Loans',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
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
    AppLoggerService.debugTrace(
      className: 'LoanController',
      method: 'fetchRepayments',
      feature: 'Loans',
      status: 'INFO',
      params: {'loanId': loanId},
    );
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

      AppLoggerService.debugTrace(
        className: 'LoanController',
        method: 'fetchRepayments',
        feature: 'Loans',
        status: 'SUCCESS',
        params: {'count': repayments.length},
      );
      return repayments;
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'LoanController',
        method: 'fetchRepayments',
        feature: 'Loans',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
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

  /// Record a manual repayment (Admin Action) — single RPC entry point
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
      final idempotencyKey =
          'admin_repay_${loanId}_${DateTime.now().millisecondsSinceEpoch}';

      final result = await SupabaseService.client.rpc(
        'fn_admin_record_loan_repayment',
        params: {
          'p_loan_id': loanId,
          'p_amount': amount,
          'p_payment_method': paymentMethod,
          'p_notes': notes,
          'p_receipt_id': receiptId,
          'p_type': type == RepaymentType.full ? 'full' : 'partial',
          'p_recorded_by': adminId,
          'p_idempotency_key': idempotencyKey,
        },
      );

      if (result is Map && result['success'] != true) {
        throw Exception(result['message'] ?? 'فشل تسجيل السداد');
      }

      await AppLoggerService.logActivity(
        action: 'admin_record_loan_repayment',
        entityType: 'loan',
        entityId: loanId,
        details: {
          'amount': amount,
          'payment_method': paymentMethod,
          'type': type == RepaymentType.full ? 'full' : 'partial',
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
    final permService = Get.find<PermissionService>();
    if (!permService.canApproveFinancials) {
      Get.snackbar('صلاحيات غير كافية', 'لا تملك صلاحية الموافقة على القروض',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoading.value = true;
      AppLoggerService.debugTrace(
        className: 'LoanController',
        method: 'approveLoan',
        feature: 'Loans',
        status: 'INFO',
        params: {'loanId': loanId},
      );

      final adminId = SupabaseService.auth.currentUser?.id;
      final loan = loans.firstWhereOrNull((l) => l.id == loanId);

      await SupabaseService.client.rpc(
        'fn_approve_loan',
        params: {'p_loan_id': loanId, 'p_admin_id': adminId},
      );

      await AppLoggerService.logActivity(
        action: 'admin_approve_loan',
        entityType: 'loan',
        entityId: loanId,
        details: loan != null
            ? {'user_id': loan.userId, 'amount': loan.amount}
            : null,
      );

      // Send User Notification
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
    final permService = Get.find<PermissionService>();
    if (!permService.canApproveFinancials) {
      Get.snackbar('صلاحيات غير كافية', 'لا تملك صلاحية رفض القروض',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoading.value = true;
      AppLoggerService.debugTrace(
        className: 'LoanController',
        method: 'rejectLoan',
        feature: 'Loans',
        status: 'INFO',
        params: {'loanId': loanId},
      );

      final adminId = SupabaseService.auth.currentUser?.id;
      final loan = loans.firstWhereOrNull((l) => l.id == loanId);

      await SupabaseService.client.rpc(
        'fn_reject_loan',
        params: {
          'p_loan_id': loanId,
          'p_admin_id': adminId,
          'p_reason': reason,
        },
      );

      await AppLoggerService.logActivity(
        action: 'admin_reject_loan',
        entityType: 'loan',
        entityId: loanId,
        details: {
          if (loan != null) 'user_id': loan.userId,
          'reason': reason,
        },
      );

      // Send User Notification
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
