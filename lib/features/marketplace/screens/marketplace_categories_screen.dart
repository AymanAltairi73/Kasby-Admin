import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/marketplace_admin_controller.dart';
import '../models/marketplace_admin_models.dart';

class MarketplaceCategoriesScreen extends StatelessWidget {
  const MarketplaceCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadCategories();

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الفئات')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KasbyColors.primaryGold,
        onPressed: () => _showForm(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.categories.length,
            itemBuilder: (_, i) {
              final c = controller.categories[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KasbyGlassCard(
                  child: ListTile(
                    title: Text(c.nameAr),
                    subtitle: Text('${c.nameEn} • ترتيب: ${c.sortOrder}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: c.isVisible,
                          activeColor: KasbyColors.primaryGold,
                          onChanged: (v) => controller.saveCategory(
                            c.copyWith(isVisible: v),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showForm(context, controller, category: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => KasbyConfirmationDialog.show(
                            message: 'حذف الفئة "${c.nameAr}"؟',
                            onConfirm: () => controller.deleteCategory(c.id),
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
    MarketplaceAdminCategory? category,
  }) {
    final nameEn = TextEditingController(text: category?.nameEn ?? '');
    final nameAr = TextEditingController(text: category?.nameAr ?? '');
    final sortOrder = TextEditingController(
      text: '${category?.sortOrder ?? controller.categories.length + 1}',
    );

    Get.dialog(
      AlertDialog(
        title: Text(category == null ? 'إضافة فئة' : 'تعديل فئة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KasbyTextField(controller: nameEn, labelText: 'الاسم (EN)'),
            KasbyTextField(controller: nameAr, labelText: 'الاسم (AR)'),
            KasbyTextField(controller: sortOrder, labelText: 'الترتيب', keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final c = MarketplaceAdminCategory(
                id: category?.id ?? 'cat_${DateTime.now().millisecondsSinceEpoch}',
                nameEn: nameEn.text,
                nameAr: nameAr.text,
                sortOrder: int.tryParse(sortOrder.text) ?? 0,
                isVisible: category?.isVisible ?? true,
              );
              controller.saveCategory(c);
              Get.back();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
