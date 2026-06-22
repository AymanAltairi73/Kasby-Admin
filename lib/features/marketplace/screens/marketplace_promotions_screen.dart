import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/marketplace_admin_controller.dart';
import '../models/marketplace_admin_models.dart';

class MarketplacePromotionsScreen extends StatelessWidget {
  const MarketplacePromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadPromotions();

    return Scaffold(
      appBar: AppBar(title: const Text('العروض والترويج')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KasbyColors.primaryGold,
        onPressed: () => _showForm(controller),
        child: const Icon(Icons.add),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.promotions.length,
            itemBuilder: (_, i) {
              final p = controller.promotions[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KasbyGlassCard(
                  child: ListTile(
                    title: Text(p.titleAr),
                    subtitle: Text('${p.type} ${p.couponCode != null ? "• ${p.couponCode}" : ""}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: p.isActive,
                          activeColor: KasbyColors.primaryGold,
                          onChanged: (v) =>
                              controller.savePromotion(p.copyWith(isActive: v)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => KasbyConfirmationDialog.show(
                            message: 'حذف العرض؟',
                            onConfirm: () => controller.deletePromotion(p.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )),
    );
  }

  void _showForm(MarketplaceAdminController controller) {
    final titleEn = TextEditingController();
    final titleAr = TextEditingController();
    final coupon = TextEditingController();
    final type = 'banner'.obs;

    Get.dialog(
      Obx(() => AlertDialog(
            title: const Text('إضافة عرض'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type.value,
                  decoration: const InputDecoration(labelText: 'النوع'),
                  items: ['banner', 'discount', 'coupon', 'campaign']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) { if (v != null) type.value = v; },
                ),
                KasbyTextField(controller: titleEn, labelText: 'العنوان (EN)'),
                KasbyTextField(controller: titleAr, labelText: 'العنوان (AR)'),
                KasbyTextField(controller: coupon, labelText: 'كود الكوبون'),
              ],
            ),
            actions: [
              TextButton(onPressed: Get.back, child: const Text('إلغاء')),
              TextButton(
                onPressed: () {
                  controller.savePromotion(MarketplaceAdminPromotion(
                    id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
                    type: type.value,
                    titleEn: titleEn.text,
                    titleAr: titleAr.text,
                    couponCode: coupon.text.isEmpty ? null : coupon.text,
                  ));
                  Get.back();
                },
                child: const Text('حفظ'),
              ),
            ],
          )),
    );
  }
}
