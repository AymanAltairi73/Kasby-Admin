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
        id: '1',
        name: 'Basic Plan',
        nameAr: 'الخطة الأساسية',
        profitPercentage: 5.0,
        durationDays: 30,
        minAmount: 100,
        maxAmount: 1000,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
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
      InvestmentPlan(
        id: '4',
        name: 'Platinum Plan',
        nameAr: 'الخطة البلاتينية',
        profitPercentage: 15.0,
        durationDays: 180,
        minAmount: 20000,
        maxAmount: 100000,
        isActive: false,
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
      UserInvestment(
        id: '3',
        userId: '2',
        userName: 'فاطمة علي',
        planId: '1',
        planName: 'الخطة الأساسية',
        amount: 500,
        profitPercentage: 5.0,
        expectedProfit: 25,
        startDate: DateTime.now().subtract(const Duration(days: 35)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        status: 'Completed',
      ),
    ];
  }
}
