import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_button.dart';
import '../controllers/investment_controller.dart';
import '../models/investment_model.dart';
import 'edit_investment_plan_screen.dart';

/// Investment Plans Screen
/// Manage investment plans (CRUD)
class InvestmentPlansScreen extends StatelessWidget {
  const InvestmentPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InvestmentController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('خطط الاستثمار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => _showCreatePlanDialog(context, controller),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KasbyColors.primaryGold.withValues(alpha: 0.1),
              ),
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 800)),

          Obx(() {
            if (controller.isLoading.value && controller.plans.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: KasbyColors.primaryGold,
                ),
              );
            }

            if (controller.plans.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.folderOpen,
                      size: 64,
                      color: KasbyColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد خطط استثمار حالياً',
                      style: TextStyle(
                        color: KasbyColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Radiant Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 100, 24, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          KasbyColors.primaryGold.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'باقات الاستثمار والنمو الذكي',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn().slideX(begin: -0.2),
                        const SizedBox(height: 8),
                        const Text(
                          'قم بإدارة وتخصيص باقات الاستثمار المتاحة للمستخدمين',
                          style: TextStyle(
                            fontSize: 14,
                            color: KasbyColors.textSecondary,
                          ),
                        ).animate().fadeIn(
                          delay: const Duration(milliseconds: 200),
                        ),
                      ],
                    ),
                  ),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    itemCount: controller.plans.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plan = controller.plans[index];
                      // Determine tier color based on profit
                      Color tierColor = KasbyColors.glowGold;
                      if (plan.profitPercentage >= 15) {
                        tierColor = const Color(
                          0xFFE5E4E2,
                        ); // Platinum (Silverish)
                      } else if (plan.profitPercentage >= 10) {
                        tierColor = KasbyColors.primaryGold; // Gold
                      } else {
                        tierColor = const Color(0xFFC0C0C0); // Silver
                      }

                      return _buildDazzlingPlanCard(plan, controller, tierColor)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 100 * index))
                          .slideY(begin: 0.1);
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDazzlingPlanCard(
    InvestmentPlan plan,
    InvestmentController controller,
    Color tierColor,
  ) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (plan.imagePath != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow Aura
                    Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: tierColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: const Duration(seconds: 3),
                        ),
                    // Image Container
                    Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                tierColor.withValues(alpha: 0.15),
                                tierColor.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: tierColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            plan.imagePath!,
                            fit: BoxFit.contain,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                          begin: -3,
                          end: 3,
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                        )
                        .shimmer(
                          delay: const Duration(seconds: 3),
                          duration: const Duration(seconds: 2),
                          color: tierColor.withValues(alpha: 0.1),
                        ),
                  ],
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.nameAr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: tierColor,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: tierColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: plan.isActive
                            ? KasbyColors.success.withValues(alpha: 0.1)
                            : KasbyColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: plan.isActive
                              ? KasbyColors.success.withValues(alpha: 0.2)
                              : KasbyColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: plan.isActive
                                  ? KasbyColors.success
                                  : KasbyColors.error,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            plan.isActive ? 'نشط' : 'متوقف',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: plan.isActive
                                  ? KasbyColors.success
                                  : KasbyColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KasbyColors.error.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FontAwesomeIcons.trashCan,
                    color: KasbyColors.error,
                    size: 16,
                  ),
                ),
                onPressed: () =>
                    _confirmDeletePlan(Get.context!, controller, plan),
                tooltip: 'حذف الخطة',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan.descriptionAr,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          if (plan.availableAmounts != null &&
              plan.availableAmounts!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'المبالغ المتاحة للاستثمار:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: KasbyColors.primaryGold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.availableAmounts!.map((amount) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: KasbyColors.primaryGold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '\$${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),

          // Metrics Grid
          Center(
            child: _buildDazzlingMetric(
              icon: FontAwesomeIcons.bolt,
              label: 'العائد المتوقع',
              value: '${plan.profitPercentage}%',
              color: tierColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDazzlingMetric(
                  icon: FontAwesomeIcons.circleArrowDown,
                  label: 'الحد الأدنى للمشاركة',
                  value: '\$${plan.minAmount.toStringAsFixed(0)}',
                  color: KasbyColors.success,
                ),
              ),
              Expanded(
                child: _buildDazzlingMetric(
                  icon: FontAwesomeIcons.circleArrowUp,
                  label: 'الحد الأقصى',
                  value: '\$${plan.maxAmount.toStringAsFixed(0)}',
                  color: KasbyColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: KasbyButton(
              text: 'تحديث إعدادات الباقة',
              onPressed: () =>
                  Get.to(() => EditInvestmentPlanScreen(plan: plan)),
              icon: Icons.edit,
              backgroundColor: tierColor.withValues(alpha: 0.15),
              textColor: tierColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDazzlingMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: KasbyColors.textSecondary,
              ),
            ),
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCreatePlanDialog(
    BuildContext context,
    InvestmentController controller,
  ) {
    final nameArController = TextEditingController();
    final descriptionController = TextEditingController();
    final profitController = TextEditingController();
    final minAmountController = TextEditingController();
    final maxAmountController = TextEditingController();
    final amountsController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'إنشاء خطة جديدة',
          style: TextStyle(color: KasbyColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KasbyTextField(
                controller: nameArController,
                hintText: 'اسم خطة الاستثمار',
                prefixIcon: Icons.title,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: profitController,
                hintText: 'نسبة الربح (%)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.percent,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: minAmountController,
                hintText: 'الحد الأدنى',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: maxAmountController,
                hintText: 'الحد الأقصى',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: KasbyColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              // Parse amounts
              List<double> availableAmounts = [];
              if (amountsController.text.isNotEmpty) {
                availableAmounts = amountsController.text
                    .split(',')
                    .map((e) => double.tryParse(e.trim()) ?? 0)
                    .where((e) => e > 0)
                    .toList();
              }

              controller.createPlan(
                nameAr: nameArController.text,
                descriptionAr: descriptionController.text.isNotEmpty
                    ? descriptionController.text
                    : 'وصف الخطة المقترحة للاستثمار...',
                profitPercentage: double.tryParse(profitController.text) ?? 0,
                minAmount: double.tryParse(minAmountController.text) ?? 0,
                maxAmount: double.tryParse(maxAmountController.text) ?? 0,
                availableAmounts: availableAmounts.isNotEmpty
                    ? availableAmounts
                    : null,
              );
              Get.back();
            },
            child: const Text(
              'إنشاء',
              style: TextStyle(color: KasbyColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlan(
    BuildContext context,
    InvestmentController controller,
    InvestmentPlan plan,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'حذف الخطة',
          style: TextStyle(color: KasbyColors.error),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${plan.nameAr}"؟ سيتم إزالتها من عرض المستخدمين الجدد.',
          style: const TextStyle(color: KasbyColors.textBody),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              controller.deletePlan(plan.id);
              Get.back();
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
