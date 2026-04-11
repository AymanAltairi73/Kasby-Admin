import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/settings_management_controller.dart';
import '../models/settings_models.dart';

class TransactionLimitsScreen extends StatelessWidget {
  const TransactionLimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsManagementController>();

    return Scaffold(
      appBar: AppBar(title: const Text('حدود المعاملات')),
      body: RefreshIndicator(
        onRefresh: () => controller.loadSettings(),
        color: KasbyColors.primaryGold,
        child: Obx(
          () {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: KasbyColors.primaryGold,
                ),
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildLimitSection(
                  context,
                  controller,
                  title: 'المستخدم العادي',
                  limits: controller.limits
                      .where((e) => e.tier == 'normal')
                      .toList(),
                ),
                const SizedBox(height: 24),
                _buildLimitSection(
                  context,
                  controller,
                  title: 'المستخدم الموثق / VIP',
                  limits: controller.limits.where((e) => e.tier == 'vip').toList(),
                ),
                const SizedBox(height: 40),
                KasbyButton(
                  text: 'إضافة حد جديد',
                  isOutlined: true,
                  onPressed: () => Get.snackbar(
                    'تنبيه',
                    'يمكنك تعديل الحدود الحالية فقط في هذا الإصدار',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLimitSection(
    BuildContext context,
    SettingsManagementController controller, {
    required String title,
    required List<LimitItem> limits,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: KasbyColors.primaryGold,
          ),
        ),
        const SizedBox(height: 12),
        ...limits.map(
          (limit) => KasbyGlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    limit.label,
                    style: const TextStyle(
                      color: KasbyColors.textBody,
                      fontSize: 14,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        limit.value,
                        style: const TextStyle(
                          color: KasbyColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: KasbyColors.info,
                      ),
                      onPressed: () =>
                          _showEditDialog(context, controller, limit),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    SettingsManagementController controller,
    LimitItem limit,
  ) {
    final valueController = TextEditingController(text: limit.value);

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تعديل ${limit.label}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                KasbyTextField(
                  controller: valueController,
                  labelText: 'القيمة الجديدة',
                  hintText: 'مثال: 5000 أو Unlimited',
                ),
                const SizedBox(height: 32),
                KasbyButton(
                  text: 'حفظ التغييرات',
                  onPressed: () async {
                    final success = await controller.updateLimit(
                      limit.id,
                      valueController.text,
                    );
                    if (success) {
                      Get.back();
                      Get.snackbar(
                        'تم التحديث',
                        'تم تحديث الحد بنجاح',
                        backgroundColor: KasbyColors.success.withOpacity(0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
                      Get.snackbar(
                        'خطأ',
                        'فشل في تحديث الحد',
                        backgroundColor: KasbyColors.error.withOpacity(0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: KasbyColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
