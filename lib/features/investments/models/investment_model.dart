/// Investment Plan Model — maps to `investment_plans` table in Supabase
class InvestmentPlan {
  final String id;
  final String nameAr;
  final String? nameEn;
  final double profitPercentage;
  final double minAmount;
  final double maxAmount;
  final List<double>? availableAmounts;
  final String descriptionAr;
  final bool isActive;
  final DateTime createdAt;
  final String? imagePath;
  final String? riskLevel;

  InvestmentPlan({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.profitPercentage,
    required this.minAmount,
    required this.maxAmount,
    this.availableAmounts,
    required this.descriptionAr,
    required this.isActive,
    required this.createdAt,
    this.imagePath,
    this.riskLevel,
  });

  InvestmentPlan copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    double? profitPercentage,
    double? minAmount,
    double? maxAmount,
    List<double>? availableAmounts,
    String? descriptionAr,
    bool? isActive,
    DateTime? createdAt,
    String? imagePath,
    String? riskLevel,
  }) {
    return InvestmentPlan(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      availableAmounts: availableAmounts ?? this.availableAmounts,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      imagePath: imagePath ?? this.imagePath,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }

  /// Construct from Supabase row
  factory InvestmentPlan.fromSupabase(Map<String, dynamic> json) {
    return InvestmentPlan(
      id: json['id'] ?? '',
      nameAr: json['name_ar'] ?? json['name'] ?? '',
      nameEn: json['name_en'],
      profitPercentage: (json['profit_percentage'] ?? 0.0).toDouble(),
      minAmount: (json['min_amount'] ?? 0.0).toDouble(),
      maxAmount: (json['max_amount'] ?? 0.0).toDouble(),
      availableAmounts: json['available_amounts'] != null
          ? List<double>.from(
              (json['available_amounts'] as List).map(
                (x) => (x as num).toDouble(),
              ),
            )
          : null,
      descriptionAr: json['description_ar'] ?? json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      imagePath: json['image_url'] ?? json['image_path'],
      riskLevel: json['risk_level'] != null ? _capitalize(json['risk_level']) : null,
    );
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return 'Medium';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Legacy fromJson
  factory InvestmentPlan.fromJson(Map<String, dynamic> json) {
    return InvestmentPlan(
      id: json['id'] ?? '',
      nameAr: json['nameAr'] ?? json['name_ar'] ?? '',
      nameEn: json['nameEn'] ?? json['name_en'],
      profitPercentage:
          (json['profitPercentage'] ?? json['profit_percentage'] ?? 0.0)
              .toDouble(),
      minAmount: (json['minAmount'] ?? json['min_amount'] ?? 0.0).toDouble(),
      maxAmount: (json['maxAmount'] ?? json['max_amount'] ?? 0.0).toDouble(),
      availableAmounts: json['availableAmounts'] != null
          ? List<double>.from(json['availableAmounts'].map((x) => x.toDouble()))
          : null,
      descriptionAr: json['descriptionAr'] ?? json['description_ar'] ?? '',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      imagePath: json['imagePath'] ?? json['image_path'] ?? json['image_url'],
      riskLevel: (json['riskLevel'] ?? json['risk_level']) != null
          ? _capitalize(json['riskLevel'] ?? json['risk_level'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'profitPercentage': profitPercentage,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'availableAmounts': availableAmounts,
      'descriptionAr': descriptionAr,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'imagePath': imagePath,
      'riskLevel': riskLevel,
    };
  }

  /// Supabase-compatible map for insert/update
  Map<String, dynamic> toSupabase() {
    return {
      'name_ar': nameAr,
      'name_en': nameEn,
      'profit_percentage': profitPercentage,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'is_active': isActive,
      'description_ar': descriptionAr,
      'image_url': imagePath,
      'risk_level': riskLevel,
      'available_amounts': availableAmounts,
    };
  }
}

/// User Investment Model — maps to `user_investments` table in Supabase
class UserInvestment {
  final String id;
  final String userId;
  final String userName;
  final String planId;
  final String planName;
  final double amount;
  final double profitPercentage;
  final double expectedProfit;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active, matured, cancelled

  UserInvestment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.profitPercentage,
    required this.expectedProfit,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  UserInvestment copyWith({
    String? userName,
    String? planName,
    double? amount,
    double? profitPercentage,
    double? expectedProfit,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return UserInvestment(
      id: id,
      userId: userId,
      userName: userName ?? this.userName,
      planId: planId,
      planName: planName ?? this.planName,
      amount: amount ?? this.amount,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      expectedProfit: expectedProfit ?? this.expectedProfit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

  /// Construct from Supabase row with nested profiles + investment_plans
  factory UserInvestment.fromSupabase(Map<String, dynamic> json) {
    String uName = '';
    final profile = json['profiles'];
    if (profile is Map) {
      uName = profile['full_name'] ?? '';
    }
    String pName = '';
    final plan = json['investment_plans'];
    if (plan is Map) {
      pName = plan['name_ar'] ?? plan['name'] ?? '';
    }

    return UserInvestment(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: uName,
      planId: json['plan_id'] ?? '',
      planName: pName,
      amount: (json['amount'] ?? 0.0).toDouble(),
      profitPercentage: (json['profit_percentage'] ?? 0.0).toDouble(),
      expectedProfit: (json['expected_profit'] ?? 0.0).toDouble(),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      status: json['status'] ?? 'active',
    );
  }

  /// Legacy fromJson
  factory UserInvestment.fromJson(Map<String, dynamic> json) {
    return UserInvestment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? '',
      planId: json['planId'] ?? json['plan_id'] ?? '',
      planName: json['planName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      profitPercentage:
          (json['profitPercentage'] ?? json['profit_percentage'] ?? 0.0)
              .toDouble(),
      expectedProfit: (json['expectedProfit'] ?? json['expected_profit'] ?? 0.0)
          .toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : (json['start_date'] != null
                ? DateTime.parse(json['start_date'])
                : DateTime.now()),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : (json['end_date'] != null
                ? DateTime.parse(json['end_date'])
                : DateTime.now()),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'planId': planId,
      'planName': planName,
      'amount': amount,
      'profitPercentage': profitPercentage,
      'expectedProfit': expectedProfit,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
    };
  }
}
