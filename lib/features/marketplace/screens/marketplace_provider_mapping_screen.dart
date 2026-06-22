import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/marketplace_admin_controller.dart';

class MarketplaceProviderMappingScreen extends StatelessWidget {
  const MarketplaceProviderMappingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadProviderMappings();

    return Scaffold(
      appBar: AppBar(title: const Text('ربط المزود')),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.providerMappings.length,
            itemBuilder: (_, i) {
              final m = controller.providerMappings[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KasbyGlassCard(
                  child: ExpansionTile(
                    leading: const Icon(Icons.link, color: KasbyColors.primaryGold),
                    title: Text(m.variantName),
                    subtitle: Text('${m.providerName} • ${m.providerSku}'),
                    children: [
                      _detailRow('Provider Product ID', m.providerProductId),
                      _detailRow('Provider Category', m.providerCategory),
                      _detailRow('Status', m.providerStatus),
                    ],
                  ),
                ),
              );
            },
          )),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 140, child: Text(label, style: TextStyle(color: Colors.grey.shade500))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
