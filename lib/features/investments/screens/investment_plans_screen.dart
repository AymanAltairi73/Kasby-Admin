import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_button.dart';
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
      appBar: AppBar(
        title: const Text('خطط الاستثمار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlanDialog(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.plans.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: KasbyColors.primaryGold),
          );
        }

        if (controller.plans.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد خطط استثمار',
              style: TextStyle(color: KasbyColors.textSecondary, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.plans.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final plan = controller.plans[index];
            return _buildPlanCard(plan, controller);
          },
        );
      }),
    );
  }

  Widget _buildPlanCard(InvestmentPlan plan, InvestmentController controller) {
    return KasbyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.nameAr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: KasbyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: plan.isActive
                      ? KasbyColors.success.withOpacity(0.2)
                      : KasbyColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan.isActive ? 'نشط' : 'معطل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: plan.isActive
                        ? KasbyColors.success
                        : KasbyColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.percent,
                  label: 'نسبة الربح',
                  value: '${plan.profitPercentage}%',
                  color: KasbyColors.primaryGold,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.clock,
                  label: 'المدة',
                  value: '${plan.durationDays} يوم',
                  color: KasbyColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.arrowDown,
                  label: 'الحد الأدنى',
                  value: '\$${plan.minAmount.toStringAsFixed(0)}',
                  color: KasbyColors.success,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.arrowUp,
                  label: 'الحد الأقصى',
                  value: '\$${plan.maxAmount.toStringAsFixed(0)}',
                  color: KasbyColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: KasbyButton(
                  text: plan.isActive ? 'تعطيل' : 'تفعيل',
                  onPressed: () => controller.togglePlanStatus(plan.id),
                  isOutlined: true,
                  height: 40,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KasbyButton(
                  text: 'تعديل',
                  onPressed: () =>
                      _showEditPlanDialog(Get.context!, controller, plan),
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: KasbyColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _showCreatePlanDialog(
    BuildContext context,
    InvestmentController controller,
  ) {
    final nameController = TextEditingController();
    final nameArController = TextEditingController();
    final profitController = TextEditingController();
    final durationController = TextEditingController();
    final minAmountController = TextEditingController();
    final maxAmountController = TextEditingController();

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
                hintText: 'الاسم بالعربية',
                prefixIcon: Icons.title,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: nameController,
                hintText: 'الاسم بالإنجليزية',
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
                controller: durationController,
                hintText: 'المدة (أيام)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_today,
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
              controller.createPlan(
                name: nameController.text,
                nameAr: nameArController.text,
                profitPercentage: double.tryParse(profitController.text) ?? 0,
                durationDays: int.tryParse(durationController.text) ?? 0,
                minAmount: double.tryParse(minAmountController.text) ?? 0,
                maxAmount: double.tryParse(maxAmountController.text) ?? 0,
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
    final nameController = TextEditingController(text: plan.name);
    final nameArController = TextEditingController(text: plan.nameAr);
    final profitController = TextEditingController(
      text: plan.profitPercentage.toString(),
    );
    final durationController = TextEditingController(
      text: plan.durationDays.toString(),
    );
    final minAmountController = TextEditingController(
      text: plan.minAmount.toString(),
    );
    final maxAmountController = TextEditingController(
      text: plan.maxAmount.toString(),
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
                controller: nameController,
                hintText: 'الاسم بالإنجليزية',
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
                controller: durationController,
                hintText: 'المدة (أيام)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_today,
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
              controller.updatePlan(plan.id, {
                'name': nameController.text,
                'nameAr': nameArController.text,
                'profitPercentage': double.tryParse(profitController.text) ?? 0,
                'durationDays': int.tryParse(durationController.text) ?? 0,
                'minAmount': double.tryParse(minAmountController.text) ?? 0,
                'maxAmount': double.tryParse(maxAmountController.text) ?? 0,
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
