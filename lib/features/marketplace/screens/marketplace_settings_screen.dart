import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/marketplace_admin_controller.dart';

class MarketplaceSettingsScreen extends StatelessWidget {
  const MarketplaceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadSettings();

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات متجر كاسبي')),
      body: Obx(() {
        final s = controller.settings.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            KasbyGlassCard(
              child: SwitchListTile(
                title: const Text('تفعيل متجر كاسبي'),
                value: s.isEnabled,
                activeColor: KasbyColors.primaryGold,
                onChanged: (v) => controller.updateSettings(s.copyWith(isEnabled: v)),
              ),
            ),
            KasbyGlassCard(
              child: SwitchListTile(
                title: const Text('الدفع بالمحفظة'),
                value: s.walletPaymentEnabled,
                activeColor: KasbyColors.primaryGold,
                onChanged: (v) =>
                    controller.updateSettings(s.copyWith(walletPaymentEnabled: v)),
              ),
            ),
            KasbyGlassCard(
              child: SwitchListTile(
                title: const Text('الدفع بـ KSP'),
                value: s.kspPaymentEnabled,
                activeColor: KasbyColors.primaryGold,
                onChanged: (v) =>
                    controller.updateSettings(s.copyWith(kspPaymentEnabled: v)),
              ),
            ),
            KasbyGlassCard(
              child: SwitchListTile(
                title: const Text('وضع الصيانة'),
                value: s.maintenanceMode,
                activeColor: Colors.orange,
                onChanged: (v) =>
                    controller.updateSettings(s.copyWith(maintenanceMode: v)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ملاحظة: هذه إعدادات تجريبية (Mock). سيتم ربطها بقاعدة البيانات عند تكامل API الإنتاج.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        );
      }),
    );
  }
}
