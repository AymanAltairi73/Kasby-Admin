import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loan_model.dart';

class LoanController extends GetxController {
  final loans = <Loan>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLoans();
  }

  Future<void> loadLoans() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    final loansData = prefs.getString('loans');

    if (loansData != null) {
      final List decoded = jsonDecode(loansData);
      loans.assignAll(decoded.map((e) => Loan.fromJson(e)).toList());
    } else {
      loans.assignAll(Loan.getMockLoans());
      saveLoans();
    }
    isLoading.value = false;
  }

  Future<void> saveLoans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'loans',
      jsonEncode(loans.map((e) => e.toJson()).toList()),
    );
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
    final index = loans.indexWhere((l) => l.id == loanId);
    if (index != -1) {
      loans[index] = loans[index].copyWith(status: newStatus);
      await saveLoans();
      Get.snackbar('نجح', 'تم تحديث حالة القرض بنجاح');
    }
  }
}
