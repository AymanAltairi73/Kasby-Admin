/// Subscription Plan Model — maps to `subscription_plans` table in Supabase
import '../../../core/services/app_logger_service.dart';

class SubscriptionPlan {
  final String id;
  final String tier; // 'free', 'premium' (inferred from price)
  final String technicalName;
  final String displayNameAr;
  final String displayNameEn;
  final double price;
  final String duration; // '1 Month', '1 Year', 'Lifetime'
  final double? discountPercentage;
  final int maxActiveInvestments;
  final int withdrawalProcessTime; // In hours
  final String status; // Active, Inactive
  final String icon;
  final List<String> features;
  final List<String> keywords;

  SubscriptionPlan({
    required this.id,
    required this.tier,
    required this.technicalName,
    required this.displayNameAr,
    required this.displayNameEn,
    required this.price,
    required this.duration,
    this.discountPercentage,
    required this.maxActiveInvestments,
    required this.withdrawalProcessTime,
    required this.status,
    required this.icon,
    required this.features,
    required this.keywords,
  });

  SubscriptionPlan copyWith({
    String? tier,
    String? technicalName,
    String? displayNameAr,
    String? displayNameEn,
    double? price,
    String? duration,
    double? discountPercentage,
    int? maxActiveInvestments,
    int? withdrawalProcessTime,
    String? status,
    String? icon,
    List<String>? features,
    List<String>? keywords,
  }) {
    return SubscriptionPlan(
      id: id,
      tier: tier ?? this.tier,
      technicalName: technicalName ?? this.technicalName,
      displayNameAr: displayNameAr ?? this.displayNameAr,
      displayNameEn: displayNameEn ?? this.displayNameEn,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      maxActiveInvestments: maxActiveInvestments ?? this.maxActiveInvestments,
      withdrawalProcessTime:
          withdrawalProcessTime ?? this.withdrawalProcessTime,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      features: features ?? this.features,
      keywords: keywords ?? this.keywords,
    );
  }

