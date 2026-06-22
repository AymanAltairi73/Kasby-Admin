import 'package:get/get.dart';
import '../models/marketplace_admin_models.dart';
import '../services/marketplace_admin_service.dart';

class MarketplaceAdminController extends GetxController {
  final MarketplaceAdminService _service;

  MarketplaceAdminController({MarketplaceAdminService? service})
      : _service = service ?? MarketplaceAdminService();

  final stats = Rxn<MarketplaceAdminDashboardStats>();
  final categories = <MarketplaceAdminCategory>[].obs;
  final products = <MarketplaceAdminProduct>[].obs;
  final orders = <MarketplaceAdminOrder>[].obs;
  final promotions = <MarketplaceAdminPromotion>[].obs;
  final rewards = <MarketplaceAdminReward>[].obs;
  final brands = <MarketplaceAdminBrand>[].obs;
  final variants = <MarketplaceAdminVariant>[].obs;
  final coupons = <MarketplaceAdminCoupon>[].obs;
  final providerMappings = <MarketplaceAdminProviderMapping>[].obs;
  final selectedVariantIds = <String>{}.obs;
  final settings = const MarketplaceAdminSettings().obs;
  final isLoading = false.obs;

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      stats.value = await _service.getDashboardStats();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    categories.value = await _service.getCategories();
    isLoading.value = false;
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    products.value = await _service.getProducts();
    isLoading.value = false;
  }

  Future<void> loadOrders() async {
    isLoading.value = true;
    orders.value = await _service.getOrders();
    isLoading.value = false;
  }

  Future<void> loadPromotions() async {
    isLoading.value = true;
    promotions.value = await _service.getPromotions();
    isLoading.value = false;
  }

  Future<void> loadRewards() async {
    isLoading.value = true;
    rewards.value = await _service.getRewards();
    isLoading.value = false;
  }

  Future<void> loadSettings() async {
    settings.value = await _service.getSettings();
  }

  Future<void> saveCategory(MarketplaceAdminCategory c) async {
    await _service.saveCategory(c);
    await loadCategories();
    Get.snackbar('نجاح', 'تم حفظ الفئة');
  }

  Future<void> deleteCategory(String id) async {
    await _service.deleteCategory(id);
    await loadCategories();
    Get.snackbar('نجاح', 'تم حذف الفئة');
  }

  Future<void> saveProduct(MarketplaceAdminProduct p) async {
    await _service.saveProduct(p);
    await loadProducts();
    Get.snackbar('نجاح', 'تم حفظ المنتج');
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
    await loadProducts();
    Get.snackbar('نجاح', 'تم حذف المنتج');
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _service.updateOrderStatus(id, status);
    await loadOrders();
    Get.snackbar('نجاح', 'تم تحديث حالة الطلب');
  }

  Future<void> savePromotion(MarketplaceAdminPromotion p) async {
    await _service.savePromotion(p);
    await loadPromotions();
    Get.snackbar('نجاح', 'تم حفظ العرض');
  }

  Future<void> deletePromotion(String id) async {
    await _service.deletePromotion(id);
    await loadPromotions();
    Get.snackbar('نجاح', 'تم حذف العرض');
  }

  Future<void> saveReward(MarketplaceAdminReward r) async {
    await _service.saveReward(r);
    await loadRewards();
    Get.snackbar('نجاح', 'تم حفظ المكافأة');
  }

  Future<void> deleteReward(String id) async {
    await _service.deleteReward(id);
    await loadRewards();
    Get.snackbar('نجاح', 'تم حذف المكافأة');
  }

  Future<void> updateSettings(MarketplaceAdminSettings s) async {
    settings.value = await _service.updateSettings(s);
    Get.snackbar('نجاح', 'تم حفظ الإعدادات');
  }

  Future<void> loadBrands() async {
    isLoading.value = true;
    brands.value = await _service.getBrands();
    isLoading.value = false;
  }

  Future<void> saveBrand(MarketplaceAdminBrand b) async {
    await _service.saveBrand(b);
    await loadBrands();
    Get.snackbar('نجاح', 'تم حفظ العلامة');
  }

  Future<void> deleteBrand(String id) async {
    await _service.deleteBrand(id);
    await loadBrands();
    Get.snackbar('نجاح', 'تم حذف العلامة');
  }

  Future<void> loadVariants() async {
    isLoading.value = true;
    variants.value = await _service.getVariants();
    isLoading.value = false;
  }

  Future<void> saveVariant(MarketplaceAdminVariant v) async {
    await _service.saveVariant(v);
    await loadVariants();
    Get.snackbar('نجاح', 'تم حفظ الباقة');
  }

  Future<void> deleteVariant(String id) async {
    await _service.deleteVariant(id);
    selectedVariantIds.remove(id);
    await loadVariants();
    Get.snackbar('نجاح', 'تم حذف الباقة');
  }

  void toggleVariantSelection(String id) {
    if (selectedVariantIds.contains(id)) {
      selectedVariantIds.remove(id);
    } else {
      selectedVariantIds.add(id);
    }
  }

  Future<void> bulkActivateVariants() async {
    if (selectedVariantIds.isEmpty) return;
    await _service.bulkSetVariantsActive(selectedVariantIds.toList(), true);
    selectedVariantIds.clear();
    await loadVariants();
    Get.snackbar('نجاح', 'تم تفعيل الباقات المحددة');
  }

  Future<void> bulkDeactivateVariants() async {
    if (selectedVariantIds.isEmpty) return;
    await _service.bulkSetVariantsActive(selectedVariantIds.toList(), false);
    selectedVariantIds.clear();
    await loadVariants();
    Get.snackbar('نجاح', 'تم إيقاف الباقات المحددة');
  }

  Future<void> bulkDeleteVariants() async {
    if (selectedVariantIds.isEmpty) return;
    await _service.bulkDeleteVariants(selectedVariantIds.toList());
    selectedVariantIds.clear();
    await loadVariants();
    Get.snackbar('نجاح', 'تم حذف الباقات المحددة');
  }

  Future<void> loadCoupons() async {
    isLoading.value = true;
    coupons.value = await _service.getCoupons();
    isLoading.value = false;
  }

  Future<void> saveCoupon(MarketplaceAdminCoupon c) async {
    await _service.saveCoupon(c);
    await loadCoupons();
    Get.snackbar('نجاح', 'تم حفظ الكوبون');
  }

  Future<void> deleteCoupon(String id) async {
    await _service.deleteCoupon(id);
    await loadCoupons();
    Get.snackbar('نجاح', 'تم حذف الكوبون');
  }

  Future<void> loadProviderMappings() async {
    isLoading.value = true;
    providerMappings.value = await _service.getProviderMappings();
    isLoading.value = false;
  }
}
