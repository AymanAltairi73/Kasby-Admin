class MarketplaceAdminCategory {
  final String id;
  final String nameEn;
  final String nameAr;
  final String iconName;
  final int sortOrder;
  final bool isVisible;

  const MarketplaceAdminCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.iconName = 'category',
    this.sortOrder = 0,
    this.isVisible = true,
  });

  MarketplaceAdminCategory copyWith({
    String? nameEn,
    String? nameAr,
    String? iconName,
    int? sortOrder,
    bool? isVisible,
  }) =>
      MarketplaceAdminCategory(
        id: id,
        nameEn: nameEn ?? this.nameEn,
        nameAr: nameAr ?? this.nameAr,
        iconName: iconName ?? this.iconName,
        sortOrder: sortOrder ?? this.sortOrder,
        isVisible: isVisible ?? this.isVisible,
      );
}

class MarketplaceAdminProduct {
  final String id;
  final String nameEn;
  final String nameAr;
  final String categoryId;
  final String? imageUrl;
  final String descriptionEn;
  final String descriptionAr;
  final String providerSku;
  final double walletPrice;
  final double? kspPrice;
  final bool isFeatured;
  final bool isPopular;
  final bool isActive;
  final String stockStatus;

  const MarketplaceAdminProduct({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.categoryId,
    this.imageUrl,
    this.descriptionEn = '',
    this.descriptionAr = '',
    this.providerSku = '',
    required this.walletPrice,
    this.kspPrice,
    this.isFeatured = false,
    this.isPopular = false,
    this.isActive = true,
    this.stockStatus = 'inStock',
  });

  MarketplaceAdminProduct copyWith({
    String? nameEn,
    String? nameAr,
    String? categoryId,
    String? imageUrl,
    String? descriptionEn,
    String? descriptionAr,
    String? providerSku,
    double? walletPrice,
    double? kspPrice,
    bool? isFeatured,
    bool? isPopular,
    bool? isActive,
    String? stockStatus,
  }) =>
      MarketplaceAdminProduct(
        id: id,
        nameEn: nameEn ?? this.nameEn,
        nameAr: nameAr ?? this.nameAr,
        categoryId: categoryId ?? this.categoryId,
        imageUrl: imageUrl ?? this.imageUrl,
        descriptionEn: descriptionEn ?? this.descriptionEn,
        descriptionAr: descriptionAr ?? this.descriptionAr,
        providerSku: providerSku ?? this.providerSku,
        walletPrice: walletPrice ?? this.walletPrice,
        kspPrice: kspPrice ?? this.kspPrice,
        isFeatured: isFeatured ?? this.isFeatured,
        isPopular: isPopular ?? this.isPopular,
        isActive: isActive ?? this.isActive,
        stockStatus: stockStatus ?? this.stockStatus,
      );
}

class MarketplaceAdminOrder {
  final String id;
  final double totalAmount;
  final String status;
  final String productName;
  final DateTime createdAt;

  const MarketplaceAdminOrder({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.productName,
    required this.createdAt,
  });

  MarketplaceAdminOrder copyWith({String? status}) => MarketplaceAdminOrder(
        id: id,
        totalAmount: totalAmount,
        status: status ?? this.status,
        productName: productName,
        createdAt: createdAt,
      );
}

class MarketplaceAdminPromotion {
  final String id;
  final String type;
  final String titleEn;
  final String titleAr;
  final String? couponCode;
  final double? discountPercent;
  final bool isActive;

  const MarketplaceAdminPromotion({
    required this.id,
    required this.type,
    required this.titleEn,
    required this.titleAr,
    this.couponCode,
    this.discountPercent,
    this.isActive = true,
  });

  MarketplaceAdminPromotion copyWith({
    String? titleEn,
    String? titleAr,
    String? couponCode,
    double? discountPercent,
    bool? isActive,
  }) =>
      MarketplaceAdminPromotion(
        id: id,
        type: type,
        titleEn: titleEn ?? this.titleEn,
        titleAr: titleAr ?? this.titleAr,
        couponCode: couponCode ?? this.couponCode,
        discountPercent: discountPercent ?? this.discountPercent,
        isActive: isActive ?? this.isActive,
      );
}

class MarketplaceAdminReward {
  final String id;
  final String type;
  final String titleEn;
  final String titleAr;
  final double? kspAmount;
  final double? walletAmount;

  const MarketplaceAdminReward({
    required this.id,
    required this.type,
    required this.titleEn,
    required this.titleAr,
    this.kspAmount,
    this.walletAmount,
  });
}

class MarketplaceAdminSettings {
  final bool isEnabled;
  final bool walletPaymentEnabled;
  final bool kspPaymentEnabled;
  final bool maintenanceMode;

  const MarketplaceAdminSettings({
    this.isEnabled = true,
    this.walletPaymentEnabled = true,
    this.kspPaymentEnabled = true,
    this.maintenanceMode = false,
  });

  MarketplaceAdminSettings copyWith({
    bool? isEnabled,
    bool? walletPaymentEnabled,
    bool? kspPaymentEnabled,
    bool? maintenanceMode,
  }) =>
      MarketplaceAdminSettings(
        isEnabled: isEnabled ?? this.isEnabled,
        walletPaymentEnabled: walletPaymentEnabled ?? this.walletPaymentEnabled,
        kspPaymentEnabled: kspPaymentEnabled ?? this.kspPaymentEnabled,
        maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      );
}

