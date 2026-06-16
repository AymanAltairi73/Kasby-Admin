import 'package:get/get.dart';
import '../models/reward_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

/// Rewards and Gamification Controller
/// Manages settings for daily rewards, spin wheel prizes, and points rules
/// All data stored in Supabase — Single Source of Truth
class RewardsController extends GetxController {
  // Observables
  final rewards = <Reward>[].obs;
  final prizes = <Prize>[].obs;
  final pointsEarnRules = <PointRule>[].obs;
  final pointsRedeemRules = <PointRule>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final totalKspBalance = 0.0.obs;
  final totalKspEarned = 0.0.obs;
  final usersWithPoints = 0.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'RewardsController',
      method: 'onInit',
      feature: 'Gamification',
      status: 'INFO',
    );
    super.onInit();
    loadSettings();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'RewardsController',
      method: 'onClose',
      feature: 'Gamification',
      status: 'INFO',
    );
    super.onClose();
  }

  /// Load settings from Supabase
  Future<void> loadSettings() async {
    AppLoggerService.debugTrace(
      className: 'RewardsController',
      method: 'loadSettings',
      feature: 'Gamification',
      status: 'INFO',
    );
    isLoading.value = true;
    hasError.value = false;
    try {
      await Future.wait([
        _loadRewards(),
        _loadPrizes(),
        _loadPointRules(),
        _loadLoyaltyStats(),
      ]);
    } catch (e) {
      hasError.value = true;
      Get.snackbar('خطأ', 'فشل تحميل إعدادات المكافآت');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLoyaltyStats() async {
    try {
      final response = await SupabaseService.client
          .from('user_points')
          .select('current_balance, total_earned');

      double balance = 0;
      double earned = 0;
      for (final row in response as List) {
        balance += (row['current_balance'] as num? ?? 0).toDouble();
        earned += (row['total_earned'] as num? ?? 0).toDouble();
      }

      totalKspBalance.value = balance;
      totalKspEarned.value = earned;
      usersWithPoints.value = (response as List).length;
    } catch (_) {
      totalKspBalance.value = 0;
      totalKspEarned.value = 0;
      usersWithPoints.value = 0;
    }
  }

  Future<void> _loadRewards() async {
    try {
      final response = await SupabaseService.client
          .from('rewards')
          .select()
          .order('created_at', ascending: true);
      if ((response as List).isNotEmpty) {
        rewards.assignAll(
          response.map(
            (e) => Reward(
              id: e['id'].toString(),
              title: e['title'] ?? '',
              description: e['description'] ?? '',
              points: (e['points_cost'] ?? 0).toInt(),
              icon: e['icon'] ?? 'calendar-check',
            ),
          ),
        );
      } else {
        rewards.clear();
      }
    } catch (e) {
      rewards.clear();
      Get.snackbar('خطأ', 'فشل تحميل المكافآت');
    }
  }

  Future<void> _loadPrizes() async {
    try {
      final response = await SupabaseService.client
          .from('prizes')
          .select()
          .order('created_at', ascending: true);
      if ((response as List).isNotEmpty) {
        prizes.assignAll(
          response.map(
            (e) => Prize(
              id: e['id'].toString(),
              label: e['label'] ?? '',
              value: e['value'] ?? '',
              type: e['type'] ?? 'Points',
              probability: (e['probability'] ?? 0.0).toDouble(),
            ),
          ),
        );
      } else {
        prizes.clear();
      }
    } catch (e) {
      prizes.clear();
      Get.snackbar('خطأ', 'فشل تحميل الجوائز');
    }
  }

  Future<void> _loadPointRules() async {
    try {
      final response = await SupabaseService.client
          .from('point_rules')
          .select()
          .order('created_at', ascending: true);
      if ((response as List).isNotEmpty) {
        final allRules = response
            .map(
              (e) => PointRule(
                id: e['id'].toString(),
                action: e['action'] ?? '',
                points: e['points'] is int
                    ? e['points']
                    : int.tryParse(e['points']?.toString() ?? '0') ?? 0,
                type: e['type'] ?? 'Earn',
              ),
            )
            .toList();
        pointsEarnRules.assignAll(allRules.where((r) => r.type == 'Earn'));
        pointsRedeemRules.assignAll(allRules.where((r) => r.type == 'Redeem'));
      } else {
        pointsEarnRules.clear();
        pointsRedeemRules.clear();
      }
    } catch (e) {
      pointsEarnRules.clear();
      pointsRedeemRules.clear();
      Get.snackbar('خطأ', 'فشل تحميل قواعد النقاط');
    }
  }

  /// Save settings to Supabase (batch update)
  Future<void> saveSettings() async {
    // Individual updates are handled through CRUD methods
  }

  // ─────────── CRUD → Supabase ───────────

  /// Update a specific point rule
  Future<void> updatePointRule(PointRule updatedRule) async {
    if (updatedRule.type == 'Earn') {
      final index = pointsEarnRules.indexWhere((r) => r.id == updatedRule.id);
      if (index != -1) pointsEarnRules[index] = updatedRule;
    } else {
      final index = pointsRedeemRules.indexWhere((r) => r.id == updatedRule.id);
      if (index != -1) pointsRedeemRules[index] = updatedRule;
    }

    try {
      await SupabaseService.client
          .from('point_rules')
          .update({'action': updatedRule.action, 'points': updatedRule.points})
          .eq('id', updatedRule.id)
          .select('id');

      Get.snackbar('تم', 'تم تحديث قاعدة KSP');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث قاعدة KSP');
    }
  }

  /// Update daily reward
  Future<void> updateReward(Reward updatedReward) async {
    final index = rewards.indexWhere((r) => r.id == updatedReward.id);
    if (index != -1) {
      rewards[index] = updatedReward;
      try {
        await SupabaseService.client
            .from('rewards')
            .update({
              'title': updatedReward.title,
              'description': updatedReward.description,
              'points_cost': updatedReward.points,
            })
            .eq('id', updatedReward.id)
            .select('id');
        Get.snackbar('تم', 'تم تحديث المكافأة');
      } catch (e) {
        Get.snackbar('خطأ', 'فشل تحديث المكافأة');
      }
    }
  }

  /// Update prize on the wheel
  Future<void> updatePrize(Prize updatedPrize) async {
    final index = prizes.indexWhere((p) => p.id == updatedPrize.id);
    if (index != -1) {
      prizes[index] = updatedPrize;
      try {
        await SupabaseService.client
            .from('prizes')
            .update({
              'label': updatedPrize.label,
              'value': updatedPrize.value,
              'type': updatedPrize.type,
              'probability': updatedPrize.probability,
            })
            .eq('id', updatedPrize.id)
            .select('id');
        Get.snackbar('تم', 'تم تحديث الجائزة');
      } catch (e) {
        Get.snackbar('خطأ', 'فشل تحديث الجائزة');
      }
    }
  }

  /// Update all settings at once (Batch)
  Future<void> updateAllSettings({
    required List<Reward> updatedRewards,
    required List<Prize> updatedPrizes,
    required List<PointRule> updatedEarnRules,
    required List<PointRule> updatedRedeemRules,
  }) async {
    isLoading.value = true;

    rewards.assignAll(updatedRewards);
    prizes.assignAll(updatedPrizes);
    pointsEarnRules.assignAll(updatedEarnRules);
    pointsRedeemRules.assignAll(updatedRedeemRules);

    // Batch update each to Supabase
    for (final r in updatedRewards) {
      await updateReward(r);
    }
    for (final p in updatedPrizes) {
      await updatePrize(p);
    }
    for (final rule in [...updatedEarnRules, ...updatedRedeemRules]) {
      await updatePointRule(rule);
    }

    isLoading.value = false;
  }
}
