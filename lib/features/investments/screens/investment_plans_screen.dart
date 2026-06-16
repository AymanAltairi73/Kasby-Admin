import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/utils/navigation_utils.dart';
import '../controllers/investment_controller.dart';
import '../models/investment_model.dart';
import 'edit_investment_plan_screen.dart';
import 'investment_plan_detail_screen.dart';

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
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KasbyColors.primaryGold.withValues(alpha: 0.05),
              ),
            ),
          ),

          Positioned.fill(
            child: Obx(() {
              if (controller.isLoading.value && controller.plans.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: KasbyColors.primaryGold,
                  ),
                );
              }

              if (controller.activePlans.isEmpty) {
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

              return RefreshIndicator(
                onRefresh: () => controller.loadPlans(),
                color: KasbyColors.primaryGold,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مستويات الاستثمار النخبوية',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'اختر الباقة المناسبة لاستراتيجيتك المالية',
                              style: TextStyle(
                                fontSize: 14,
                                color: KasbyColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: controller.activePlans.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final plan = controller.activePlans[index];
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

                          return _buildDazzlingPlanCard(
                            plan,
                            controller,
                            tierColor,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDazzlingPlanCard(
    InvestmentPlan plan,
    InvestmentController controller,
    Color tierColor,
  ) {
    return GestureDetector(
      onTap: () => Get.to(() => InvestmentPlanDetailScreen(plan: plan)),
      child: KasbyGlassCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Header
            Stack(
              children: [
                Hero(
                  tag: 'plan_image_${plan.id}',
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      image: plan.imagePath != null
                          ? DecorationImage(
                              image: plan.imagePath!
                                      .trim()
                                      .toLowerCase()
                                      .startsWith('http')
                                  ? NetworkImage(plan.imagePath!.trim())
                                  : AssetImage(plan.imagePath!) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: plan.imagePath == null
                          ? LinearGradient(
                              colors: [
                                tierColor.withValues(alpha: 0.3),
                                Colors.black
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                  ),
                ),
                // Overlay Gradient
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: plan.isActive
                          ? KasbyColors.success.withValues(alpha: 0.2)
                          : KasbyColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: plan.isActive
                            ? KasbyColors.success
                            : KasbyColors.error,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: plan.isActive
                                ? KasbyColors.success
                                : KasbyColors.error,
                          ),
                        ),
                        const SizedBox(width: 4),
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
                ),
                // Profit Badge
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عائد يصل إلى',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${plan.profitPercentage}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: tierColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.nameAr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: tierColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.trashCan,
                            color: KasbyColors.error, size: 16),
                        onPressed: () =>
                            _confirmDeletePlan(Get.context!, controller, plan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.descriptionAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.4,
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: KasbyButton(
                          text: 'عرض التفاصيل',
                          onPressed: () =>
                              Get.to(() => InvestmentPlanDetailScreen(plan: plan)),
                          icon: Icons.visibility_rounded,
                          backgroundColor: tierColor.withValues(alpha: 0.1),
                          textColor: tierColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      KasbyButton(
                        text: '',
                        onPressed: () =>
                            Get.to(() => EditInvestmentPlanScreen(plan: plan)),
                        icon: Icons.edit_rounded,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(
            color: KasbyColors.primaryGold,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    final nameEnController = TextEditingController();
    final descriptionController = TextEditingController();
    final profitController = TextEditingController();
    final minAmountController = TextEditingController();
    final maxAmountController = TextEditingController();
    final amountsController = TextEditingController();
    String selectedRiskLevel = 'متوسط';
    final Map<String, String> riskLevelMap = {
      'منخفض': 'low',
      'متوسط': 'medium',
      'عالي': 'high',
    };
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: KasbyColors.surface,
            title: const Text(
              'إنشاء خطة جديدة',
              style: TextStyle(color: KasbyColors.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        setState(() {
                          selectedImage = File(image.path);
                        });
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.add_a_photo,
                              color: KasbyColors.primaryGold,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogLabel('اسم الباقة (بالعربي)'),
                  KasbyTextField(
                    controller: nameArController,
                    hintText: '',
                    prefixIcon: Icons.title,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogLabel('اسم الباقة (انجليزي)'),
                  KasbyTextField(
                    controller: nameEnController,
                    hintText: '',
                    prefixIcon: Icons.language,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogLabel('وصف الباقة (بالعربي)'),
                  KasbyTextField(
                    controller: descriptionController,
                    hintText: 'اشرح تفاصيل الباقة...',
                    prefixIcon: Icons.description,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDialogLabel('الربح (%)'),
                            KasbyTextField(
                              controller: profitController,
                              hintText: '0.0',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.percent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDialogLabel('الحد الأدنى'),
                            KasbyTextField(
                              controller: minAmountController,
                              hintText: '0.0',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.attach_money,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDialogLabel('الحد الأقصى'),
                            KasbyTextField(
                              controller: maxAmountController,
                              hintText: '0.0',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.attach_money,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDialogLabel('المبالغ المتاحة (مفصولة بفاصلة)'),
                  KasbyTextField(
                    controller: amountsController,
                    hintText: '100, 500, 1000,..etc',
                    prefixIcon: Icons.list,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogLabel('مستوى المخاطرة'),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRiskLevel,
                    dropdownColor: KasbyColors.surface,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.warning,
                        color: KasbyColors.primaryGold,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ['منخفض', 'متوسط', 'عالي']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child:
                                Text(e, style: const TextStyle(color: Colors.white)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedRiskLevel = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => safePop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: KasbyColors.textSecondary),
                ),
              ),
              Obx(
                () => TextButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          if (nameArController.text.isEmpty) {
                            Get.snackbar('خطأ', 'يرجى إدخال اسم الخطة');
                            return;
                          }

                          String? imageUrl;
                          if (selectedImage != null) {
                            imageUrl = await controller.uploadPlanImage(
                              selectedImage!,
                            );
                          }

                          List<double> availableAmounts = [];
                          if (amountsController.text.isNotEmpty) {
                            availableAmounts = amountsController.text
                                .split(',')
                                .map((e) => double.tryParse(e.trim()) ?? 0)
                                .where((e) => e > 0)
                                .toList();
                          }

                          try {
                            await controller.createPlan(
                              nameAr: nameArController.text,
                              nameEn: nameEnController.text,
                              descriptionAr: descriptionController.text.isNotEmpty
                                  ? descriptionController.text
                                  : 'وصف الخطة المقترحة للاستثمار...',
                              profitPercentage:
                                  double.tryParse(profitController.text) ?? 0,
                              minAmount:
                                  double.tryParse(minAmountController.text) ?? 0,
                              maxAmount:
                                  double.tryParse(maxAmountController.text) ?? 0,
                              availableAmounts: availableAmounts.isNotEmpty
                                  ? availableAmounts
                                  : null,
                              riskLevel: riskLevelMap[selectedRiskLevel] ?? 'medium',
                              imagePath: imageUrl,
                            );
                            
                            safePop(); // Close creation dialog
                            
                            // Show success dialog
                            Get.dialog(
                              AlertDialog(
                                backgroundColor: KasbyColors.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: KasbyColors.success),
                                    SizedBox(width: 10),
                                    Text('نجاح', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                                content: const Text(
                                  'تم إضافة الخطة بنجاح',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => safePop(),
                                    child: const Text('حسناً', style: TextStyle(color: KasbyColors.primaryGold)),
                                  ),
                                ],
                              ),
                            );
                          } catch (e) {
                            // Error handled by controller
                          }
                        },
                  child: Text(
                    controller.isLoading.value ? 'جاري...' : 'إنشاء',
                    style: const TextStyle(color: KasbyColors.primaryGold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeletePlan(
    BuildContext context,
    InvestmentController controller,
    InvestmentPlan plan,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'حذف الخطة',
          style: TextStyle(color: KasbyColors.error),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${plan.nameAr}"؟\n'
          'إذا كانت مرتبطة باستثمارات سيتم إيقافها فقط.',
          style: const TextStyle(color: KasbyColors.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => safePop(null, dialogContext),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              safePop(null, dialogContext);
              await controller.deletePlan(plan.id);
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
