import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/settings_management_controller.dart';
import '../models/settings_models.dart';

class FeeSettingsScreen extends StatelessWidget {
  const FeeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsManagementController>();

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الرسوم')),
      body: RefreshIndicator(
        onRefresh: () => controller.loadSettings(),
        color: KasbyColors.primaryGold,
        child: Obx(
          () => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeeSection(
                  context,
                  controller,
                  title: 'رسوم الإيداع',
                  icon: FontAwesomeIcons.arrowDown,
                  fees: controller.fees
                      .where((e) => e.category == 'Deposit')
                      .toList(),
                ),
                const SizedBox(height: 24),
                _buildFeeSection(
                  context,
                  controller,
                  title: 'رسوم السحب',
                  icon: FontAwesomeIcons.arrowUp,
                  fees: controller.fees
                      .where((e) => e.category == 'Withdraw')
                      .toList(),
                ),
                const SizedBox(height: 24),
                _buildFeeSection(
                  context,
                  controller,
                  title: 'رسوم الاستثمار',
                  icon: FontAwesomeIcons.chartPie,
                  fees: controller.fees
                      .where((e) => e.category == 'Investment')
                      .toList(),
                ),
                const SizedBox(height: 40),
                KasbyButton(
                  text: 'إضافة نوع رسوم جديد',
                  isOutlined: true,
                  onPressed: () => Get.snackbar(
                    'تنبيه',
                    'هذه الميزة ستتوفر في التحديث القادم',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeeSection(
    BuildContext context,
    SettingsManagementController controller, {
    required String title,
    required IconData icon,
    required List<FeeItem> fees,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: KasbyColors.primaryGold, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: fees
              .map((fee) => _buildFeeCard(context, controller, fee))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFeeCard(
    BuildContext context,
    SettingsManagementController controller,
    FeeItem fee,
  ) {
    return KasbyGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fee.label,
            style: const TextStyle(color: KasbyColors.textBody, fontSize: 14),
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
                  border: Border.all(
                    color: KasbyColors.primaryGold.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  fee.value,
                  style: const TextStyle(
                    color: KasbyColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: KasbyColors.info),
                onPressed: () => _showEditDialog(context, controller, fee),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    SettingsManagementController controller,
    FeeItem fee,
  ) {
    final valueController = TextEditingController(text: fee.value);

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
                  'تعديل ${fee.label}',
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
                  hintText: 'مثال: 2.5% أو \$10.00',
                ),
                const SizedBox(height: 32),
                KasbyButton(
                  text: 'حفظ التغييرات',
                  onPressed: () {
                    controller.updateFee(fee.id, valueController.text);
                    Get.back();
                    Get.snackbar('تم', 'تم تحديث الرسوم بنجاح');
                  },
                ),
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
