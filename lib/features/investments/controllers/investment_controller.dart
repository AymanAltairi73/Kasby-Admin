import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
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
    _listenToUserInvestments();
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
            '*, profiles!user_investments_user_id_fkey(full_name), investment_plans!user_investments_plan_id_fkey(name_ar)',
          )
          .order('created_at', ascending: false);

      if (response != null && (response as List).isNotEmpty) {
        debugPrint('[InvestmentController] ℹ️ Raw First Row: ${response[0]}');
      }

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

  // ─── USER INVESTMENTS LISTENER ──────────────────────────
  StreamSubscription? _userInvestmentsSubscription;

  void _listenToUserInvestments() {
    _userInvestmentsSubscription?.cancel();
    _userInvestmentsSubscription = SupabaseService.client
        .from('user_investments')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) async {
          debugPrint('[InvestmentController] ℹ️ User investments updated via stream');
          
          // Re-fetch with joins to ensure names are present (stream doesn't support joins)
          await loadUserInvestments();
        }, onError: (error) {
          debugPrint('[InvestmentController] ❌ Stream error: $error');
        });
  }

  /// Approve a pending investment
  Future<void> approveUserInvestment(String investmentId) async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client.rpc(
        'approve_investment',
        params: {
          'p_investment_id': investmentId,
          'p_admin_id': SupabaseService.userId,
        },
      );

      final result = response;
      if (result is Map && result['success'] == true) {
        Get.snackbar(
          'نجح',
          'تمت الموافقة على الاستثمار وتفعيله',
          backgroundColor: KasbyColors.success.withValues(alpha: 0.1),
          colorText: KasbyColors.success,
        );
      } else {
        // Fallback for void or boolean success
        if (result == true || result == null) {
           Get.snackbar('نجح', 'تمت المعالجة بنجاح');
        } else {
           throw (result is Map ? result['error'] : 'Unknown error') ?? 'فشل الموافقة';
        }
      }
    } catch (e) {
      Get.snackbar('خطأ', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Reject a pending investment
  Future<void> rejectUserInvestment(String investmentId, String reason) async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client.rpc(
        'reject_investment',
        params: {
          'p_investment_id': investmentId,
          'p_admin_id': SupabaseService.userId,
          'p_reason': reason,
        },
      );

      final result = response;
      if (result is Map && result['success'] == true) {
        Get.snackbar(
          'تم الرفض',
          'تم رفض الاستثمار بنجاح',
          backgroundColor: KasbyColors.error.withValues(alpha: 0.1),
          colorText: KasbyColors.error,
        );
      } else {
        if (result == true || result == null) {
           Get.snackbar('نجح', 'تم الرفض بنجاح');
        } else {
           throw (result is Map ? result['error'] : 'Unknown error') ?? 'فشل الرفض';
        }
      }
    } catch (e) {
      Get.snackbar('خطأ', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload plan image to Supabase Storage
  Future<String?> uploadPlanImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final storagePath = 'plan_icons/$fileName';

      await SupabaseService.client.storage
          .from('investment-plans')
          .upload(storagePath, file);

      final imageUrl = SupabaseService.client.storage
          .from('investment-plans')
          .getPublicUrl(storagePath);

      return imageUrl;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'InvestmentController',
        method: 'uploadPlanImage',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Create new plan
  Future<void> createPlan({
    required String nameAr,
    String? nameEn,
    required String descriptionAr,
    required double profitPercentage,
    required double minAmount,
    required double maxAmount,
    List<double>? availableAmounts,
    String? imagePath,
    String? riskLevel,
  }) async {
    isLoading.value = true;
    try {
      await SupabaseService.client.from('investment_plans').insert({
        'name_ar': nameAr,
        'name_en': nameEn,
        'description_ar': descriptionAr,
        'profit_percentage': profitPercentage,
        'min_amount': minAmount,
        'max_amount': maxAmount,
        'available_amounts': availableAmounts,
        'image_url': imagePath,
        'risk_level': riskLevel,
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
      
      // Map Dart keys to Supabase column names
      final mapping = {
        'nameAr': 'name_ar',
        'nameEn': 'name_en',
        'descriptionAr': 'description_ar',
        'profitPercentage': 'profit_percentage',
        'minAmount': 'min_amount',
        'maxAmount': 'max_amount',
        'availableAmounts': 'available_amounts',
        'imagePath': 'image_url',
        'durationDays': 'duration_days',
        'riskLevel': 'risk_level',
        'isActive': 'is_active',
      };

      updates.forEach((key, value) {
        if (mapping.containsKey(key)) {
          var mappedValue = value;
          if (key == 'riskLevel' && value is String) {
            mappedValue = value.toLowerCase();
          }
          supabaseUpdates[mapping[key]!] = mappedValue;
        }
      });

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
      // Actually delete if the user really wants to, but usually we just deactivate.
      // The user requested to confirm operations, so I'll keep it as deactivation for safety 
      // unless it's a new plan without investments.
      
      await SupabaseService.client
          .from('investment_plans')
          .update({'is_active': false})
          .eq('id', planId);

      await loadPlans();

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

  /// Get pending investments
  List<UserInvestment> get pendingInvestments {
    return userInvestments.where((inv) => inv.status == 'pending').toList();
  }

  /// Get completed investments
  List<UserInvestment> get completedInvestments {
    return userInvestments.where((inv) => inv.status == 'matured').toList();
  }

  @override
  void onClose() {
    _userInvestmentsSubscription?.cancel();
    super.onClose();
  }
}
