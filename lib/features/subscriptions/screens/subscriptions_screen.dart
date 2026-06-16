import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_model.dart';
import 'subscription_detail_screen.dart';
import 'add_edit_subscription_screen.dart';

/// Main Subscriptions Screen with Category Tiers
class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إدارة الاشتراكات'),
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF0F172A)),
          _buildOrb(
            top: -50,
            right: -50,
            size: 300,
            color: KasbyColors.primaryGold.withValues(alpha: 0.05),
          ),
          _buildOrb(
            bottom: -100,
            left: -100,
            size: 400,
            color: KasbyColors.info.withValues(alpha: 0.05),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Radiant Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
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
                          'خطط الاشتراكات',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          final total = controller.plans.length;
                          final active = controller.plans
                              .where((p) => p.status.toLowerCase() == 'active')
                              .length;
                          return Text(
                            '$total خطة · $active فعّالة',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'فئات الاشتراكات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Free Plan Category
                        _buildCategoryCard(
                          title: 'الخطة المجانية',
                          subtitle: 'مميزات الحساب المجاني والقيود',
                          icon: Icons.person_outline_rounded,
                          color: Colors.white70,
                          onTap: () {
                            final freePlan = controller.plans.firstWhereOrNull(
                              (p) => p.tier == 'free',
                            );
                            if (freePlan != null) {
                              Get.to(() => SubscriptionDetailScreen(plan: freePlan));
                            } else {
                              Get.snackbar('تنبيه', 'لا توجد خطة مجانية حالياً');
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        // Premium Category
                        _buildCategoryCard(
                          title: 'الخطة المميزة',
                          subtitle: 'إدارة باقات البريميوم والخدمات الاستثنائية',
                          icon: Icons.stars_rounded,
                          color: KasbyColors.primaryGold,
                          isPremium: true,
                          onTap: () => Get.to(() => const PremiumDetailsScreen()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AddEditSubscriptionScreen()),
        backgroundColor: KasbyColors.primaryGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'إضافة خطة جديدة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return KasbyGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 18,
          ),
        ],
      ),
    );
  }

  static Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
          ],
        ),
      ),
    );
  }
}

/// Detailed View for Premium Plans
class PremiumDetailsScreen extends StatefulWidget {
  const PremiumDetailsScreen({super.key});

  @override
  State<PremiumDetailsScreen> createState() => _PremiumDetailsScreenState();
}

class _PremiumDetailsScreenState extends State<PremiumDetailsScreen> {
  @override
  void initState() {
    super.initState();
    AppLoggerService.debugTrace(
      className: 'PremiumDetailsScreen',
      method: 'initState',
      feature: 'Subscriptions',
      status: 'INFO',
      message: 'Screen mounted',
    );
  }

  @override
  void dispose() {
    AppLoggerService.debugTrace(
      className: 'PremiumDetailsScreen',
      method: 'dispose',
      feature: 'Subscriptions',
      status: 'INFO',
      message: 'Screen unmounted',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('خطط الحساب المميز'),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const AddEditSubscriptionScreen()),
            icon: const Icon(Icons.add_rounded, color: KasbyColors.primaryGold),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF0F172A)),
          SubscriptionsScreen._buildOrb(
            top: -50,
            right: -50,
            size: 300,
            color: KasbyColors.primaryGold.withValues(alpha: 0.05),
          ),
          SubscriptionsScreen._buildOrb(
            bottom: -100,
            left: -100,
            size: 400,
            color: KasbyColors.info.withValues(alpha: 0.05),
          ),

          Obx(() {
            final premiumPlans = controller.plans
                .where((p) => p.tier == 'premium')
                .toList();

            if (premiumPlans.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد خطط مميزة فعالة',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
              itemCount: premiumPlans.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final plan = premiumPlans[index];
                return _buildPlanItem(context, plan, controller);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlanItem(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionController controller,
  ) {
    // Tier-based decoration
    Color tierColor = KasbyColors.primaryGold;
    if (plan.tier == 'premium') {
      if (plan.price >= 80) {
        tierColor = const Color(0xFFE5E4E2); // Platinum
      } else if (plan.price <= 10) {
        tierColor = const Color(0xFFC0C0C0); // Silver
      }
    }

    return KasbyGlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Tier and Price
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tierColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.displayNameAr,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: tierColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.displayNameEn,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${plan.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: tierColor,
                      ),
                    ),
                    Text(
                      plan.duration == '1 Month' ? '/ شهرياً' : '/ سنوياً',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المميزات الحصرية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                ...plan.features.take(2).map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: tierColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMiniBadge(
                      '${plan.maxActiveInvestments > 100 ? "∞" : plan.maxActiveInvestments} استثمارات',
                      Icons.account_balance_wallet_rounded,
                      tierColor,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniBadge(
                      'سحب خلال ${plan.withdrawalProcessTime} ساعة',
                      Icons.history_rounded,
                      Colors.blueAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.to(() => SubscriptionDetailScreen(plan: plan)),
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: const Text('عرض التفاصيل'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tierColor,
                          side: BorderSide(color: tierColor.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () => Get.to(() => AddEditSubscriptionScreen(plan: plan)),
                      icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: KasbyColors.primaryGold.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
