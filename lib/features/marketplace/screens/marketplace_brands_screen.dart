import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/marketplace_admin_controller.dart';
import '../models/marketplace_admin_models.dart';

class MarketplaceBrandsScreen extends StatelessWidget {
  const MarketplaceBrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadBrands();

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة العلامات')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KasbyColors.primaryGold,
        onPressed: () => _showForm(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.brands.length,
            itemBuilder: (_, i) {
              final b = controller.brands[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KasbyGlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.store, color: KasbyColors.primaryGold),
                    title: Text(b.nameAr),
                    subtitle: Text('${b.nameEn} • ${b.isActive ? "نشط" : "غير نشط"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showForm(context, controller, brand: b),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => KasbyConfirmationDialog.show(
                            message: 'حذف "${b.nameAr}"؟',
                            onConfirm: () => controller.deleteBrand(b.id),
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

  void _showForm(
    BuildContext context,
    MarketplaceAdminController controller, {
    MarketplaceAdminBrand? brand,
  }) {
    final nameEn = TextEditingController(text: brand?.nameEn ?? '');
    final nameAr = TextEditingController(text: brand?.nameAr ?? '');
    final categoryId = (brand?.categoryId ?? 'cat_games').obs;
    final isActive = (brand?.isActive ?? true).obs;

    Get.dialog(
      AlertDialog(
        title: Text(brand == null ? 'علامة جديدة' : 'تعديل العلامة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KasbyTextField(labelText: 'الاسم (EN)', controller: nameEn),
              KasbyTextField(labelText: 'الاسم (AR)', controller: nameAr),
              Obx(() => SwitchListTile(
                    title: const Text('نشط'),
                    value: isActive.value,
                    onChanged: (v) => isActive.value = v,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              controller.saveBrand(MarketplaceAdminBrand(
                id: brand?.id ?? 'brand_${DateTime.now().millisecondsSinceEpoch}',
                categoryId: categoryId.value,
                nameEn: nameEn.text,
                nameAr: nameAr.text,
                isActive: isActive.value,
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
