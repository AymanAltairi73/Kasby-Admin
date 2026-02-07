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
  });

  static List<InvestmentPlan> getMockPlans() {
    return [
      InvestmentPlan(
        id: '1',
        nameAr: 'خطة استثمار الفضة',
        profitPercentage: 6.0,
        minAmount: 100,
        maxAmount: 500,
        availableAmounts: [100, 200, 300, 400, 500],
        descriptionAr: 'خطة استثمار متوسطة تهدف إلى نمو رأس المال بشكل مستقر.',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      InvestmentPlan(
        id: '2',
        nameAr: 'خطة استثمار الذهب',
        profitPercentage: 8.0,
        minAmount: 500,
        maxAmount: 2500,
        availableAmounts: [500, 1000, 1500, 2000, 2500],
        descriptionAr:
            'استثمار آمن في أصول الذهب مع حماية وتشفير عالي للبيانات.',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      InvestmentPlan(
        id: '3',
        nameAr: 'خطة استثمار العقارات',
        profitPercentage: 10.0,
        minAmount: 2000,
        maxAmount: 10000,
        descriptionAr:
            'أعلى العوائد من خلال الاستثمار في الأصول العقارية الموثوقة.',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
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
