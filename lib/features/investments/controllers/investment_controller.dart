import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final plansData = prefs.getString('investment_plans');

    if (plansData != null) {
      final List decoded = jsonDecode(plansData);
      plans.assignAll(decoded.map((e) => InvestmentPlan.fromJson(e)).toList());
    } else {
      plans.assignAll(InvestmentPlan.getMockPlans());
      savePlans();
    }
    isLoading.value = false;
  }

  /// Load user investments
  Future<void> loadUserInvestments() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    final userInvData = prefs.getString('user_investments');

    if (userInvData != null) {
      final List decoded = jsonDecode(userInvData);
      userInvestments.assignAll(
        decoded.map((e) => UserInvestment.fromJson(e)).toList(),
      );
    } else {
      userInvestments.assignAll(UserInvestment.getMockInvestments());
      saveUserInvestments();
    }
    isLoading.value = false;
  }

  Future<void> savePlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'investment_plans',
      jsonEncode(plans.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveUserInvestments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_investments',
      jsonEncode(userInvestments.map((e) => e.toJson()).toList()),
    );
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
    await savePlans();

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

      await savePlans();

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

    plans.removeWhere((p) => p.id == planId);
    await savePlans();

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
