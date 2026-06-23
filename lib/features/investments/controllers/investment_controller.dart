import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/permission_service.dart';
import '../models/investment_model.dart';
import '../../notifications/controllers/notification_controller.dart';

/// Investment Controller — manages investment plans & user investments from Supabase
class InvestmentController extends GetxController {
  final plans = <InvestmentPlan>[].obs;
  final userInvestments = <UserInvestment>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'InvestmentController',
      method: 'onInit',
      feature: 'Investments',
      status: 'INFO',
    );
    super.onInit();
    loadPlans();
    loadUserInvestments();
    _listenToUserInvestments();
  }

  /// Load investment plans from Supabase
  Future<void> loadPlans() async {
    AppLoggerService.debugTrace(
      className: 'InvestmentController',
      method: 'loadPlans',
      feature: 'Investments',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('investment_plans')
          .select()
          .order('created_at', ascending: false);

      plans.assignAll(
        (response as List?)?.map((e) => InvestmentPlan.fromSupabase(e)).toList() ?? [],
      );

      AppLoggerService.debugTrace(
        className: 'InvestmentController',
        method: 'loadPlans',
        feature: 'Investments',
        status: 'SUCCESS',
        params: {'count': plans.length},
      );
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'InvestmentController',
        method: 'loadPlans',
        feature: 'Investments',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
      AppLoggerService.logError(
        controller: 'InvestmentController',
        method: 'loadPlans',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل خطط الاستثمار: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  /// Load user investments from Supabase
  Future<void> loadUserInvestments() async {
    AppLoggerService.debugTrace(
      className: 'InvestmentController',
      method: 'loadUserInvestments',
      feature: 'Investments',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('user_investments')
          .select('''
            *,
            profiles!user_investments_user_id_fkey(
              full_name,
              email,
              phone
            ),
            investment_plans!user_investments_plan_id_fkey(
              name_ar,
              name_en,
              profit_percentage,
              duration_days
            )
          ''')
          .order('created_at', ascending: false);

      userInvestments.assignAll(
        (response as List?)?.map((e) => UserInvestment.fromSupabase(e)).toList() ?? [],
      );

      AppLoggerService.debugTrace(
        className: 'InvestmentController',
        method: 'loadUserInvestments',
        feature: 'Investments',
        status: 'SUCCESS',
        params: {'count': userInvestments.length},
      );
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'InvestmentController',
        method: 'loadUserInvestments',
        feature: 'Investments',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
      AppLoggerService.logError(
        controller: 'InvestmentController',
        method: 'loadUserInvestments',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل استثمارات المستخدمين: ${e.toString()}',
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
          AppLoggerService.debugTrace(
            className: 'InvestmentController',
            method: '_listenToUserInvestments',
            feature: 'Investments',
            status: 'INFO',
            message: 'User investments stream update',
          );
          await loadUserInvestments();
        }, onError: (error) {
          AppLoggerService.debugTrace(
            className: 'InvestmentController',
            method: '_listenToUserInvestments',
            feature: 'Investments',
            status: 'FAILED',
            error: error,
          );
        });
  }

  /// Approve a pending investment
  Future<void> approveUserInvestment(String investmentId) async {
    final permService = Get.find<PermissionService>();
    if (!permService.canApproveFinancials) {
      Get.snackbar('صلاحيات غير كافية', 'لا تملك صلاحية الموافقة على الاستثمارات',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

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
        await AppLoggerService.logActivity(
          action: 'admin_approve_investment',
          entityType: 'user_investment',
          entityId: investmentId,
        );

        // Find investment to get userId
        final inv = userInvestments.firstWhereOrNull((i) => i.id == investmentId);
        if (inv != null) {
          Get.find<NotificationController>().sendNotification(
            '🌟 استثمار مفعل',
            'تمت الموافقة على خطة الاستثمار "${inv.planName}" وهي الآن مفعلة وتحقق لك الأرباح.',
            'specific',
            specificUserId: inv.userId,
          );
        }

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
    final permService = Get.find<PermissionService>();
    if (!permService.canApproveFinancials) {
      Get.snackbar('صلاحيات غير كافية', 'لا تملك صلاحية رفض الاستثمارات',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

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
        await AppLoggerService.logActivity(
          action: 'admin_reject_investment',
          entityType: 'user_investment',
          entityId: investmentId,
          details: {'reason': reason},
        );

        // Find investment to get userId
        final inv = userInvestments.firstWhereOrNull((i) => i.id == investmentId);
        if (inv != null) {
          Get.find<NotificationController>().sendNotification(
            '⚠️ رفض الاستثمار',
            'تم رفض طلب الاستثمار الخاص بك. السبب: $reason',
            'specific',
            specificUserId: inv.userId,
          );
        }

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

  /// Soft-delete or hard-delete plan depending on linked investments
  Future<bool> deletePlan(String planId) async {
    isLoading.value = true;
    try {
      final linked = await SupabaseService.client
          .from('user_investments')
          .select('id')
          .eq('plan_id', planId)
          .limit(1);

      final hasInvestments = (linked as List).isNotEmpty;
      List<dynamic> result;

      if (hasInvestments) {
        result = await SupabaseService.client
            .from('investment_plans')
            .update({'is_active': false})
            .eq('id', planId)
            .select('id');
      } else {
        result = await SupabaseService.client
            .from('investment_plans')
            .delete()
            .eq('id', planId)
            .select('id');
      }

      if (result.isEmpty) {
        throw Exception('No rows affected — check permissions');
      }

      plans.removeWhere((p) => p.id == planId);
      await loadPlans();

      Get.snackbar(
        'نجح',
        hasInvestments
            ? 'تم إيقاف الخطة (مرتبطة باستثمارات)'
            : 'تم حذف الخطة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.success.withValues(alpha: 0.15),
        colorText: KasbyColors.success,
      );
      return true;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'InvestmentController',
        method: 'deletePlan',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في حذف الخطة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  List<InvestmentPlan> get activePlans =>
      plans.where((p) => p.isActive).toList();

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

  /// Get rejected/cancelled investments
  List<UserInvestment> get rejectedInvestments {
    return userInvestments
        .where((inv) => inv.status == 'cancelled' || inv.status == 'rejected')
        .toList();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'InvestmentController',
      method: 'onClose',
      feature: 'Investments',
      status: 'INFO',
    );
    _userInvestmentsSubscription?.cancel();
    super.onClose();
  }
}
