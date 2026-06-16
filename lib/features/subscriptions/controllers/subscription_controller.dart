import 'dart:async';
import 'package:get/get.dart';
import '../models/subscription_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

/// Subscription Controller — manages subscription plans from Supabase
class SubscriptionController extends GetxController {
  final plans = <SubscriptionPlan>[].obs;
  final isLoading = false.obs;
  StreamSubscription? _plansSubscription;
  Timer? _reloadDebounce;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'SubscriptionController',
      method: 'onInit',
      feature: 'Subscriptions',
      status: 'INFO',
    );
    super.onInit();
    loadPlans();
    _listenToPlans();
  }

  void _listenToPlans() {
    _plansSubscription?.cancel();
    _plansSubscription = SupabaseService.client
        .from('subscription_plans')
        .stream(primaryKey: ['id'])
        .listen((_) {
          _reloadDebounce?.cancel();
          _reloadDebounce = Timer(const Duration(milliseconds: 750), loadPlans);
        }, onError: (_) {});
  }

  @override
  void onClose() {
    _plansSubscription?.cancel();
    _reloadDebounce?.cancel();
    AppLoggerService.debugTrace(
      className: 'SubscriptionController',
      method: 'onClose',
      feature: 'Subscriptions',
      status: 'INFO',
    );
    super.onClose();
  }

  /// Load plans from Supabase, fallback to defaults if no data
  Future<void> loadPlans() async {
    AppLoggerService.debugTrace(
      className: 'SubscriptionController',
      method: 'loadPlans',
      feature: 'Subscriptions',
      status: 'INFO',
    );
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
        plans.clear();
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SubscriptionController',
        method: 'loadPlans',
        error: e,
        stackTrace: stackTrace,
      );
      plans.clear();
      Get.snackbar('خطأ', 'فشل تحميل خطط الاشتراك');
    }
    isLoading.value = false;
  }

  /// Add a new plan
  Future<bool> createPlan(SubscriptionPlan plan) async {
    AppLoggerService.debugTrace(
      className: 'SubscriptionController',
      method: 'createPlan',
      feature: 'Subscriptions',
      status: 'INFO',
      params: {'planName': plan.displayNameAr},
    );
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
      isLoading.value = false;
      return true;
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
      isLoading.value = false;
      return false;
    }
  }

  /// Delete a plan
  Future<bool> deletePlan(String planId) async {
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
      isLoading.value = false;
      return true;
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
      isLoading.value = false;
      return false;
    }
  }

  /// Update an existing plan
  Future<bool> updatePlan(String planId, Map<String, dynamic> updates) async {
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
        isLoading.value = false;
        return true;
      }
      isLoading.value = false;
      return false;
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
      isLoading.value = false;
      return false;
    }
  }
}
