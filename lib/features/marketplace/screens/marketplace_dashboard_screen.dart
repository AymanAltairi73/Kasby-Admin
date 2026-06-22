import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/marketplace_admin_controller.dart';
import 'marketplace_categories_screen.dart';
import 'marketplace_products_screen.dart';
import 'marketplace_orders_screen.dart';
import 'marketplace_promotions_screen.dart';
import 'marketplace_rewards_screen.dart';
import 'marketplace_settings_screen.dart';
import 'marketplace_brands_screen.dart';
import 'marketplace_variants_screen.dart';
import 'marketplace_coupons_screen.dart';
import 'marketplace_analytics_screen.dart';
import 'marketplace_provider_mapping_screen.dart';

class MarketplaceDashboardScreen extends StatelessWidget {
  const MarketplaceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MarketplaceAdminController());
    controller.loadDashboard();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('إدارة متجر كاسبي'),
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF0F172A)),
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KasbyColors.primaryGold.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value && controller.stats.value == null) {
                return const Center(
                  child: CircularProgressIndicator(color: KasbyColors.primaryGold),
                );
              }
              final s = controller.stats.value;
              return RefreshIndicator(
                color: KasbyColors.primaryGold,
                onRefresh: controller.loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (s != null) ...[
                      _statsGrid(s),
                      if (s.health.unmappedVariants > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: KasbyGlassCard(
                            child: ListTile(
                              leading: const Icon(Icons.warning_amber, color: Colors.orange),
                              title: const Text('تنبيه صحة المتجر'),
                              subtitle: Text('${s.health.unmappedVariants} باقة بدون ربط مزود'),
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () => Get.to(() => const MarketplaceProviderMappingScreen()),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    const Text('الإدارة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _menuTile(FontAwesomeIcons.box, 'المنتجات', () {
                      Get.to(() => const MarketplaceProductsScreen());
                    }),
                    _menuTile(FontAwesomeIcons.tags, 'الباقات (Variants)', () {
                      Get.to(() => const MarketplaceVariantsScreen());
                    }),
                    _menuTile(FontAwesomeIcons.store, 'العلامات (Brands)', () {
                      Get.to(() => const MarketplaceBrandsScreen());
                    }),
                    _menuTile(FontAwesomeIcons.layerGroup, 'الفئات', () {
                      Get.to(() => const MarketplaceCategoriesScreen());
                    }),
                    _menuTile(FontAwesomeIcons.ticket, 'الكوبونات', () {
                      Get.to(() => const MarketplaceCouponsScreen());
                    }),
                    _menuTile(FontAwesomeIcons.chartLine, 'التحليلات', () {
                      Get.to(() => const MarketplaceAnalyticsScreen());
                    }),
                    _menuTile(FontAwesomeIcons.link, 'ربط المزود', () {
                      Get.to(() => const MarketplaceProviderMappingScreen());
                    }),
                    _menuTile(FontAwesomeIcons.receipt, 'الطلبات', () {
                      Get.to(() => const MarketplaceOrdersScreen());
                    }),
                    _menuTile(FontAwesomeIcons.tags, 'العروض والترويج', () {
                      Get.to(() => const MarketplacePromotionsScreen());
                    }),
                    _menuTile(FontAwesomeIcons.gift, 'المكافآت', () {
                      Get.to(() => const MarketplaceRewardsScreen());
                    }),
                    _menuTile(FontAwesomeIcons.gear, 'إعدادات متجر كاسبي', () {
                      Get.to(() => const MarketplaceSettingsScreen());
                    }),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(dynamic s) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard('المنتجات', '${s.totalProducts}', FontAwesomeIcons.box),
        _statCard('العلامات', '${s.totalBrands}', FontAwesomeIcons.store),
        _statCard('الباقات', '${s.totalVariants}', FontAwesomeIcons.tags),
        _statCard('الطلبات', '${s.totalOrders}', FontAwesomeIcons.receipt),
        _statCard('الإيرادات', '\$${s.totalRevenue.toStringAsFixed(0)}', FontAwesomeIcons.dollarSign),
        _statCard('قيد الانتظار', '${s.pendingOrders}', FontAwesomeIcons.clock),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return KasbyGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: KasbyColors.primaryGold, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KasbyGlassCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: KasbyColors.primaryGold),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.chevron_left),
          ],
        ),
      ),
    );
  }
}
