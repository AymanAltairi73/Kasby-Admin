import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../models/investment_model.dart';

/// Investment Controller — manages investment plans & user investments from Supabase
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

  /// Load investment plans from Supabase
  Future<void> loadPlans() async {
    debugPrint('[InvestmentController] ▶ Loading investment plans...');
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('investment_plans')
          .select()
          .order('created_at', ascending: false);

      plans.assignAll(
        (response as List).map((e) => InvestmentPlan.fromSupabase(e)).toList(),
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'InvestmentController',
        method: 'loadPlans',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل خطط الاستثمار',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  /// Load user investments from Supabase
  Future<void> loadUserInvestments() async {
    debugPrint('[InvestmentController] ▶ Loading user investments...');
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('user_investments')
          .select(
            '*, profiles!user_investments_user_id_fkey!left(full_name), investment_plans!user_investments_plan_id_fkey!left(name_ar)',
          )
          .order('created_at', ascending: false);

      userInvestments.assignAll(
        (response as List).map((e) => UserInvestment.fromSupabase(e)).toList(),
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'InvestmentController',
        method: 'loadUserInvestments',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل استثمارات المستخدمين',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
    try {
      await SupabaseService.client.from('investment_plans').insert({
        'name_ar': nameAr,
        'description_ar': descriptionAr,
        'profit_percentage': profitPercentage,
        'min_amount': minAmount,
        'max_amount': maxAmount,
        'is_active': true,
      });

      await loadPlans();

      Get.snackbar(
        'نجح',
        'تم إنشاء الخطة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.success.withValues(alpha: 0.1),
        colorText: KasbyColors.success,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'InvestmentController',
        method: 'createPlan',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في إنشاء الخطة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  /// Update plan
  Future<void> updatePlan(String planId, Map<String, dynamic> updates) async {
    isLoading.value = true;
    try {
      final supabaseUpdates = <String, dynamic>{};
      if (updates['nameAr'] != null) {
        supabaseUpdates['name_ar'] = updates['nameAr'];
      }
      if (updates['descriptionAr'] != null) {
        supabaseUpdates['description_ar'] = updates['descriptionAr'];
      }
      if (updates['profitPercentage'] != null) {
        supabaseUpdates['profit_percentage'] = updates['profitPercentage'];
      }
      if (updates['minAmount'] != null) {
        supabaseUpdates['min_amount'] = updates['minAmount'];
      }
      if (updates['maxAmount'] != null) {
        supabaseUpdates['max_amount'] = updates['maxAmount'];
      }
      if (updates['imagePath'] != null) {
        supabaseUpdates['image_path'] = updates['imagePath'];
      }

      await SupabaseService.client
          .from('investment_plans')
          .update(supabaseUpdates)
          .eq('id', planId);

      await loadPlans();

      Get.snackbar(
        'نجح',
        'تم تحديث بيانات الخطة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.primaryGold.withValues(alpha: 0.1),
        colorText: KasbyColors.primaryGold,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'InvestmentController',
        method: 'updatePlan',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحديث الخطة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  /// Soft-delete plan (set is_active = false to preserve referential integrity)
  Future<void> deletePlan(String planId) async {
    isLoading.value = true;
    try {
      await SupabaseService.client
          .from('investment_plans')
          .update({'is_active': false})
          .eq('id', planId);

      plans.removeWhere((p) => p.id == planId);

      Get.snackbar(
        'نجح',
        'تم إلغاء تفعيل الخطة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.error.withValues(alpha: 0.1),
        colorText: KasbyColors.error,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'InvestmentController',
        method: 'deletePlan',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في إلغاء تفعيل الخطة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  /// Get active investments
  List<UserInvestment> get activeInvestments {
    return userInvestments.where((inv) => inv.status == 'active').toList();
  }

  /// Get completed investments
  List<UserInvestment> get completedInvestments {
    return userInvestments.where((inv) => inv.status == 'matured').toList();
  }
}
