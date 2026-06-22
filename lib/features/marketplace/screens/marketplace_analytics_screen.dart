import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/marketplace_admin_controller.dart';
import '../models/marketplace_admin_models.dart';

class MarketplaceAnalyticsScreen extends StatelessWidget {
  const MarketplaceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadDashboard();

    return Scaffold(
      appBar: AppBar(title: const Text('تحليلات متجر كاسبي')),
      body: Obx(() {
        final s = controller.stats.value;
        if (s == null) {
          return const Center(child: CircularProgressIndicator(color: KasbyColors.primaryGold));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('صحة متجر كاسبي'),
            KasbyGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _healthRow('باقات نشطة', s.health.activeVariants, Colors.green),
                    _healthRow('باقات متوقفة', s.health.inactiveVariants, Colors.orange),
                    _healthRow('بدون ربط مزود', s.health.unmappedVariants, Colors.redAccent),
                    _healthRow('كوبونات نشطة', s.health.activeCoupons, KasbyColors.primaryGold),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('أفضل المنتجات'),
            ...s.topProducts.map((p) => _topTile(p, '\$${p.value.toStringAsFixed(0)}')),
            const SizedBox(height: 24),
            _sectionTitle('الإيرادات حسب الفئة'),
            ...s.topCategories.map((c) => _topTile(c, '\$${c.value.toStringAsFixed(0)}')),
          ],
        );
      }),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _healthRow(String label, int value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );

  Widget _topTile(MarketplaceAdminTopItem item, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: KasbyGlassCard(
          child: ListTile(
            title: Text(item.name),
            trailing: Text(value, style: const TextStyle(color: KasbyColors.primaryGold, fontWeight: FontWeight.bold)),
          ),
        ),
      );
}
