/// Investment Plan Model
class InvestmentPlan {
  final String id;
  final String nameAr;
  final double profitPercentage;
  final double minAmount;
  final double maxAmount;
  final List<double>? availableAmounts;
  final String descriptionAr;
  final bool isActive;
  final DateTime createdAt;
  final String? imagePath;

  InvestmentPlan({
    required this.id,
    required this.nameAr,
    required this.profitPercentage,
    required this.minAmount,
    required this.maxAmount,
    this.availableAmounts,
    required this.descriptionAr,
    required this.isActive,
    required this.createdAt,
    this.imagePath,
  });

  InvestmentPlan copyWith({
    String? id,
    String? nameAr,
    double? profitPercentage,
    double? minAmount,
    double? maxAmount,
    List<double>? availableAmounts,
    String? descriptionAr,
    bool? isActive,
    DateTime? createdAt,
    String? imagePath,
  }) {
    return InvestmentPlan(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      availableAmounts: availableAmounts ?? this.availableAmounts,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  factory InvestmentPlan.fromJson(Map<String, dynamic> json) {
    return InvestmentPlan(
      id: json['id'] ?? '',
      nameAr: json['nameAr'] ?? '',
      profitPercentage: (json['profitPercentage'] ?? 0.0).toDouble(),
      minAmount: (json['minAmount'] ?? 0.0).toDouble(),
      maxAmount: (json['maxAmount'] ?? 0.0).toDouble(),
      availableAmounts: json['availableAmounts'] != null
          ? List<double>.from(json['availableAmounts'].map((x) => x.toDouble()))
          : null,
      descriptionAr: json['descriptionAr'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      imagePath: json['imagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'profitPercentage': profitPercentage,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'availableAmounts': availableAmounts,
      'descriptionAr': descriptionAr,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  static List<InvestmentPlan> getMockPlans() {
    return [
      InvestmentPlan(
        id: '1',
        nameAr: 'خطة الفضة',
        profitPercentage: 6.0,
        minAmount: 100,
        maxAmount: 500,
        availableAmounts: [100, 200, 300, 400, 500],
        descriptionAr: 'خطة استثمار متوسطة تهدف إلى نمو رأس المال بشكل مستقر.',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        imagePath: 'assets/images/sliver.png',
      ),
      InvestmentPlan(
        id: '2',
        nameAr: 'خطة الذهب',
        profitPercentage: 12.0,
        minAmount: 500,
        maxAmount: 2500,
        availableAmounts: [500, 1000, 1500, 2000, 2500],
        descriptionAr:
            'استثمار آمن في أصول الذهب مع حماية وتشفير عالي للبيانات.',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        imagePath: 'assets/images/gold.png',
      ),
      InvestmentPlan(
        id: '3',
        nameAr: 'خطة العقارات',
        profitPercentage: 18.0,
        minAmount: 2000,
        maxAmount: 10000,
        descriptionAr:
            'أعلى العوائد من خلال الاستثمار في الأصول العقارية الموثوقة.',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        imagePath: 'assets/images/real_estate.png',
      ),
    ];
  }
}

/// User Investment Model
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
  final String status; // Active, Completed, Cancelled

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

  factory UserInvestment.fromJson(Map<String, dynamic> json) {
    return UserInvestment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      profitPercentage: (json['profitPercentage'] ?? 0.0).toDouble(),
      expectedProfit: (json['expectedProfit'] ?? 0.0).toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      status: json['status'] ?? 'Active',
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

  static List<UserInvestment> getMockInvestments() {
    return [
      UserInvestment(
        id: '1',
        userId: '1',
        userName: 'أحمد محمد',
        planId: '2',
        planName: 'الخطة الفضية',
        amount: 3000,
        profitPercentage: 8.5,
        expectedProfit: 255,
        startDate: DateTime.now().subtract(const Duration(days: 20)),
        endDate: DateTime.now().add(const Duration(days: 40)),
        status: 'Active',
      ),
      UserInvestment(
        id: '2',
        userId: '4',
        userName: 'نورة عبدالله',
        planId: '3',
        planName: 'الخطة الذهبية',
        amount: 10000,
        profitPercentage: 12.0,
        expectedProfit: 1200,
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        endDate: DateTime.now().add(const Duration(days: 45)),
        status: 'Active',
      ),
    ];
  }
}
