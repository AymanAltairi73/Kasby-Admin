import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/settings_management_controller.dart';
import '../models/settings_models.dart';

class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsManagementController>();

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات العملات')),
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
                ...controller.currencies.map(
                  (currency) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCurrencyCard(context, controller, currency),
                  ),
                ),
                const SizedBox(height: 24),
                KasbyButton(
                  text: 'إضافة عملة جديدة',
                  onPressed: () => _showAddDialog(context, controller),
                  isOutlined: true,
                  icon: Icons.add,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(
    BuildContext context,
    SettingsManagementController controller,
    CurrencyItem currency,
  ) {
    return KasbyGlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KasbyColors.primaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildCurrencyIcon(currency),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      currency.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (currency.isBase)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KasbyColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'الأساسية',
                          style: TextStyle(
                            color: KasbyColors.success,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '1 USD = ${currency.rate} ${currency.code}',
                  style: const TextStyle(
                    color: KasbyColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: KasbyColors.info),
                onPressed: () =>
                    _showAddDialog(context, controller, currency: currency),
              ),
              if (!currency.isBase)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: KasbyColors.error,
                  ),
                  onPressed: () =>
                      _showDeleteConfirmation(context, controller, currency.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    SettingsManagementController controller, {
    CurrencyItem? currency,
  }) {
    final nameController = TextEditingController(text: currency?.name);
    final codeController = TextEditingController(text: currency?.code);
    final rateController = TextEditingController(text: currency?.rate);
    final isBase = (currency?.isBase ?? false).obs;

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
                  currency == null ? 'إضافة عملة جديدة' : 'تعديل العملة',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                KasbyTextField(
                  controller: nameController,
                  labelText: 'اسم العملة',
                  hintText: 'مثال: ريال سعودي',
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: codeController,
                  labelText: 'رمز العملة',
                  hintText: 'مثال: SAR',
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: rateController,
                  labelText: 'سعر الصرف (مقابل USD)',
                  hintText: 'مثال: 3.75',
                ),
                const SizedBox(height: 16),
                Obx(
                  () => SwitchListTile(
                    title: const Text(
                      'عملة أساسية',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    value: isBase.value,
                    onChanged: (val) => isBase.value = val,
                    activeTrackColor: KasbyColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 32),
                KasbyButton(
                  text: 'حفظ التغييرات',
                  onPressed: () async {
                    final newCurrency = CurrencyItem(
                      id:
                          currency?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      code: codeController.text,
                      rate: rateController.text,
                      isBase: isBase.value,
                      iconCode:
                          currency?.iconCode ??
                          FontAwesomeIcons.coins.codePoint,
                      iconFamily:
                          currency?.iconFamily ??
                          FontAwesomeIcons.coins.fontFamily,
                      iconPackage:
                          currency?.iconPackage ??
                          FontAwesomeIcons.coins.fontPackage,
                    );

                      bool success;
                      if (currency == null) {
                        success = await controller.addCurrency(newCurrency);
                      } else {
                        success = await controller.updateCurrency(newCurrency);
                      }
                      
                      if (success) {
                        Get.back();
                        Get.snackbar(
                          'تم الحفظ',
                          'تم حفظ بيانات العملة بنجاح',
                          backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } else {
                        Get.snackbar(
                          'خطأ',
                          'فشل في حفظ بيانات العملة',
                          backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
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

  void _showDeleteConfirmation(
    BuildContext context,
    SettingsManagementController controller,
    String id,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف هذه العملة؟',
          style: TextStyle(color: KasbyColors.textSecondary),
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
            onPressed: () async {
              final success = await controller.deleteCurrency(id);
              if (success) {
                Get.back();
                Get.snackbar(
                  'تم الحذف',
                  'تم حذف العملة بنجاح',
                  backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
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

  Widget _buildCurrencyIcon(CurrencyItem currency) {
    if (currency.iconCode == null) {
      return const Icon(
        FontAwesomeIcons.coins,
        color: KasbyColors.primaryGold,
        size: 24,
      );
    }

    return Text(
      String.fromCharCode(currency.iconCode!),
      style: TextStyle(
        fontFamily: currency.iconFamily ?? 'MaterialIcons',
        package: currency.iconPackage,
        fontSize: 24,
        color: KasbyColors.primaryGold,
      ),
    );
  }
}
