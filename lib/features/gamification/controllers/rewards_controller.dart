import 'package:get/get.dart';
import '../models/reward_model.dart';
import '../../../core/services/audit_logger.dart';
import '../../../core/services/supabase_service.dart';

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

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Load settings from Supabase
  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      await Future.wait([_loadRewards(), _loadPrizes(), _loadPointRules()]);
    } catch (_) {
      _loadDefaultSettings();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRewards() async {
    try {
      final response = await SupabaseService.client
          .from('gamification_rewards')
          .select()
          .order('created_at', ascending: true);
      if ((response as List).isNotEmpty) {
        rewards.assignAll(
          response.map(
            (e) => Reward(
              id: e['id'].toString(),
              title: e['title'] ?? '',
              description: e['description'] ?? '',
              points: (e['points'] ?? 0).toInt(),
              icon: e['icon'] ?? 'calendar-check',
            ),
          ),
        );
      } else {
        _loadDefaultRewards();
      }
    } catch (_) {
      _loadDefaultRewards();
    }
  }

  Future<void> _loadPrizes() async {
    try {
      final response = await SupabaseService.client
          .from('gamification_prizes')
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
        _loadDefaultPrizes();
      }
    } catch (_) {
      _loadDefaultPrizes();
    }
  }

  Future<void> _loadPointRules() async {
    try {
      final response = await SupabaseService.client
          .from('gamification_point_rules')
          .select()
          .order('created_at', ascending: true);
      if ((response as List).isNotEmpty) {
        final allRules = response
            .map(
              (e) => PointRule(
                id: e['id'].toString(),
                action: e['action'] ?? '',
                points: e['points'] ?? '',
                type: e['type'] ?? 'Earn',
              ),
            )
            .toList();
        pointsEarnRules.assignAll(allRules.where((r) => r.type == 'Earn'));
        pointsRedeemRules.assignAll(allRules.where((r) => r.type == 'Redeem'));
      } else {
        _loadDefaultPointRules();
      }
    } catch (_) {
      _loadDefaultPointRules();
    }
  }

  /// Save settings to Supabase (batch update)
  Future<void> saveSettings() async {
    // Individual updates are handled through CRUD methods
    // This method is kept for backward compatibility with batch operations
  }

  // ─────────── Defaults (fallback) ───────────

  void _loadDefaultSettings() {
    _loadDefaultRewards();
    _loadDefaultPrizes();
    _loadDefaultPointRules();
  }

  void _loadDefaultRewards() {
    rewards.value = [
      Reward(
        id: 'daily_checkin',
        title: 'مكافأة يومية',
        description: '50 نقطة لكل يوم متتالي',
        points: 50,
        icon: 'calendar-check',
      ),
    ];
  }

  void _loadDefaultPrizes() {
    prizes.value = [
      Prize(
        id: '1',
        label: '10 نقاط',
        value: '10',
        type: 'Points',
        probability: 0.4,
      ),
      Prize(
        id: '2',
        label: '25 نقطة',
        value: '25',
        type: 'Points',
        probability: 0.3,
      ),
      Prize(
        id: '3',
        label: '50 نقطة',
        value: '50',
        type: 'Points',
        probability: 0.2,
      ),
      Prize(
        id: '4',
        label: '100 نقطة',
        value: '100',
        type: 'Points',
        probability: 0.08,
      ),
      Prize(
        id: '5',
        label: '\$5 رصيد',
        value: '5',
        type: 'Cash',
        probability: 0.02,
      ),
    ];
  }

  void _loadDefaultPointRules() {
    pointsEarnRules.value = [
      PointRule(
        id: 'e1',
        action: 'تسجيل الدخول اليومي',
        points: '10 نقاط',
        type: 'Earn',
      ),
      PointRule(
        id: 'e2',
        action: 'إحالة صديق',
        points: '100 نقاط',
        type: 'Earn',
      ),
      PointRule(
        id: 'e3',
        action: 'أول استثمار',
        points: '200 نقاط',
        type: 'Earn',
      ),
      PointRule(
        id: 'e4',
        action: 'إكمال الملف الشخصي',
        points: '50 نقاط',
        type: 'Earn',
      ),
    ];

    pointsRedeemRules.value = [
      PointRule(
        id: 'r1',
        action: '1000 نقطة',
        points: '\$10 رصيد',
        type: 'Redeem',
      ),
      PointRule(
        id: 'r2',
        action: '2500 نقطة',
        points: '\$30 رصيد',
        type: 'Redeem',
      ),
      PointRule(
        id: 'r3',
        action: '5000 نقطة',
        points: '\$75 رصيد',
        type: 'Redeem',
      ),
    ];
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
          .from('gamification_point_rules')
          .update({'action': updatedRule.action, 'points': updatedRule.points})
          .eq('id', updatedRule.id);
    } catch (_) {}

    await AuditLogger.log(
      adminName: 'Admin',
      action: 'تعديل قواعد النقاط',
      details:
          'تم تعديل قاعدة: ${updatedRule.action} إلى ${updatedRule.points}',
    );
  }

  /// Update daily reward
  Future<void> updateReward(Reward updatedReward) async {
    final index = rewards.indexWhere((r) => r.id == updatedReward.id);
    if (index != -1) {
      rewards[index] = updatedReward;
      try {
        await SupabaseService.client
            .from('gamification_rewards')
            .update({
              'title': updatedReward.title,
              'description': updatedReward.description,
              'points': updatedReward.points,
            })
            .eq('id', updatedReward.id);
      } catch (_) {}
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'تعديل قيمة المكافأة',
        details:
            'تم تعديل ${updatedReward.title} إلى ${updatedReward.points} نقطة',
      );
    }
  }

  /// Update prize on the wheel
  Future<void> updatePrize(Prize updatedPrize) async {
    final index = prizes.indexWhere((p) => p.id == updatedPrize.id);
    if (index != -1) {
      prizes[index] = updatedPrize;
      try {
        await SupabaseService.client
            .from('gamification_prizes')
            .update({
              'label': updatedPrize.label,
              'value': updatedPrize.value,
              'type': updatedPrize.type,
              'probability': updatedPrize.probability,
            })
            .eq('id', updatedPrize.id);
      } catch (_) {}
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'تعديل جوائز العجلة',
        details: 'تم تعديل جائزة ${updatedPrize.label}',
      );
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

    await AuditLogger.log(
      adminName: 'Admin',
      action: 'تحديث شامل لإعدادات المكافآت',
      details: 'تم تحديث قيم المكافآت، الجوائز وقواعد النقاط.',
    );

    isLoading.value = false;
  }
}
