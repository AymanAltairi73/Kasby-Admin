import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward_model.dart';
import '../../../core/services/audit_logger.dart';

/// Rewards and Gamification Controller
/// Manages settings for daily rewards, spin wheel prizes, and points rules
class RewardsController extends GetxController {
  // Observables
  final rewards = <Reward>[].obs;
  final prizes = <Prize>[].obs;
  final pointsEarnRules = <PointRule>[].obs;
  final pointsRedeemRules = <PointRule>[].obs;
  final isLoading = false.obs;

  static const String _storageKey = 'gamification_settings';

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Load settings from Local Storage
  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedData = prefs.getString(_storageKey);

      if (savedData != null) {
        final Map<String, dynamic> data = jsonDecode(savedData);

        rewards.value = (data['rewards'] as List)
            .map((e) => Reward.fromJson(e))
            .toList();

        prizes.value = (data['prizes'] as List)
            .map((e) => Prize.fromJson(e))
            .toList();

        final allRules = (data['rules'] as List)
            .map((e) => PointRule.fromJson(e))
            .toList();

        pointsEarnRules.value = allRules
            .where((r) => r.type == 'Earn')
            .toList();
        pointsRedeemRules.value = allRules
            .where((r) => r.type == 'Redeem')
            .toList();
      } else {
        _loadDefaultSettings();
        await saveSettings();
      }
    } catch (e) {
      _loadDefaultSettings();
    } finally {
      isLoading.value = false;
    }
  }

  /// Save settings to local storage
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'rewards': rewards.map((e) => e.toJson()).toList(),
      'prizes': prizes.map((e) => e.toJson()).toList(),
      'rules': [
        ...pointsEarnRules.map((e) => e.toJson()),
        ...pointsRedeemRules.map((e) => e.toJson()),
      ],
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// Load initial mock/default settings
  void _loadDefaultSettings() {
    rewards.value = [
      Reward(
        id: 'daily_checkin',
        title: 'مكافأة يومية',
        description: '50 نقطة لكل يوم متتالي',
        points: 50,
        icon: 'calendar-check',
      ),
    ];

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

  /// Update a specific point rule
  Future<void> updatePointRule(PointRule updatedRule) async {
    if (updatedRule.type == 'Earn') {
      final index = pointsEarnRules.indexWhere((r) => r.id == updatedRule.id);
      if (index != -1) pointsEarnRules[index] = updatedRule;
    } else {
      final index = pointsRedeemRules.indexWhere((r) => r.id == updatedRule.id);
      if (index != -1) pointsRedeemRules[index] = updatedRule;
    }

    await saveSettings();
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
      await saveSettings();
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'تعديل قيمة المكافأة',
        details:
            'تم تعديل ${updatedReward.title} إلى ${updatedReward.points} نقطة',
      );
    }
  }

  /// Update spin wheel prize
  Future<void> updatePrize(Prize updatedPrize) async {
    final index = prizes.indexWhere((p) => p.id == updatedPrize.id);
    if (index != -1) {
      prizes[index] = updatedPrize;
      await saveSettings();
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'تعديل جوائز العجلة',
        details: 'تم تعديل جائزة ${updatedPrize.label}',
      );
    }
  }
}
