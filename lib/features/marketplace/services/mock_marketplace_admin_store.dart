import '../models/marketplace_admin_models.dart';

/// Shared in-memory mock store for admin marketplace management.
/// TODO: Replace this mock endpoint with the production Marketplace Provider API.
class MockMarketplaceAdminStore {
  MockMarketplaceAdminStore._();

  static MarketplaceAdminSettings settings = const MarketplaceAdminSettings();

  static final categories = <MarketplaceAdminCategory>[
    const MarketplaceAdminCategory(id: 'cat_games', nameEn: 'Games', nameAr: 'الألعاب', iconName: 'sports_esports', sortOrder: 1),
    const MarketplaceAdminCategory(id: 'cat_gift_cards', nameEn: 'Gift Cards', nameAr: 'بطاقات الهدايا', iconName: 'card_giftcard', sortOrder: 2),
    const MarketplaceAdminCategory(id: 'cat_subscriptions', nameEn: 'Subscriptions', nameAr: 'الاشتراكات', iconName: 'subscriptions', sortOrder: 3),
    const MarketplaceAdminCategory(id: 'cat_digital_services', nameEn: 'Digital Services', nameAr: 'الخدمات الرقمية', iconName: 'wifi', sortOrder: 4),
    const MarketplaceAdminCategory(id: 'cat_rewards', nameEn: 'Rewards', nameAr: 'المكافآت', iconName: 'emoji_events', sortOrder: 5),
    const MarketplaceAdminCategory(id: 'cat_ksp_exclusive', nameEn: 'KSP Exclusive', nameAr: 'حصري KSP', iconName: 'diamond', sortOrder: 6),
    const MarketplaceAdminCategory(id: 'cat_featured', nameEn: 'Featured Offers', nameAr: 'عروض مميزة', iconName: 'star', sortOrder: 7),
    const MarketplaceAdminCategory(id: 'cat_new_arrivals', nameEn: 'New Arrivals', nameAr: 'وصل حديثاً', iconName: 'new_releases', sortOrder: 8),
  ];

  static final brands = <MarketplaceAdminBrand>[
    const MarketplaceAdminBrand(id: 'brand_pubg', categoryId: 'cat_games', nameEn: 'PUBG Mobile', nameAr: 'PUBG Mobile', sortOrder: 1),
    const MarketplaceAdminBrand(id: 'brand_google', categoryId: 'cat_gift_cards', nameEn: 'Google Play', nameAr: 'Google Play', sortOrder: 1),
    const MarketplaceAdminBrand(id: 'brand_netflix', categoryId: 'cat_subscriptions', nameEn: 'Netflix', nameAr: 'Netflix', sortOrder: 1),
  ];

  static final variants = <MarketplaceAdminVariant>[
    const MarketplaceAdminVariant(id: 'var_pubg_300', productId: 'prod_pubg_uc', brandId: 'brand_pubg', categoryId: 'cat_games', nameEn: '300 UC', nameAr: '300 UC', providerSku: 'MOCK-PUBG-300', walletPrice: 4.49, kspPrice: 220, isFeatured: true),
    const MarketplaceAdminVariant(id: 'var_gp_10', productId: 'prod_gp', brandId: 'brand_google', categoryId: 'cat_gift_cards', nameEn: '\$10', nameAr: '10\$', providerSku: 'MOCK-GP-10', walletPrice: 10, kspPrice: 500),
    const MarketplaceAdminVariant(id: 'var_nf_1m', productId: 'prod_netflix', brandId: 'brand_netflix', categoryId: 'cat_subscriptions', nameEn: '1 Month', nameAr: 'شهر', providerSku: 'MOCK-NF-1M', walletPrice: 12.99, kspPrice: 650, isFeatured: true),
  ];

  static final coupons = <MarketplaceAdminCoupon>[
    const MarketplaceAdminCoupon(id: 'cpn_1', code: 'KASBY10', titleEn: '10% Off', titleAr: 'خصم 10%', discountPercent: 10),
    const MarketplaceAdminCoupon(id: 'cpn_2', code: 'SAVE5', titleEn: '\$5 Off', titleAr: 'خصم 5\$', discountAmount: 5),
    const MarketplaceAdminCoupon(id: 'cpn_3', code: 'WELCOME', titleEn: 'Welcome Offer', titleAr: 'عرض ترحيبي', discountPercent: 15, isActive: false),
  ];

