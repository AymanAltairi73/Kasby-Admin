import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../models/investment_model.dart';
import '../controllers/investment_controller.dart';
import 'edit_investment_plan_screen.dart';

class InvestmentPlanDetailScreen extends StatelessWidget {
  final InvestmentPlan plan;

  const InvestmentPlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvestmentController>();
    
    // Determine tier color based on profit
    Color tierColor = KasbyColors.glowGold;
    if (plan.profitPercentage >= 15) {
      tierColor = const Color(0xFFE5E4E2); // Platinum
    } else if (plan.profitPercentage >= 10) {
      tierColor = KasbyColors.primaryGold; // Gold
    } else {
      tierColor = const Color(0xFFC0C0C0); // Silver
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(tierColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(tierColor),
                  const SizedBox(height: 32),
                  _buildMetricsGrid(tierColor),
                  const SizedBox(height: 32),
                  _buildDescriptionSection(),
                  const SizedBox(height: 32),
                  if (plan.availableAmounts != null && plan.availableAmounts!.isNotEmpty)
                    _buildAvailableAmounts(tierColor),
                  const SizedBox(height: 40),
                  _buildActions(controller, tierColor),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Color tierColor) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image/Gradient
            if (plan.imagePath != null && plan.imagePath!.isNotEmpty)
              Hero(
                tag: 'plan_image_${plan.id}',
                child: plan.imagePath!.trim().toLowerCase().startsWith('http')
                    ? Image.network(plan.imagePath!.trim(), fit: BoxFit.cover)
                    : Image.asset(plan.imagePath!, fit: BoxFit.cover),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tierColor.withValues(alpha: 0.3),
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            
            // Dark Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Floating Badge for Status
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: plan.isActive ? KasbyColors.success.withValues(alpha: 0.2) : KasbyColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: plan.isActive ? KasbyColors.success : KasbyColors.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      plan.isActive ? Icons.check_circle : Icons.error,
                      color: plan.isActive ? KasbyColors.success : KasbyColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan.isActive ? 'نشط' : 'متوقف',
                      style: TextStyle(
                        color: plan.isActive ? KasbyColors.success : KasbyColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(Color tierColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plan.nameAr,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: tierColor,
            letterSpacing: -1,
            shadows: [
              Shadow(
                color: tierColor.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        if (plan.nameEn != null) ...[
          const SizedBox(height: 4),
          Text(
            plan.nameEn!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricsGrid(Color tierColor) {
    return Column(
      children: [
        KasbyGlassCard(
          padding: const EdgeInsets.all(24),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildDeepMetric(
                    icon: FontAwesomeIcons.chartLine,
                    label: 'الربح المتوقع',
                    value: '${plan.profitPercentage}%',
                    color: tierColor,
                  ),
                ),
                VerticalDivider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
                Expanded(
                  child: _buildDeepMetric(
                    icon: FontAwesomeIcons.shieldHalved,
                    label: 'المخاطر',
                    value: plan.riskLevel ?? 'متوسط',
                    color: _getRiskColor(plan.riskLevel),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        KasbyGlassCard(
          padding: const EdgeInsets.all(24),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildDeepMetric(
                    icon: Icons.south,
                    label: 'الحد الأدنى',
                    value: '\$${plan.minAmount.toStringAsFixed(0)}',
                    color: KasbyColors.success,
                  ),
                ),
                VerticalDivider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
                Expanded(
                  child: _buildDeepMetric(
                    icon: Icons.north,
                    label: 'الحد الأقصى',
                    value: '\$${plan.maxAmount.toStringAsFixed(0)}',
                    color: KasbyColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeepMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'وصف الباقة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: KasbyColors.primaryGold,
          ),
        ),
        const SizedBox(height: 12),
        KasbyGlassCard(
          padding: const EdgeInsets.all(20),
          child: Text(
            plan.descriptionAr,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableAmounts(Color tierColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الكميات المتاحة للمساهمة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: KasbyColors.primaryGold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: plan.availableAmounts!.map((amount) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tierColor.withValues(alpha: 0.1),
                    tierColor.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: tierColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '\$${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions(InvestmentController controller, Color tierColor) {
    return Row(
      children: [
        Expanded(
          child: KasbyButton(
            text: 'تعديل بيانات الباقة',
            onPressed: () => Get.to(() => EditInvestmentPlanScreen(plan: plan)),
            icon: Icons.edit_note_rounded,
            backgroundColor: tierColor.withValues(alpha: 0.15),
            textColor: tierColor,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: KasbyColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KasbyColors.error.withValues(alpha: 0.3)),
          ),
          child: IconButton(
            icon: const Icon(FontAwesomeIcons.trashCan, color: KasbyColors.error, size: 20),
            onPressed: () => _confirmDeletePlan(Get.context!, controller, plan),
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'low':
      case 'منخفض':
        return KasbyColors.success;
      case 'high':
      case 'عالي':
        return KasbyColors.error;
      default:
        return KasbyColors.warning;
    }
  }

  void _confirmDeletePlan(
    BuildContext context,
    InvestmentController controller,
    InvestmentPlan plan,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'حذف الخطة فورا؟',
          style: TextStyle(color: KasbyColors.error, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${plan.nameAr}"؟ لن يتمكن المستثمرون الجدد من رؤيتها.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('تراجع', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              controller.deletePlan(plan.id);
              Get.back(); // Close dialog
              Get.back(); // Go back to list
            },
            child: const Text(
              'حذف نهائي',
              style: TextStyle(color: KasbyColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
