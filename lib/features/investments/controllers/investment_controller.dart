import 'package:get/get.dart';
import '../models/investment_model.dart';

/// Investment Controller
/// Manages investment plans and user investments
class InvestmentController extends GetxController {
  final plans = <InvestmentPlan>[].obs;
  final userInvestments = <UserInvestment>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPlans();
    loadUserInvestments();
  }

  /// Load investment plans
  Future<void> loadPlans() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    plans.value = InvestmentPlan.getMockPlans();
    isLoading.value = false;
  }

  /// Load user investments
  Future<void> loadUserInvestments() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    userInvestments.value = UserInvestment.getMockInvestments();
    isLoading.value = false;
  }

  /// Create new plan
  Future<void> createPlan({
    required String name,
    required String nameAr,
    required double profitPercentage,
    required int durationDays,
    required double minAmount,
    required double maxAmount,
  }) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    Get.snackbar(
      'نجح',
      'تم إنشاء الخطة بنجاح',
      snackPosition: SnackPosition.BOTTOM,
    );

    isLoading.value = false;
    loadPlans();
  }

  /// Update plan
  Future<void> updatePlan(String planId, Map<String, dynamic> updates) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    // Safety Warning: Inform about impact
    Get.snackbar(
      'تنبيه',
      'تم تحديث الخطة. التعديلات تسري فقط على الاشتراكات الجديدة ولا تؤثر على الاستثمارات النشطة حالياً.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );

    isLoading.value = false;
    loadPlans();
  }

  /// Toggle plan active status
  Future<void> togglePlanStatus(String planId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    Get.snackbar(
      'نجح',
      'تم تحديث حالة الخطة',
      snackPosition: SnackPosition.BOTTOM,
    );

    isLoading.value = false;
    loadPlans();
  }

  /// Delete plan
  Future<void> deletePlan(String planId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    Get.snackbar('نجح', 'تم حذف الخطة', snackPosition: SnackPosition.BOTTOM);

    isLoading.value = false;
    loadPlans();
  }

  /// Get active investments
  List<UserInvestment> get activeInvestments {
    return userInvestments.where((inv) => inv.status == 'Active').toList();
  }

  /// Get completed investments
  List<UserInvestment> get completedInvestments {
    return userInvestments.where((inv) => inv.status == 'Completed').toList();
  }
}
