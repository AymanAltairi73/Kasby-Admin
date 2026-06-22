import '../models/marketplace_admin_models.dart';
import 'mock_marketplace_admin_store.dart';

/// Mock API service for admin marketplace operations.
/// TODO: Replace this mock endpoint with the production Marketplace Provider API.
class MarketplaceAdminService {
  static const _delay = Duration(milliseconds: 300);

  Future<void> _simulate() => Future.delayed(_delay);

  Future<MarketplaceAdminDashboardStats> getDashboardStats() async {
    // TODO: Replace this mock endpoint with the production Marketplace Provider API.
    await _simulate();
    final orders = MockMarketplaceAdminStore.orders;
    final variants = MockMarketplaceAdminStore.variants;
    return MarketplaceAdminDashboardStats(
      totalProducts: MockMarketplaceAdminStore.products.length,
      totalCategories: MockMarketplaceAdminStore.categories.length,
      totalBrands: MockMarketplaceAdminStore.brands.length,
      totalVariants: variants.length,
      totalOrders: orders.length,
      totalRevenue: orders
          .where((o) => o.status == 'completed')
          .fold(0.0, (s, o) => s + o.totalAmount),
      pendingOrders: orders.where((o) => o.status == 'pending').length,
      topProducts: [
        const MarketplaceAdminTopItem(id: 'var_pubg_300', name: 'PUBG 300 UC', value: 1240),
        const MarketplaceAdminTopItem(id: 'var_gp_10', name: 'Google Play \$10', value: 890),
        const MarketplaceAdminTopItem(id: 'var_nf_1m', name: 'Netflix 1 Month', value: 560),
      ],
      topCategories: [
        const MarketplaceAdminTopItem(id: 'cat_games', name: 'Games', value: 4200),
        const MarketplaceAdminTopItem(id: 'cat_gift_cards', name: 'Gift Cards', value: 3100),
        const MarketplaceAdminTopItem(id: 'cat_subscriptions', name: 'Subscriptions', value: 1800),
      ],
      health: MarketplaceAdminHealth(
        activeVariants: variants.where((v) => v.isActive).length,
        inactiveVariants: variants.where((v) => !v.isActive).length,
        unmappedVariants: variants.length - MockMarketplaceAdminStore.providerMappings.length,
        activeCoupons: MockMarketplaceAdminStore.coupons.where((c) => c.isActive).length,
      ),
    );
  }

  Future<List<MarketplaceAdminCategory>> getCategories() async {
    await _simulate();
    return MockMarketplaceAdminStore.categories.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<MarketplaceAdminCategory> saveCategory(MarketplaceAdminCategory c) async {
    await _simulate();
    final idx = MockMarketplaceAdminStore.categories.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      MockMarketplaceAdminStore.categories[idx] = c;
    } else {
      MockMarketplaceAdminStore.categories.add(c);
    }
    return c;
  }

  Future<void> deleteCategory(String id) async {
    await _simulate();
    MockMarketplaceAdminStore.categories.removeWhere((c) => c.id == id);
  }

  Future<List<MarketplaceAdminProduct>> getProducts() async {
    await _simulate();
    return MockMarketplaceAdminStore.products.toList();
  }