  /// Construct from Supabase `subscription_plans` row
  factory SubscriptionPlan.fromSupabase(Map<String, dynamic> json) {
    // Parse features from JSONB or Map
    List<String> feats = [];
    final rawFeatures = json['features'];
    if (rawFeatures is List) {
      feats = List<String>.from(rawFeatures.map((e) => e.toString()));
    } else if (rawFeatures is Map) {
      final items = rawFeatures['items'];
      if (items is List) feats = List<String>.from(items.map((e) => e.toString()));
    }

    final double priceMonthly = (json['price_monthly'] ?? 0.0).toDouble();
    final double priceYearly = (json['price_yearly'] ?? 0.0).toDouble();

    // Mapping logic for price and duration
    double usedPrice = 0.0;
    String usedDuration = 'Basic';
    String tier = 'free';

    if (priceYearly > 0) {
      usedPrice = priceYearly;
      usedDuration = '1 Year';
      tier = 'premium';
    } else if (priceMonthly > 0) {
      usedPrice = priceMonthly;
      usedDuration = '1 Month';
      tier = 'premium';
    } else {
      usedPrice = 0.0;
      usedDuration = 'Lifetime';
      tier = 'free';
    }

    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      tier: tier,
      technicalName: json['name'] ?? 'basic_plan',
      displayNameAr: json['display_name_ar'] ?? json['name'] ?? 'خطة أساسية',
      displayNameEn: json['display_name_en'] ?? json['name'] ?? 'Basic Plan',
      price: usedPrice,
      duration: usedDuration,
      maxActiveInvestments: tier == 'premium' ? 999 : 2,
      withdrawalProcessTime: tier == 'premium' ? 2 : 72,
      status: (json['is_active'] == true) ? 'Active' : 'Inactive',
      icon: json['icon'] ?? 'stars_rounded',
      features: feats,
      keywords: [],
    );
  }

  /// Legacy fromJson (Standard JSON)
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    try {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      tier: json['tier'] ?? 'free',
      technicalName: json['technicalName'] ?? '',
      displayNameAr: json['displayNameAr'] ?? '',
      displayNameEn: json['displayNameEn'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? '',
      discountPercentage: json['discountPercentage']?.toDouble(),
      maxActiveInvestments: json['maxActiveInvestments'] ?? 2,
      withdrawalProcessTime: json['withdrawalProcessTime'] ?? 72,
      status: json['status'] ?? 'Active',
      icon: json['icon'] ?? 'stars_rounded',
      features: List<String>.from(json['features'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
    );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'SubscriptionPlan',
        method: 'fromJson',
        feature: 'Subscriptions',
        status: 'FAILED',
        params: {'id': json['id']?.toString()},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier': tier,
      'technicalName': technicalName,
      'displayNameAr': displayNameAr,
      'displayNameEn': displayNameEn,
      'price': price,
      'duration': duration,
      'discountPercentage': discountPercentage,
      'maxActiveInvestments': maxActiveInvestments,
      'withdrawalProcessTime': withdrawalProcessTime,
      'status': status,
      'icon': icon,
      'features': features,
      'keywords': keywords,
    };
  }

  /// Supabase-compatible map for insert/update
  Map<String, dynamic> toSupabase() {
    final durationLower = duration.toLowerCase();
    return {
      'name': technicalName.isNotEmpty
          ? technicalName
          : (displayNameEn.isNotEmpty ? displayNameEn : displayNameAr),
      'price_monthly': durationLower.contains('month') ? price : 0,
      'price_yearly': durationLower.contains('year') ? price : 0,
      'features': {'items': features},
      'is_active': status.toLowerCase() == 'active',
    };
  }

  static List<SubscriptionPlan> getDefaultPlans() {
    return [
      SubscriptionPlan(
        id: '1',
        tier: 'free',
        technicalName: 'free_plan',
        displayNameAr: 'أساسي (BASIC)',
        displayNameEn: 'BASIC',
        price: 0.0,
        duration: 'Lifetime',
        maxActiveInvestments: 2,
        withdrawalProcessTime: 72,
        status: 'Active',
        icon: 'stars_rounded',
        features: [
          'سحوبات محدودة: تتم معالجة السحوبات خلال 48-72 ساعة.',
          'دعم قياسي: الوصول إلى مركز المساعدة والمجتمع فقط.',
          'استثمارات محدودة: متاح للمستخدم حتى (2) خطة استثمار نشطة فقط في نفس الوقت.',
        ],
        keywords: ['أساسي', 'يدوي', 'محدود', 'قياسي'],
      ),
      SubscriptionPlan(
        id: '2',
        tier: 'premium',
        technicalName: 'monthly_pro',
        displayNameAr: 'احترافي شهري (PRO Monthly)',
        displayNameEn: 'PRO Monthly',
        price: 9.0,
        duration: '1 Month',
        maxActiveInvestments: 999,
        withdrawalProcessTime: 2,
        status: 'Active',
        icon: 'stars_rounded',
        features: [
          'أولوية في السحب: معالجة سريعة لجميع طلبات السحب.',
          'استثمارات غير محدودة: لا توجد حدود لعدد خطط الاستثمار النشطة.',
          'هدايا حصرية: مكافآت وهدايا مفاجئة يتم إرسالها شهرياً.',
          'دعم ذو أولوية: وصول مباشر وفوري للدعم الفني (24/7).',
        ],
        keywords: ['متقدم', 'أولوية', 'غير محدود', 'متميز'],
      ),
      SubscriptionPlan(
        id: '3',
        tier: 'premium',
        technicalName: 'yearly_pro',
        displayNameAr: 'احترافي سنوي (PRO Yearly)',
        displayNameEn: 'PRO Yearly',
        price: 89.0,
        duration: '1 Year',
        discountPercentage: 20.0,
        maxActiveInvestments: 999,
        withdrawalProcessTime: 2,
        status: 'Active',
        icon: 'stars_rounded',
        features: [
          'أولوية في السحب: معالجة سريعة لجميع طلبات السحب.',
          'استثمارات غير محدودة: لا توجد حدود لعدد خطط الاستثمار النشطة.',
          'هدايا حصرية: مكافآت وهدايا مفاجئة يتم إرسالها شهرياً.',
          'دعم ذو أولوية: وصول مباشر وفوري للدعم الفني (24/7).',
        ],
        keywords: ['متقدم', 'أولوية', 'سنوي', 'توفير'],
      ),
    ];
  }
}
