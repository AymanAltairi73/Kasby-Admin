import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/marketplace_admin_controller.dart';
import '../models/marketplace_admin_models.dart';

class MarketplaceRewardsScreen extends StatelessWidget {
  const MarketplaceRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadRewards();

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المكافآت')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KasbyColors.primaryGold,
        onPressed: () => _showForm(controller),
        child: const Icon(Icons.add),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.rewards.length,
            itemBuilder: (_, i) {
              final r = controller.rewards[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KasbyGlassCard(
                  child: ListTile(
                    title: Text(r.titleAr),
                    subtitle: Text(
                      '${r.type} ${r.kspAmount != null ? "• ${r.kspAmount} KSP" : ""}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => KasbyConfirmationDialog.show(
                        message: 'حذف المكافأة؟',
                        onConfirm: () => controller.deleteReward(r.id),
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
    final titleEn = TextEditingController();
    final titleAr = TextEditingController();
    final ksp = TextEditingController();
    final type = 'daily'.obs;

    Get.dialog(
      Obx(() => AlertDialog(
            title: const Text('إضافة مكافأة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type.value,
                  decoration: const InputDecoration(labelText: 'النوع'),
                  items: ['daily', 'promotional', 'marketplaceBonus', 'ksp']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) { if (v != null) type.value = v; },
                ),
                KasbyTextField(controller: titleEn, labelText: 'العنوان (EN)'),
                KasbyTextField(controller: titleAr, labelText: 'العنوان (AR)'),
                KasbyTextField(controller: ksp, labelText: 'KSP', keyboardType: TextInputType.number),
              ],
            ),
            actions: [
              TextButton(onPressed: Get.back, child: const Text('إلغاء')),
              TextButton(
                onPressed: () {
                  controller.saveReward(MarketplaceAdminReward(
                    id: 'rw_${DateTime.now().millisecondsSinceEpoch}',
                    type: type.value,
                    titleEn: titleEn.text,
                    titleAr: titleAr.text,
                    kspAmount: double.tryParse(ksp.text),
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
