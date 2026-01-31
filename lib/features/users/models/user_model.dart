/// Mock User Model
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status; // Active, Blocked
  final double walletBalance;
  final double investedAmount;
  final double pendingAmount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.walletBalance,
    required this.investedAmount,
    required this.pendingAmount,
    required this.createdAt,
  });

  // Mock data generator
  static List<User> getMockUsers() {
    return [
      User(
        id: '1',
        name: 'أحمد محمد',
        email: 'ahmed@example.com',
        phone: '+966501234567',
        status: 'Active',
        walletBalance: 5000.0,
        investedAmount: 15000.0,
        pendingAmount: 500.0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      User(
        id: '2',
        name: 'فاطمة علي',
        email: 'fatima@example.com',
        phone: '+966507654321',
        status: 'Active',
        walletBalance: 3200.0,
        investedAmount: 8000.0,
        pendingAmount: 0.0,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      User(
        id: '3',
        name: 'خالد سعيد',
        email: 'khaled@example.com',
        phone: '+966509876543',
        status: 'Blocked',
        walletBalance: 0.0,
        investedAmount: 0.0,
        pendingAmount: 0.0,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      User(
        id: '4',
        name: 'نورة عبدالله',
        email: 'noura@example.com',
        phone: '+966502345678',
        status: 'Active',
        walletBalance: 12000.0,
        investedAmount: 25000.0,
        pendingAmount: 1200.0,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      User(
        id: '5',
        name: 'عمر حسن',
        email: 'omar@example.com',
        phone: '+966508765432',
        status: 'Active',
        walletBalance: 7500.0,
        investedAmount: 18000.0,
        pendingAmount: 300.0,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }
}
