import 'package:get/get.dart';
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

  void loadLoans() async {
    isLoading.value = true;
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    loans.assignAll(Loan.getMockLoans());
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
}
