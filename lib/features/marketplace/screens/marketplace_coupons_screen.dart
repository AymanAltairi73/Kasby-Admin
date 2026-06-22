import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/marketplace_admin_controller.dart';
import '../models/marketplace_admin_models.dart';

class MarketplaceCouponsScreen extends StatelessWidget {
  const MarketplaceCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadCoupons();

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الكوبونات')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KasbyColors.primaryGold,
        onPressed: () => _showForm(controller),
        child: const Icon(Icons.add),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.coupons.length,
            itemBuilder: (_, i) {
              final c = controller.coupons[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KasbyGlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.local_offer, color: KasbyColors.primaryGold),
                    title: Text(c.code),
                    subtitle: Text(
                      '${c.titleAr} • ${c.discountPercent != null ? "${c.discountPercent}%" : "\$${c.discountAmount}"}\n${c.isActive ? "نشط" : "غير نشط"}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => KasbyConfirmationDialog.show(
                        message: 'حذف الكوبون "${c.code}"؟',
                        onConfirm: () => controller.deleteCoupon(c.id),
                      ),
                    ),
                  ),
                ),
              );
            },
          )),
    );
  }

  void _showForm(MarketplaceAdminController controller) {
    final code = TextEditingController();
    final titleEn = TextEditingController();
    final titleAr = TextEditingController();
    final percent = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('كوبون جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KasbyTextField(labelText: 'الرمز', controller: code),
            KasbyTextField(labelText: 'العنوان (EN)', controller: titleEn),
            KasbyTextField(labelText: 'العنوان (AR)', controller: titleAr),
            KasbyTextField(labelText: 'نسبة الخصم %', controller: percent, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              controller.saveCoupon(MarketplaceAdminCoupon(
                id: 'cpn_${DateTime.now().millisecondsSinceEpoch}',
                code: code.text.toUpperCase(),
                titleEn: titleEn.text,
                titleAr: titleAr.text,
                discountPercent: double.tryParse(percent.text),
              ));
              Get.back();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
