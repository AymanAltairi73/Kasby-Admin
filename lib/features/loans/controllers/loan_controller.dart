import 'package:get/get.dart';
import '../models/loan_model.dart';
import '../../../core/services/supabase_service.dart';

/// Loan Controller — manages loans from Supabase `loans` table
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
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('loans')
          .select('*, profiles!loans_user_id_fkey(full_name)')
          .order('created_at', ascending: false);

      loans.assignAll(
        (response as List).map((e) => Loan.fromSupabase(e)).toList(),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل القروض: $e',
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

  /// Update loan status (Admin Action)
  Future<void> updateLoanStatus(String loanId, LoanStatus newStatus) async {
    try {
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
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة القرض: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