class MarketplaceAdminDashboardStats {
  final int totalProducts;
  final int totalCategories;
  final int totalBrands;
  final int totalVariants;
  final int totalOrders;
  final double totalRevenue;
  final int pendingOrders;
  final List<MarketplaceAdminTopItem> topProducts;
  final List<MarketplaceAdminTopItem> topCategories;
  final MarketplaceAdminHealth health;

  const MarketplaceAdminDashboardStats({
    required this.totalProducts,
    required this.totalCategories,
    this.totalBrands = 0,
    this.totalVariants = 0,
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingOrders,
    this.topProducts = const [],
    this.topCategories = const [],
    this.health = const MarketplaceAdminHealth(),
  });
}

class MarketplaceAdminTopItem {
  final String id;
  final String name;
  final double value;

  const MarketplaceAdminTopItem({
    required this.id,
    required this.name,
    required this.value,
  });
}

class MarketplaceAdminHealth {
  final int activeVariants;
  final int inactiveVariants;
  final int unmappedVariants;
  final int activeCoupons;

  const MarketplaceAdminHealth({
    this.activeVariants = 0,
    this.inactiveVariants = 0,
    this.unmappedVariants = 0,
    this.activeCoupons = 0,
  });
}

class MarketplaceAdminBrand {
  final String id;
  final String categoryId;
  final String nameEn;
  final String nameAr;
  final String? logoUrl;
  final int sortOrder;
  final bool isActive;

  const MarketplaceAdminBrand({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    this.logoUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  MarketplaceAdminBrand copyWith({
    String? categoryId,
    String? nameEn,
    String? nameAr,
    String? logoUrl,
    int? sortOrder,
    bool? isActive,
  }) =>
      MarketplaceAdminBrand(
        id: id,
        categoryId: categoryId ?? this.categoryId,
        nameEn: nameEn ?? this.nameEn,
        nameAr: nameAr ?? this.nameAr,
        logoUrl: logoUrl ?? this.logoUrl,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
      );
}

class MarketplaceAdminVariant {
  final String id;
  final String productId;
  final String brandId;
  final String categoryId;
  final String nameEn;
  final String nameAr;
  final String providerSku;
  final double walletPrice;
  final double? kspPrice;
  final double? originalPrice;
  final bool isFeatured;
  final bool isActive;
  final int sortOrder;
  final String stockStatus;

  const MarketplaceAdminVariant({
    required this.id,
    required this.productId,
    required this.brandId,
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    this.providerSku = '',
    required this.walletPrice,
    this.kspPrice,
    this.originalPrice,
    this.isFeatured = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.stockStatus = 'inStock',
  });

  MarketplaceAdminVariant copyWith({
    String? nameEn,
    String? nameAr,
    String? providerSku,
    double? walletPrice,
    double? kspPrice,
    double? originalPrice,
    bool? isFeatured,
    bool? isActive,
    int? sortOrder,
    String? stockStatus,
  }) =>
      MarketplaceAdminVariant(
        id: id,
        productId: productId,
        brandId: brandId,
        categoryId: categoryId,
        nameEn: nameEn ?? this.nameEn,
        nameAr: nameAr ?? this.nameAr,
        providerSku: providerSku ?? this.providerSku,
        walletPrice: walletPrice ?? this.walletPrice,
        kspPrice: kspPrice ?? this.kspPrice,
        originalPrice: originalPrice ?? this.originalPrice,
        isFeatured: isFeatured ?? this.isFeatured,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
        stockStatus: stockStatus ?? this.stockStatus,
      );
}

class MarketplaceAdminCoupon {
  final String id;
  final String code;
  final String titleEn;
  final String titleAr;
  final double? discountPercent;
  final double? discountAmount;
  final bool isActive;

  const MarketplaceAdminCoupon({
    required this.id,
    required this.code,
    required this.titleEn,
    required this.titleAr,
    this.discountPercent,
    this.discountAmount,
    this.isActive = true,
  });

  MarketplaceAdminCoupon copyWith({
    String? code,
    String? titleEn,
    String? titleAr,
    double? discountPercent,
    double? discountAmount,
    bool? isActive,
  }) =>
      MarketplaceAdminCoupon(
        id: id,
        code: code ?? this.code,
        titleEn: titleEn ?? this.titleEn,
        titleAr: titleAr ?? this.titleAr,
        discountPercent: discountPercent ?? this.discountPercent,
        discountAmount: discountAmount ?? this.discountAmount,
        isActive: isActive ?? this.isActive,
      );
}

class MarketplaceAdminProviderMapping {
  final String id;
  final String variantId;
  final String variantName;
  final String providerName;
  final String providerProductId;
  final String providerSku;
  final String providerCategory;
  final String providerStatus;

  const MarketplaceAdminProviderMapping({
    required this.id,
    required this.variantId,
    required this.variantName,
    required this.providerName,
    required this.providerProductId,
    required this.providerSku,
    this.providerCategory = '',
    this.providerStatus = 'active',
  });
}
