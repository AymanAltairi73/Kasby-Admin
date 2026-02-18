import 'package:get/get.dart';
import '../models/subscription_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

/// Subscription Controller — manages subscription plans from Supabase
class SubscriptionController extends GetxController {
  final plans = <SubscriptionPlan>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPlans();
  }

  /// Load plans from Supabase, fallback to defaults if no data
  Future<void> loadPlans() async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('subscription_plans')
          .select()
          .order('created_at', ascending: false);

      if ((response as List).isNotEmpty) {
        plans.assignAll(
          response.map((e) => SubscriptionPlan.fromSupabase(e)).toList(),
        );
      } else {
        // Fallback to default plans if table is empty
        plans.assignAll(SubscriptionPlan.getDefaultPlans());
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SubscriptionController',
        method: 'loadPlans',
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to default plans on error
      plans.assignAll(SubscriptionPlan.getDefaultPlans());
    }
    isLoading.value = false;
  }

  /// Add a new plan
  Future<void> createPlan(SubscriptionPlan plan) async {
    isLoading.value = true;
    try {
      await SupabaseService.client
          .from('subscription_plans')
          .insert(plan.toSupabase());

      await loadPlans();

      Get.snackbar(
        'نجح',
        'تم إضافة الخطة الجديدة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SubscriptionController',
        method: 'createPlan',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في إضافة الخطة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  /// Delete a plan
  Future<void> deletePlan(String planId) async {
    isLoading.value = true;
    try {
      await SupabaseService.client
          .from('subscription_plans')
          .delete()
          .eq('id', planId);

      plans.removeWhere((p) => p.id == planId);

      Get.snackbar(
        'نجح',
        'تم حذف الخطة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SubscriptionController',
        method: 'deletePlan',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في حذف الخطة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  /// Update an existing plan
  Future<void> updatePlan(String planId, Map<String, dynamic> updates) async {
    isLoading.value = true;
    try {
      final index = plans.indexWhere((p) => p.id == planId);
      if (index != -1) {
        final old = plans[index];
        final updated = old.copyWith(
          tier: updates['tier'],
          technicalName: updates['technicalName'],
          displayNameAr: updates['displayNameAr'],
          displayNameEn: updates['displayNameEn'],
          price: updates['price'],
          duration: updates['duration'],
          discountPercentage: updates['discountPercentage'],
          maxActiveInvestments: updates['maxActiveInvestments'],
          withdrawalProcessTime: updates['withdrawalProcessTime'],
          status: updates['status'],
          icon: updates['icon'],
          features: updates['features'],
          keywords: updates['keywords'],
        );

        await SupabaseService.client
            .from('subscription_plans')
            .update(updated.toSupabase())
            .eq('id', planId);

        plans[index] = updated;

        Get.snackbar(
          'نجح',
          'تم تحديث بيانات الخطة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SubscriptionController',
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
}
