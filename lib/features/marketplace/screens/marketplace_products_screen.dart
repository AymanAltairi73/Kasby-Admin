import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/marketplace_admin_controller.dart';
import '../models/marketplace_admin_models.dart';

class MarketplaceProductsScreen extends StatelessWidget {
  const MarketplaceProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadProducts();

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المنتجات')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KasbyColors.primaryGold,
        onPressed: () => _showForm(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.products.length,
            itemBuilder: (_, i) {
              final p = controller.products[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KasbyGlassCard(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: KasbyColors.primaryGold.withValues(alpha: 0.2),
                      child: const Icon(Icons.inventory_2, color: KasbyColors.primaryGold),
                    ),
                    title: Text(p.nameAr),
                    subtitle: Text(
                      '\$${p.walletPrice} • SKU: ${p.providerSku}\n${p.isActive ? "نشط" : "غير نشط"}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.isFeatured)
                          const Icon(Icons.star, color: KasbyColors.primaryGold, size: 18),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showForm(context, controller, product: p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => KasbyConfirmationDialog.show(
                            message: 'حذف "${p.nameAr}"؟',
                            onConfirm: () => controller.deleteProduct(p.id),
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
    MarketplaceAdminProduct? product,
  }) {
    final nameEn = TextEditingController(text: product?.nameEn ?? '');
    final nameAr = TextEditingController(text: product?.nameAr ?? '');
    final sku = TextEditingController(text: product?.providerSku ?? '');
    final wallet = TextEditingController(text: '${product?.walletPrice ?? ''}');
    final ksp = TextEditingController(text: '${product?.kspPrice ?? ''}');
    final categoryId = (product?.categoryId ?? 'cat_games').obs;
    final isFeatured = (product?.isFeatured ?? false).obs;
    final isPopular = (product?.isPopular ?? false).obs;
    final isActive = (product?.isActive ?? true).obs;

    Get.dialog(
      Obx(() => AlertDialog(
            title: Text(product == null ? 'إضافة منتج' : 'تعديل منتج'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KasbyTextField(controller: nameEn, labelText: 'الاسم (EN)'),
                  KasbyTextField(controller: nameAr, labelText: 'الاسم (AR)'),
                  KasbyTextField(controller: sku, labelText: 'Provider SKU'),
                  KasbyTextField(controller: wallet, labelText: 'سعر المحفظة', keyboardType: TextInputType.number),
                  KasbyTextField(controller: ksp, labelText: 'سعر KSP', keyboardType: TextInputType.number),
                  DropdownButtonFormField<String>(
                    value: categoryId.value,
                    decoration: const InputDecoration(labelText: 'الفئة'),
                    items: controller.categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr)))
                        .toList(),
                    onChanged: (v) { if (v != null) categoryId.value = v; },
                  ),
                  SwitchListTile(title: const Text('مميز'), value: isFeatured.value, onChanged: (v) => isFeatured.value = v),
                  SwitchListTile(title: const Text('شائع'), value: isPopular.value, onChanged: (v) => isPopular.value = v),
                  SwitchListTile(title: const Text('نشط'), value: isActive.value, onChanged: (v) => isActive.value = v),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: Get.back, child: const Text('إلغاء')),
              TextButton(
                onPressed: () {
                  final p = MarketplaceAdminProduct(
                    id: product?.id ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
                    nameEn: nameEn.text,
                    nameAr: nameAr.text,
                    categoryId: categoryId.value,
                    providerSku: sku.text,
                    walletPrice: double.tryParse(wallet.text) ?? 0,
                    kspPrice: double.tryParse(ksp.text),
                    isFeatured: isFeatured.value,
                    isPopular: isPopular.value,
                    isActive: isActive.value,
                  );
                  controller.saveProduct(p);
                  Get.back();
                },
                child: const Text('حفظ'),
              ),
            ],
          )),
    );
  }
}
