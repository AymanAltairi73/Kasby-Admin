import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/investment_controller.dart';
import '../models/investment_model.dart';

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
                    padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
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
                          'خطط النمو والاستثمار',
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
                        const SizedBox(height: 20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.nameAr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: tierColor,
                      shadows: [
                        Shadow(
                          color: tierColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: plan.isActive
                      ? KasbyColors.success.withValues(alpha: 0.1)
                      : KasbyColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: plan.isActive
                        ? KasbyColors.success
                        : KasbyColors.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: plan.isActive
                                ? KasbyColors.success
                                : KasbyColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: plan.isActive
                                    ? KasbyColors.success
                                    : KasbyColors.error,
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: const Duration(seconds: 2)),
                    const SizedBox(width: 8),
                    Text(
                      plan.isActive ? 'باقة نشطة' : 'معطلة حالياً',
                      style: TextStyle(
                        fontSize: 11,
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
          const SizedBox(height: 12),
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
              label: 'نسبة الربح المتوقعة',
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
                  label: 'الحد الأدنى',
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

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => controller.togglePlanStatus(plan.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: plan.isActive
                            ? KasbyColors.error
                            : KasbyColors.success,
                      ),
                    ),
                  ),
                  child: Text(
                    plan.isActive ? 'تعطيل الخطة' : 'تفعيل الخطة',
                    style: TextStyle(
                      color: plan.isActive
                          ? KasbyColors.error
                          : KasbyColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _showEditPlanDialog(Get.context!, controller, plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tierColor.withValues(alpha: 0.2),
                    foregroundColor: tierColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تعديل البيانات',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
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
              // KasbyTextField(
              //   controller: durationController,
              //   hintText: 'المدة (أيام)',
              //   keyboardType: TextInputType.number,
              //   prefixIcon: Icons.calendar_today,
              // ),
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

  void _showEditPlanDialog(
    BuildContext context,
    InvestmentController controller,
    InvestmentPlan plan,
  ) {
    final nameArController = TextEditingController(text: plan.nameAr);
    final descriptionController = TextEditingController(
      text: plan.descriptionAr,
    );
    final profitController = TextEditingController(
      text: plan.profitPercentage.toString(),
    );
    final minAmountController = TextEditingController(
      text: plan.minAmount.toString(),
    );
    final maxAmountController = TextEditingController(
      text: plan.maxAmount.toString(),
    );
    final amountsController = TextEditingController(
      text: plan.availableAmounts?.join(', ') ?? '',
    );

    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'تعديل الخطة',
          style: TextStyle(color: KasbyColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KasbyTextField(
                controller: nameArController,
                hintText: 'الاسم بالعربية',
                prefixIcon: Icons.title,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: descriptionController,
                hintText: 'وصف الخطة (بالعربية)',
                prefixIcon: Icons.description,
                maxLines: 3,
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
                hintText: 'الحد الأدنى للاستثمار',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: maxAmountController,
                hintText: 'الحد الأقصى للاستثمار',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: amountsController,
                hintText: 'المبالغ المتاحة (مثل: 100, 200, 500)',
                prefixIcon: Icons.list_alt,
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

              controller.updatePlan(plan.id, {
                'nameAr': nameArController.text,
                'descriptionAr': descriptionController.text,
                'profitPercentage': double.tryParse(profitController.text) ?? 0,
                'minAmount': double.tryParse(minAmountController.text) ?? 0,
                'maxAmount': double.tryParse(maxAmountController.text) ?? 0,
                'availableAmounts': availableAmounts.isNotEmpty
                    ? availableAmounts
                    : null,
              });
              Get.back();
            },
            child: const Text(
              'حفظ',
              style: TextStyle(color: KasbyColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }
}
