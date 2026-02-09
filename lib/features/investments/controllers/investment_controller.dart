import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
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
    required String nameAr,
    required String descriptionAr,
    required double profitPercentage,
    required double minAmount,
    required double maxAmount,
    List<double>? availableAmounts,
    String? imagePath,
  }) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final newPlan = InvestmentPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nameAr: nameAr,
      descriptionAr: descriptionAr,
      profitPercentage: profitPercentage,
      minAmount: minAmount,
      maxAmount: maxAmount,
      availableAmounts: availableAmounts,
      imagePath: imagePath,
      isActive: true,
      createdAt: DateTime.now(),
    );

    plans.add(newPlan);

    Get.snackbar(
      'نجح',
      'تم إنشاء الخطة بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: KasbyColors.success.withValues(alpha: 0.1),
      colorText: KasbyColors.success,
    );

    isLoading.value = false;
  }

  /// Update plan
  Future<void> updatePlan(String planId, Map<String, dynamic> updates) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final index = plans.indexWhere((p) => p.id == planId);
    if (index != -1) {
      final oldPlan = plans[index];
      plans[index] = oldPlan.copyWith(
        nameAr: updates['nameAr'],
        descriptionAr: updates['descriptionAr'],
        profitPercentage: updates['profitPercentage'],
        minAmount: updates['minAmount'],
        maxAmount: updates['maxAmount'],
        availableAmounts: updates['availableAmounts'],
        imagePath: updates['imagePath'],
      );

      Get.snackbar(
        'نجح',
        'تم تحديث بيانات الخطة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.primaryGold.withValues(alpha: 0.1),
        colorText: KasbyColors.primaryGold,
      );
    }

    isLoading.value = false;
  }

  /// Delete plan
  Future<void> deletePlan(String planId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    plans.removeWhere((p) => p.id == planId);

    Get.snackbar(
      'نجح',
      'تم حذف الخطة نهائياً من العرض',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: KasbyColors.error.withValues(alpha: 0.1),
      colorText: KasbyColors.error,
    );

    isLoading.value = false;
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
