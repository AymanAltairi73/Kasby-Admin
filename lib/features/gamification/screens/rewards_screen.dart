import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_dialog.dart';
import '../controllers/rewards_controller.dart';
import '../models/reward_model.dart';

/// Rewards Screen
/// Manage daily rewards, spin wheel, and points system
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RewardsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('المكافآت والنقاط')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Check-in
              const Text(
                'تسجيل الحضور اليومي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KasbyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...controller.rewards.map(
                (reward) => KasbyCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: KasbyColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              reward.icon == 'calendar-check'
                                  ? FontAwesomeIcons.calendarCheck
                                  : FontAwesomeIcons.gift,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: KasbyColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${reward.points} نقطة لكل يوم متتالي',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: KasbyColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'المستخدمون النشطون اليوم',
                              '1,234',
                              FontAwesomeIcons.users,
                              KasbyColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'إجمالي النقاط الموزعة',
                              '61,700',
                              FontAwesomeIcons.coins,
                              KasbyColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Spin Wheel
              const Text(
                'عجلة الحظ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KasbyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              KasbyCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                KasbyColors.primaryGold,
                                KasbyColors.success,
                                KasbyColors.info,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            FontAwesomeIcons.dharmachakra,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'عجلة الحظ اليومية',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: KasbyColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'فرصة واحدة يومياً للفوز',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: KasbyColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'الجوائز المتاحة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.prizes.map((prize) {
                        return _buildPrizeChip(
                          prize.label,
                          prize.type == 'Cash'
                              ? KasbyColors.error
                              : KasbyColors.primaryGold,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'المشاركون اليوم',
                            '856',
                            FontAwesomeIcons.userGroup,
                            KasbyColors.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'إجمالي الجوائز',
                            '\$425',
                            FontAwesomeIcons.gift,
                            KasbyColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Points System
              const Text(
                'نظام النقاط',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KasbyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              KasbyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'طرق كسب النقاط',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...controller.pointsEarnRules.map(
                      (rule) => Column(
                        children: [
                          _buildPointsRule(rule.action, rule.points),
                          if (controller.pointsEarnRules.last != rule)
                            const Divider(color: KasbyColors.background),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'استبدال النقاط',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...controller.pointsRedeemRules.map(
                      (rule) => Column(
                        children: [
                          _buildPointsRule(rule.action, rule.points),
                          if (controller.pointsRedeemRules.last != rule)
                            const Divider(color: KasbyColors.background),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Configuration Button
              KasbyButton(
                text: 'إعدادات المكافآت',
                onPressed: () => _showEditRewardsDialog(context, controller),
                icon: FontAwesomeIcons.gear,
                isOutlined: true,
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Dialog to edit reward values, prizes, and rules
  void _showEditRewardsDialog(
    BuildContext context,
    RewardsController controller,
  ) {
    // Local state for the dialog
    final localRewards = List<Reward>.from(controller.rewards);
    final localPrizes = List<Prize>.from(controller.prizes);
    final localEarnRules = List<PointRule>.from(controller.pointsEarnRules);
    final localRedeemRules = List<PointRule>.from(controller.pointsRedeemRules);

    Get.dialog(
      KasbyDialog(
        title: 'تعديل قيم المكافآت',
        actions: [
          KasbyButton(
            text: 'إلغاء',
            onPressed: () => Get.back(),
            isOutlined: true,
            width: 100,
          ),
          const SizedBox(width: 12),
          KasbyButton(
            text: 'حفظ التعديلات',
            onPressed: () async {
              await controller.updateAllSettings(
                updatedRewards: localRewards,
                updatedPrizes: localPrizes,
                updatedEarnRules: localEarnRules,
                updatedRedeemRules: localRedeemRules,
              );
              Get.back();
              Get.snackbar('نجح', 'تم حفظ التعديلات بنجاح');
            },
            width: 150,
          ),
        ],
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Daily Rewards Section ---
              _buildSectionTitle('المكافآت اليومية'),
              ...localRewards.map((Reward reward) {
                final pointsController = TextEditingController(
                  text: reward.points.toString(),
                );
                return _buildEditField(
                  label: reward.title,
                  controller: pointsController,
                  onSave: (val) {
                    final points = int.tryParse(val) ?? reward.points;
                    final index = localRewards.indexOf(reward);
                    localRewards[index] = reward.copyWith(points: points);
                  },
                );
              }),

              const SizedBox(height: 20),
              // --- Point Rules Section ---
              _buildSectionTitle('قواعد كسب النقاط'),
              ...localEarnRules.map((PointRule rule) {
                final valController = TextEditingController(text: rule.points);
                return _buildEditField(
                  label: rule.action,
                  controller: valController,
                  onSave: (val) {
                    final index = localEarnRules.indexOf(rule);
                    localEarnRules[index] = rule.copyWith(points: val);
                  },
                );
              }),

              const SizedBox(height: 20),
              // --- Point Redemption Section ---
              _buildSectionTitle('قواعد استبدال النقاط'),
              ...localRedeemRules.map((PointRule rule) {
                final valController = TextEditingController(text: rule.points);
                return _buildEditField(
                  label: rule.action,
                  controller: valController,
                  onSave: (val) {
                    final index = localRedeemRules.indexOf(rule);
                    localRedeemRules[index] = rule.copyWith(points: val);
                  },
                );
              }),

              const SizedBox(height: 20),
              // --- Spin Wheel Section ---
              _buildSectionTitle('جوائز عجلة الحظ'),
              ...localPrizes.map((Prize prize) {
                final valController = TextEditingController(text: prize.label);
                return _buildEditField(
                  label: 'الجائزة ${prize.id}',
                  controller: valController,
                  onSave: (val) {
                    final index = localPrizes.indexOf(prize);
                    localPrizes[index] = prize.copyWith(label: val);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: KasbyColors.primaryGold,
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required Function(String) onSave,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: KasbyTextField(
              controller: controller,
              hintText: 'القيمة',
              onChanged: onSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: KasbyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPointsRule(String action, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action,
            style: const TextStyle(fontSize: 14, color: KasbyColors.textBody),
          ),
          Text(
            points,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: KasbyColors.primaryGold,
            ),
          ),
        ],
      ),
    );
  }
}
