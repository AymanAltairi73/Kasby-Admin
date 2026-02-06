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

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? status,
    double? walletBalance,
    double? investedAmount,
    double? pendingAmount,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      walletBalance: walletBalance ?? this.walletBalance,
      investedAmount: investedAmount ?? this.investedAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Mock data generator
  static List<User> getMockUsers() {
    final now = DateTime.now();
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
        createdAt: now.subtract(const Duration(minutes: 30)), // Today
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
        createdAt: now.subtract(const Duration(days: 2)), // This Week
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
        createdAt: now.subtract(const Duration(days: 10)), // This Month
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
        createdAt: now.subtract(const Duration(hours: 5)), // Today
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
        createdAt: now.subtract(const Duration(days: 4)), // This Week
      ),
      User(
        id: '6',
        name: 'ليلى يوسف',
        email: 'layla@example.com',
        phone: '+966501112223',
        status: 'Active',
        walletBalance: 1500.0,
        investedAmount: 5000.0,
        pendingAmount: 100.0,
        createdAt: now.subtract(const Duration(days: 40)), // Older
      ),
    ];
  }
}
