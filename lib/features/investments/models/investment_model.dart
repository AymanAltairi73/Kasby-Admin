/// Investment Plan Model
class InvestmentPlan {
  final String id;
  final String name;
  final String nameAr;
  final double profitPercentage;
  final int durationDays;
  final double minAmount;
  final double maxAmount;
  final bool isActive;
  final DateTime createdAt;

  InvestmentPlan({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.profitPercentage,
    required this.durationDays,
    required this.minAmount,
    required this.maxAmount,
    required this.isActive,
    required this.createdAt,
  });

  static List<InvestmentPlan> getMockPlans() {
    return [
      InvestmentPlan(
        id: '2',
        name: 'Silver Plan',
        nameAr: 'الخطة الفضية',
        profitPercentage: 8.5,
        durationDays: 60,
        minAmount: 1000,
        maxAmount: 5000,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      InvestmentPlan(
        id: '3',
        name: 'Gold Plan',
        nameAr: 'الخطة الذهبية',
        profitPercentage: 12.0,
        durationDays: 90,
        minAmount: 5000,
        maxAmount: 20000,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
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