  Future<MarketplaceAdminProduct> saveProduct(MarketplaceAdminProduct p) async {
    await _simulate();
    final idx = MockMarketplaceAdminStore.products.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      MockMarketplaceAdminStore.products[idx] = p;
    } else {
      MockMarketplaceAdminStore.products.add(p);
    }
    return p;
  }

  Future<void> deleteProduct(String id) async {
    await _simulate();
    MockMarketplaceAdminStore.products.removeWhere((p) => p.id == id);
  }

  Future<List<MarketplaceAdminOrder>> getOrders() async {
    await _simulate();
    return MockMarketplaceAdminStore.orders.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<MarketplaceAdminOrder> updateOrderStatus(String id, String status) async {
    await _simulate();
    final idx = MockMarketplaceAdminStore.orders.indexWhere((o) => o.id == id);
    MockMarketplaceAdminStore.orders[idx] =
        MockMarketplaceAdminStore.orders[idx].copyWith(status: status);
    return MockMarketplaceAdminStore.orders[idx];
  }

  Future<List<MarketplaceAdminPromotion>> getPromotions() async {
    await _simulate();
    return MockMarketplaceAdminStore.promotions.toList();
  }

  Future<MarketplaceAdminPromotion> savePromotion(MarketplaceAdminPromotion p) async {
    await _simulate();
    final idx = MockMarketplaceAdminStore.promotions.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      MockMarketplaceAdminStore.promotions[idx] = p;
    } else {
      MockMarketplaceAdminStore.promotions.add(p);
    }
    return p;
  }

  Future<void> deletePromotion(String id) async {
    await _simulate();
    MockMarketplaceAdminStore.promotions.removeWhere((p) => p.id == id);
  }

  Future<List<MarketplaceAdminReward>> getRewards() async {
    await _simulate();
    return MockMarketplaceAdminStore.rewards.toList();
  }

  Future<MarketplaceAdminReward> saveReward(MarketplaceAdminReward r) async {
    await _simulate();
    final idx = MockMarketplaceAdminStore.rewards.indexWhere((x) => x.id == r.id);
    if (idx >= 0) {
      MockMarketplaceAdminStore.rewards[idx] = r;
    } else {
      MockMarketplaceAdminStore.rewards.add(r);
    }
    return r;
  }

  Future<void> deleteReward(String id) async {
    await _simulate();
    MockMarketplaceAdminStore.rewards.removeWhere((r) => r.id == id);
  }

  Future<MarketplaceAdminSettings> getSettings() async {
    await _simulate();
    return MockMarketplaceAdminStore.settings;
  }

  Future<MarketplaceAdminSettings> updateSettings(MarketplaceAdminSettings s) async {
    await _simulate();
    MockMarketplaceAdminStore.settings = s;
    return s;
  }

  // ── Brands ─────────────────────────────────────────────────────────────────
  Future<List<MarketplaceAdminBrand>> getBrands() async {
    await _simulate();
    return MockMarketplaceAdminStore.brands.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<MarketplaceAdminBrand> saveBrand(MarketplaceAdminBrand b) async {
    await _simulate();
    final idx = MockMarketplaceAdminStore.brands.indexWhere((x) => x.id == b.id);
    if (idx >= 0) {
      MockMarketplaceAdminStore.brands[idx] = b;
    } else {
      MockMarketplaceAdminStore.brands.add(b);
    }
    return b;
  }

  Future<void> deleteBrand(String id) async {
    await _simulate();
    MockMarketplaceAdminStore.brands.removeWhere((b) => b.id == id);
  }

  Future<void> bulkSetBrandsActive(List<String> ids, bool active) async {
    await _simulate();
    for (var i = 0; i < MockMarketplaceAdminStore.brands.length; i++) {
      if (ids.contains(MockMarketplaceAdminStore.brands[i].id)) {
        MockMarketplaceAdminStore.brands[i] =
            MockMarketplaceAdminStore.brands[i].copyWith(isActive: active);
      }
    }
  }

  // ── Variants ───────────────────────────────────────────────────────────────
  Future<List<MarketplaceAdminVariant>> getVariants() async {
    await _simulate();
    return MockMarketplaceAdminStore.variants.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<MarketplaceAdminVariant> saveVariant(MarketplaceAdminVariant v) async {
    await _simulate();
    final idx = MockMarketplaceAdminStore.variants.indexWhere((x) => x.id == v.id);
    if (idx >= 0) {
      MockMarketplaceAdminStore.variants[idx] = v;
    } else {
      MockMarketplaceAdminStore.variants.add(v);
    }
    return v;
  }

  Future<void> deleteVariant(String id) async {
    await _simulate();
    MockMarketplaceAdminStore.variants.removeWhere((v) => v.id == id);
  }

  Future<void> bulkSetVariantsActive(List<String> ids, bool active) async {
    await _simulate();
    for (var i = 0; i < MockMarketplaceAdminStore.variants.length; i++) {
      if (ids.contains(MockMarketplaceAdminStore.variants[i].id)) {
        MockMarketplaceAdminStore.variants[i] =
            MockMarketplaceAdminStore.variants[i].copyWith(isActive: active);
      }
    }
  }

  Future<void> bulkDeleteVariants(List<String> ids) async {
    await _simulate();
    MockMarketplaceAdminStore.variants.removeWhere((v) => ids.contains(v.id));
  }

  // ── Coupons ────────────────────────────────────────────────────────────────
  Future<List<MarketplaceAdminCoupon>> getCoupons() async {
    await _simulate();
    return MockMarketplaceAdminStore.coupons.toList();
  }

  Future<MarketplaceAdminCoupon> saveCoupon(MarketplaceAdminCoupon c) async {
    await _simulate();
    final idx = MockMarketplaceAdminStore.coupons.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      MockMarketplaceAdminStore.coupons[idx] = c;
    } else {
      MockMarketplaceAdminStore.coupons.add(c);
    }
    return c;
  }

  Future<void> deleteCoupon(String id) async {
    await _simulate();
    MockMarketplaceAdminStore.coupons.removeWhere((c) => c.id == id);
  }

  // ── Provider Mapping ───────────────────────────────────────────────────────
  Future<List<MarketplaceAdminProviderMapping>> getProviderMappings() async {
    await _simulate();
    return MockMarketplaceAdminStore.providerMappings.toList();
  }
}
