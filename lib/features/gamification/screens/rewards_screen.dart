import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/admin_metric_chip.dart';
import '../controllers/rewards_controller.dart';
import '../models/reward_model.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available
    final controller = Get.isRegistered<RewardsController>() 
        ? Get.find<RewardsController>() 
        : Get.put(RewardsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('المكافآت والولاء'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadSettings(),
        color: KasbyColors.primaryGold,
        child: Obx(() {
          if (controller.isLoading.value && controller.rewards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AdminMetricChip(
                      label: 'KSP متداول',
                      value: controller.totalKspBalance.value.toStringAsFixed(0),
                      color: KasbyColors.primaryGold,
                      icon: FontAwesomeIcons.coins,
                    ),
                    const SizedBox(width: 10),
                    AdminMetricChip(
                      label: 'KSP مكتسب',
                      value: controller.totalKspEarned.value.toStringAsFixed(0),
                      color: KasbyColors.success,
                      icon: FontAwesomeIcons.arrowTrendUp,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AdminMetricChip(
                      label: 'مستخدمون',
                      value: '${controller.usersWithPoints.value}',
                      color: KasbyColors.info,
                      icon: FontAwesomeIcons.users,
                    ),
                    const SizedBox(width: 10),
                    AdminMetricChip(
                      label: 'مكافآت / جوائز',
                      value: '${controller.rewards.length}/${controller.prizes.length}',
                      color: KasbyColors.warning,
                      icon: FontAwesomeIcons.gift,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('المكافآت اليومية', FontAwesomeIcons.gift),
                const SizedBox(height: 12),
                _buildRewardsList(controller),
                const SizedBox(height: 24),
                _buildSectionHeader('جوائز عجلة الحظ', FontAwesomeIcons.dharmachakra),
                const SizedBox(height: 12),
                _buildPrizesList(controller),
                const SizedBox(height: 24),
                _buildSectionHeader('قواعد كسب KSP', FontAwesomeIcons.coins),
                const SizedBox(height: 12),
                _buildRulesList(controller, controller.pointsEarnRules, 'كسب'),
                const SizedBox(height: 24),
                _buildSectionHeader('قواعد استبدال KSP', FontAwesomeIcons.handHoldingHeart),
                const SizedBox(height: 12),
                _buildRulesList(controller, controller.pointsRedeemRules, 'استبدال'),
                const SizedBox(height: 40),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: KasbyColors.primaryGold),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsList(RewardsController controller) {
    if (controller.rewards.isEmpty) {
      return const KasbyGlassCard(
        child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد مكافآت مسجلة', style: TextStyle(color: KasbyColors.textSecondary)))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.rewards.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final reward = controller.rewards[index];
        return KasbyGlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(reward.icon),
                  color: KasbyColors.primaryGold,
                  size: 20,
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
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      reward.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KasbyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${reward.points} KSP',
                style: const TextStyle(
                  color: KasbyColors.primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: KasbyColors.info),
                onPressed: () => _showEditRewardDialog(context, controller, reward),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrizesList(RewardsController controller) {
    if (controller.prizes.isEmpty) {
      return const KasbyGlassCard(
        child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد جوائز مسجلة', style: TextStyle(color: KasbyColors.textSecondary)))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.prizes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final prize = controller.prizes[index];
        return KasbyGlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                prize.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _buildTypeBadge(prize.type),
              const SizedBox(width: 16),
              Text(
                '${(prize.probability * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: KasbyColors.textSecondary),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: KasbyColors.info),
                onPressed: () => _showEditPrizeDialog(context, controller, prize),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRulesList(RewardsController controller, List<PointRule> rules, String typeLabel) {
    if (rules.isEmpty) {
      return const KasbyGlassCard(
        child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد قواعد مسجلة', style: TextStyle(color: KasbyColors.textSecondary)))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final rule = rules[index];
        return KasbyGlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rule.action,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Text(
                '${rule.points} KSP',
                style: const TextStyle(
                  color: KasbyColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: KasbyColors.info),
                onPressed: () => _showEditRuleDialog(context, controller, rule),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color = KasbyColors.info;
    if (type == 'Cash') color = KasbyColors.success;
    if (type == 'Points') color = KasbyColors.primaryGold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        type,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'calendar-check':
        return FontAwesomeIcons.calendarCheck;
      case 'star':
        return FontAwesomeIcons.star;
      case 'gift':
        return FontAwesomeIcons.gift;
      default:
        return FontAwesomeIcons.award;
    }
  }

  void _showEditRewardDialog(BuildContext context, RewardsController controller, Reward reward) {
    final titleController = TextEditingController(text: reward.title);
    final descController = TextEditingController(text: reward.description);
    final pointsController = TextEditingController(text: reward.points.toString());

    Get.dialog(
      _buildDialog(
        title: 'تعديل المكافأة',
        content: Column(
          children: [
            KasbyTextField(controller: titleController, labelText: 'العنوان'),
            const SizedBox(height: 12),
            KasbyTextField(controller: descController, labelText: 'الوصف'),
            const SizedBox(height: 12),
            KasbyTextField(
              controller: pointsController,
              labelText: 'الـ KSP',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        onConfirm: () {
          controller.updateReward(
            reward.copyWith(
              title: titleController.text,
              description: descController.text,
              points: int.tryParse(pointsController.text) ?? reward.points,
            ),
          );
          Get.back();
        },
      ),
    );
  }

  void _showEditPrizeDialog(BuildContext context, RewardsController controller, Prize prize) {
    final labelController = TextEditingController(text: prize.label);
    final valueController = TextEditingController(text: prize.value);
    final probController = TextEditingController(text: prize.probability.toString());

    Get.dialog(
      _buildDialog(
        title: 'تعديل الجائزة',
        content: Column(
          children: [
            KasbyTextField(controller: labelController, labelText: 'المسمى'),
            const SizedBox(height: 12),
            KasbyTextField(controller: valueController, labelText: 'القيمة'),
            const SizedBox(height: 12),
            KasbyTextField(
              controller: probController,
              labelText: 'الاحتمالية (0.01 - 1.0)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        onConfirm: () {
          controller.updatePrize(
            prize.copyWith(
              label: labelController.text,
              value: valueController.text,
              probability: double.tryParse(probController.text) ?? prize.probability,
            ),
          );
          Get.back();
        },
      ),
    );
  }

  void _showEditRuleDialog(BuildContext context, RewardsController controller, PointRule rule) {
    final pointsController = TextEditingController(text: rule.points.toString());

    Get.dialog(
      _buildDialog(
        title: 'تعديل قاعدة KSP',
        content: Column(
          children: [
            Text(rule.action, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            KasbyTextField(
              controller: pointsController,
              labelText: 'الـ KSP',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        onConfirm: () {
          controller.updatePointRule(
            rule.copyWith(points: int.tryParse(pointsController.text) ?? rule.points),
          );
          Get.back();
        },
      ),
    );
  }

  Widget _buildDialog({
    required String title,
    required Widget content,
    required VoidCallback onConfirm,
  }) {
    return Dialog(
      backgroundColor: KasbyColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KasbyButton(text: 'حفظ', onPressed: onConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
