import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/marketplace_admin_controller.dart';

class MarketplaceVariantsScreen extends StatelessWidget {
  const MarketplaceVariantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadVariants();

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الباقات')),
      body: Column(
        children: [
          Obx(() {
            if (controller.selectedVariantIds.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: KasbyColors.primaryGold.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Text('${controller.selectedVariantIds.length} محدد'),
                  const Spacer(),
                  TextButton(onPressed: controller.bulkActivateVariants, child: const Text('تفعيل')),
                  TextButton(onPressed: controller.bulkDeactivateVariants, child: const Text('إيقاف')),
                  TextButton(
                    onPressed: () => KasbyConfirmationDialog.show(
                      message: 'حذف الباقات المحددة؟',
                      onConfirm: controller.bulkDeleteVariants,
                    ),
                    child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: Obx(() => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.variants.length,
                  itemBuilder: (_, i) {
                    final v = controller.variants[i];
                    final selected = controller.selectedVariantIds.contains(v.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: KasbyGlassCard(
                        child: ListTile(
                          leading: Checkbox(
                            value: selected,
                            activeColor: KasbyColors.primaryGold,
                            onChanged: (_) => controller.toggleVariantSelection(v.id),
                          ),
                          title: Text(v.nameAr),
                          subtitle: Text(
                            '\$${v.walletPrice} • SKU: ${v.providerSku}\n${v.isActive ? "نشط" : "غير نشط"}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (v.isFeatured)
                                const Icon(Icons.star, color: KasbyColors.primaryGold, size: 18),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => KasbyConfirmationDialog.show(
                                  message: 'حذف "${v.nameAr}"؟',
                                  onConfirm: () => controller.deleteVariant(v.id),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }
}
