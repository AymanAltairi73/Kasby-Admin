import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../models/subscription_model.dart';
import '../controllers/subscription_controller.dart';
import 'add_edit_subscription_screen.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final SubscriptionPlan plan;

  const SubscriptionDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();
    Color tierColor = plan.tier == 'premium' ? KasbyColors.primaryGold : Colors.white70;
    
    // Platinum/Silver logic based on price
    if (plan.tier == 'premium') {
      if (plan.price >= 80) tierColor = const Color(0xFFE5E4E2);
      else if (plan.price <= 10) tierColor = const Color(0xFFC0C0C0);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(plan.displayNameAr),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => AddEditSubscriptionScreen(plan: plan)),
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF0F172A)),
          _buildOrb(top: -50, right: -50, size: 300, color: tierColor.withValues(alpha: 0.1)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Hero
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: tierColor.withValues(alpha: 0.2)),
                          ),
                          child: Icon(
                            plan.tier == 'premium' ? Icons.stars_rounded : Icons.person_outline_rounded,
                            size: 64,
                            color: tierColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          plan.displayNameAr,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          plan.displayNameEn,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Metrics Row
                  Row(
                    children: [
                      _buildMetricItem(
                        context,
                        'السعر',
                        '\$${plan.price.toStringAsFixed(0)}',
                        plan.duration == '1 Month' ? 'شهرياً' : (plan.duration == '1 Year' ? 'سنوياً' : 'دائم'),
                        tierColor,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricItem(
                        context,
                        'الاستثمارات',
                        plan.maxActiveInvestments > 100 ? '∞' : plan.maxActiveInvestments.toString(),
                        'استثمار نشط',
                        Colors.blueAccent,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Features Section
                  const Text(
                    'المميزات المضمنة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...plan.features.map((f) => _buildFeatureRow(f, tierColor)),

                  const SizedBox(height: 40),

                  // Technical Info
                  KasbyGlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInfoRow('وقت السحب', '${plan.withdrawalProcessTime} ساعة'),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow('الاسم التقني', plan.technicalName),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow('الحالة', plan.status == 'Active' ? 'مفعلة' : 'معطلة', 
                          color: plan.status == 'Active' ? KasbyColors.success : KasbyColors.error),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(context, controller),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      label: const Text('حذف هذه الخطة نهائياً'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, String subValue, Color color) {
    return Expanded(
      child: KasbyGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              subValue,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String tech, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 12, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tech,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold, 
            color: color ?? Colors.white
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, SubscriptionController controller) {
    KasbyConfirmationDialog.show(
      message: 'هل أنت متأكد من حذف خطة "${plan.displayNameAr}"؟ لا يمكن التراجع عن هذا الإجراء.',
      onConfirm: () {
        controller.deletePlan(plan.id);
        Get.back(); // Close detail screen
      },
    );
  }

  Widget _buildOrb({double? top, double? bottom, double? left, double? right, required double size, required Color color}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
        ),
      ),
    );
  }
}
