import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/investment_controller.dart';
import '../models/investment_model.dart';

class EditInvestmentPlanScreen extends StatelessWidget {
  final InvestmentPlan plan;
  const EditInvestmentPlanScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvestmentController>();
    final nameArController = TextEditingController(text: plan.nameAr);
    final descriptionArController = TextEditingController(
      text: plan.descriptionAr,
    );
    final profitPercentageController = TextEditingController(
      text: plan.profitPercentage.toString(),
    );
    final minAmountController = TextEditingController(
      text: plan.minAmount.toString(),
    );
    final maxAmountController = TextEditingController(
      text: plan.maxAmount.toString(),
    );
    final availableAmountsController = TextEditingController(
      text: plan.availableAmounts?.join(', ') ?? '',
    );
    final selectedImagePath = plan.imagePath.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديث إعدادات الباقة'),
        actions: [
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.trashCan,
              color: KasbyColors.error,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context, controller, plan),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview & Selection
            const Text(
              'أيقونة الباقة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow Aura
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: KasbyColors.primaryGold.withValues(
                              alpha: 0.1,
                            ),
                            blurRadius: 25,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    // Image Container
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: selectedImagePath.value != null
                          ? Image.asset(
                              selectedImagePath.value!,
                              fit: BoxFit.contain,
                            )
                          : const Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: KasbyColors.textSecondary,
                            ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () =>
                            _showImagePicker(context, selectedImagePath),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: KasbyColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            KasbyTextField(
              controller: nameArController,
              hintText: 'اسم الخطة (عربي)',
              prefixIcon: Icons.title,
            ),
            const SizedBox(height: 16),
            KasbyTextField(
              controller: descriptionArController,
              hintText: 'وصف الخطة (عربي)',
              prefixIcon: Icons.description,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KasbyTextField(
                    controller: profitPercentageController,
                    hintText: 'نسبة الربح (%)',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.percent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KasbyTextField(
                    controller: minAmountController,
                    hintText: 'الحد الأدنى',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KasbyTextField(
                    controller: maxAmountController,
                    hintText: 'الحد الأقصى',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            KasbyTextField(
              controller: availableAmountsController,
              hintText: 'المبالغ المتاحة (مثال: 100, 200, 500)',
              prefixIcon: Icons.list,
            ),
            const SizedBox(height: 40),

            KasbyButton(
              text: 'حفظ التغييرات',
              onPressed: () {
                final updates = {
                  'nameAr': nameArController.text,
                  'descriptionAr': descriptionArController.text,
                  'profitPercentage':
                      double.tryParse(profitPercentageController.text) ?? 0,
                  'minAmount': double.tryParse(minAmountController.text) ?? 0,
                  'maxAmount': double.tryParse(maxAmountController.text) ?? 0,
                  'availableAmounts': availableAmountsController.text.isNotEmpty
                      ? availableAmountsController.text
                            .split(',')
                            .map((e) => double.tryParse(e.trim()) ?? 0)
                            .where((e) => e > 0)
                            .toList()
                      : null,
                  'imagePath': selectedImagePath.value,
                };
                controller.updatePlan(plan.id, updates);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context, Rx<String?> selectedImage) {
    Get.bottomSheet(
      KasbyGlassCard(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'اختر أيقونة الخطة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const Divider(color: Colors.white12),
            _buildImageOption(
              'خطة الذهب',
              'assets/images/gold.png',
              selectedImage,
            ),
            _buildImageOption(
              'خطة الفضة',
              'assets/images/sliver.png',
              selectedImage,
            ),
            _buildImageOption(
              'خطة العقارات',
              'assets/images/real_estate.png',
              selectedImage,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildImageOption(
    String label,
    String path,
    Rx<String?> selectedImage,
  ) {
    return ListTile(
      leading: Image.asset(path, width: 30),
      title: Text(label),
      onTap: () {
        selectedImage.value = path;
        Get.back();
      },
      trailing: selectedImage.value == path
          ? const Icon(Icons.check_circle, color: KasbyColors.primaryGold)
          : null,
    );
  }

  void _confirmDelete(
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
          'هل أنت متأكد من حذف "${plan.nameAr}" نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              controller.deletePlan(plan.id);
              Get.back(); // Close dialog
              Get.back(); // Close screen
            },
            child: const Text(
              'حذف الآن',
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