  static final providerMappings = <MarketplaceAdminProviderMapping>[
    const MarketplaceAdminProviderMapping(id: 'map_1', variantId: 'var_pubg_300', variantName: 'PUBG — 300 UC', providerName: 'mock', providerProductId: 'MOCK-PUBG-300', providerSku: 'MOCK-PUBG-300', providerCategory: 'games'),
    const MarketplaceAdminProviderMapping(id: 'map_2', variantId: 'var_gp_10', variantName: 'Google Play — \$10', providerName: 'mock', providerProductId: 'MOCK-GP-10', providerSku: 'MOCK-GP-10', providerCategory: 'gift_cards'),
  ];

  static final products = <MarketplaceAdminProduct>[
    MarketplaceAdminProduct(id: 'pubg_300', nameEn: 'PUBG 300 UC', nameAr: 'PUBG 300 UC', categoryId: 'cat_games', walletPrice: 4.49, kspPrice: 220, isFeatured: true, isPopular: true, providerSku: 'MOCK-PUBG-300'),
    MarketplaceAdminProduct(id: 'google_play_10', nameEn: 'Google Play \$10', nameAr: 'Google Play 10\$', categoryId: 'cat_gift_cards', walletPrice: 10, kspPrice: 500, isPopular: true, providerSku: 'MOCK-GP-10'),
    MarketplaceAdminProduct(id: 'netflix_1m', nameEn: 'Netflix 1 Month', nameAr: 'Netflix شهر', categoryId: 'cat_subscriptions', walletPrice: 12.99, kspPrice: 650, isFeatured: true, providerSku: 'MOCK-NF-1M'),
    MarketplaceAdminProduct(id: 'steam_20', nameEn: 'Steam Wallet \$20', nameAr: 'Steam 20\$', categoryId: 'cat_gift_cards', walletPrice: 20, kspPrice: 1000, providerSku: 'MOCK-ST-20'),
    MarketplaceAdminProduct(id: 'ksp_bundle_gaming', nameEn: 'KSP Gaming Bundle', nameAr: 'حزمة KSP للألعاب', categoryId: 'cat_ksp_exclusive', walletPrice: 14.99, kspPrice: 750, isFeatured: true, providerSku: 'MOCK-KSP-GAME'),
  ];

  static final promotions = <MarketplaceAdminPromotion>[
    const MarketplaceAdminPromotion(id: 'promo_1', type: 'banner', titleEn: 'Summer Gaming Sale', titleAr: 'تخفيضات الألعاب', isActive: true),
    const MarketplaceAdminPromotion(id: 'promo_2', type: 'coupon', titleEn: 'KASBY10', titleAr: 'KASBY10', couponCode: 'KASBY10', discountPercent: 10, isActive: true),
  ];

  static final rewards = <MarketplaceAdminReward>[
    const MarketplaceAdminReward(id: 'rw_1', type: 'daily', titleEn: 'Daily Login Bonus', titleAr: 'مكافأة يومية', kspAmount: 25),
    const MarketplaceAdminReward(id: 'rw_2', type: 'ksp', titleEn: 'KSP Elite Reward', titleAr: 'مكافأة KSP', kspAmount: 100),
  ];

  static final orders = <MarketplaceAdminOrder>[
    MarketplaceAdminOrder(id: 'ord_001', totalAmount: 4.49, status: 'completed', productName: 'PUBG 300 UC', createdAt: DateTime.now().subtract(const Duration(days: 2))),
    MarketplaceAdminOrder(id: 'ord_002', totalAmount: 20, status: 'processing', productName: 'Google Play \$10 x2', createdAt: DateTime.now().subtract(const Duration(hours: 5))),
    MarketplaceAdminOrder(id: 'ord_003', totalAmount: 12.99, status: 'pending', productName: 'Netflix 1 Month', createdAt: DateTime.now().subtract(const Duration(minutes: 30))),
  ];
}
