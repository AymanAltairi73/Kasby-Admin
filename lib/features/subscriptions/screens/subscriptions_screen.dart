import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_dialog.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_model.dart';

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

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر الفئة للإدارة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Free Plan Category
                _buildCategoryCard(
                  title: 'الخطة المجانية',
                  subtitle: 'إدارة مميزات الحساب العادي',
                  icon: Icons.person_outline_rounded,
                  color: Colors.white70,
                  onTap: () {
                    final freePlan = controller.plans.firstWhereOrNull(
                      (p) => p.tier == 'free',
                    );
                    if (freePlan != null) {
                      _showEditPlanDialog(context, freePlan, controller);
                    } else {
                      Get.snackbar('تنبيه', 'لا توجد خطة مجانية حالياً');
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Premium Category
                _buildCategoryCard(
                  title: 'خطة الحساب المميز',
                  subtitle: 'إدارة باقات البريميوم والمميزات',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlanDialog(context, controller),
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

  static void showPlanDialog(
    BuildContext context,
    SubscriptionPlan? plan,
    SubscriptionController controller,
  ) {
    final isEdit = plan != null;
    final nameArController = TextEditingController(
      text: plan?.displayNameAr ?? '',
    );
    final nameEnController = TextEditingController(
      text: plan?.displayNameEn ?? '',
    );
    final priceController = TextEditingController(
      text: plan?.price.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: plan?.duration ?? '',
    );
    final maxInvestmentsController = TextEditingController(
      text: plan?.maxActiveInvestments.toString() ?? '',
    );
    final withdrawalTimeController = TextEditingController(
      text: plan?.withdrawalProcessTime.toString() ?? '',
    );
    final tier = (plan?.tier ?? 'premium').obs;
    final status = (plan?.status ?? 'Active').obs;
    final features = (plan?.features ?? <String>[]).obs;
    final featureController = TextEditingController();

    KasbyDialog.show(
      title: isEdit ? 'تعديل الخطة' : 'إضافة خطة جديدة',
      content: SingleChildScrollView(
        child: Column(
          children: [
            Obx(
              () => SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'free', label: Text('مجانية')),
                  ButtonSegment(value: 'premium', label: Text('مميزة')),
                ],
                selected: {tier.value},
                onSelectionChanged: (set) => tier.value = set.first,
              ),
            ),
            const SizedBox(height: 20),
            KasbyTextField(
              controller: nameArController,
              labelText: 'الاسم (عربي)',
              prefixIcon: Icons.title_rounded,
            ),
            const SizedBox(height: 16),
            KasbyTextField(
              controller: nameEnController,
              labelText: 'Name (English)',
              prefixIcon: Icons.translate_rounded,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KasbyTextField(
                    controller: priceController,
                    labelText: 'السعر (\$)',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KasbyTextField(
                    controller: durationController,
                    labelText: 'المدة (مثلاً: 1 Month)',
                    prefixIcon: Icons.timer_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KasbyTextField(
                    controller: maxInvestmentsController,
                    labelText: 'الاستثمارات',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.account_balance_wallet_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KasbyTextField(
                    controller: withdrawalTimeController,
                    labelText: 'ساعات السحب',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.history_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'المميزات:',
              style: TextStyle(
                color: KasbyColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: KasbyTextField(
                    controller: featureController,
                    labelText: 'أضف ميزة',
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (featureController.text.isNotEmpty) {
                      features.add(featureController.text);
                      featureController.clear();
                    }
                  },
                  icon: const Icon(
                    Icons.add_circle_rounded,
                    color: KasbyColors.primaryGold,
                  ),
                ),
              ],
            ),
            Obx(
              () => Column(
                children: features
                    .map(
                      (f) => ListTile(
                        title: Text(
                          f,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => features.remove(f),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            final newPlan = SubscriptionPlan(
              id: isEdit
                  ? plan.id
                  : DateTime.now().millisecondsSinceEpoch.toString(),
              tier: tier.value,
              technicalName: nameEnController.text.toLowerCase().replaceAll(
                ' ',
                '_',
              ),
              displayNameAr: nameArController.text,
              displayNameEn: nameEnController.text,
              price: double.tryParse(priceController.text) ?? 0.0,
              duration: durationController.text,
              maxActiveInvestments:
                  int.tryParse(maxInvestmentsController.text) ?? 0,
              withdrawalProcessTime:
                  int.tryParse(withdrawalTimeController.text) ?? 0,
              status: status.value,
              icon: 'stars_rounded',
              features: features.toList(),
              keywords: [],
            );

            if (isEdit) {
              controller.updatePlan(plan.id, newPlan.toJson());
            } else {
              controller.createPlan(newPlan);
            }
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: KasbyColors.primaryGold,
            foregroundColor: Colors.black,
          ),
          child: Text(isEdit ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }

  void _showAddPlanDialog(
    BuildContext context,
    SubscriptionController controller,
  ) {
    SubscriptionsScreen.showPlanDialog(context, null, controller);
  }

  void _showEditPlanDialog(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionController controller,
  ) {
    SubscriptionsScreen.showPlanDialog(context, plan, controller);
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
class PremiumDetailsScreen extends StatelessWidget {
  const PremiumDetailsScreen({super.key});

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
            onPressed: () =>
                SubscriptionsScreen.showPlanDialog(context, null, controller),
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
                    plan.displayNameAr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    plan.duration,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _updatePlan(context, plan, controller),
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: KasbyColors.primaryGold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deletePlan(context, plan, controller),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${plan.price}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: KasbyColors.primaryGold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          ...plan.features
              .take(3)
              .map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                        color: KasbyColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _updatePlan(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionController controller,
  ) {
    SubscriptionsScreen.showPlanDialog(context, plan, controller);
  }

  void _deletePlan(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionController controller,
  ) {
    KasbyConfirmationDialog.show(
      message: 'هل أنت متأكد من حذف هذه الخطة؟ لا يمكن التراجع عن هذا الإجراء.',
      onConfirm: () => controller.deletePlan(plan.id),
    );
  }
}
