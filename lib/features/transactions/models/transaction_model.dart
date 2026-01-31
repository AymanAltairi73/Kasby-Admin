/// Transaction Model
class Transaction {
  final String id;
  final String userId;
  final String userName;
  final String type; // Deposit, Withdrawal
  final double amount;
  final String status; // Pending, Approved, Rejected
  final String? reason;
  final String? proofUrl;
  final DateTime createdAt;
  final DateTime? processedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.amount,
    required this.status,
    this.reason,
    this.proofUrl,
    required this.createdAt,
    this.processedAt,
  });

  static List<Transaction> getMockTransactions() {
    return [
      Transaction(
        id: '1',
        userId: '1',
        userName: 'أحمد محمد',
        type: 'Deposit',
        amount: 1000,
        status: 'Pending',
        proofUrl: 'https://example.com/proof1.jpg',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Transaction(
        id: '2',
        userId: '4',
        userName: 'نورة عبدالله',
        type: 'Withdrawal',
        amount: 500,
        status: 'Pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Transaction(
        id: '3',
        userId: '2',
        userName: 'فاطمة علي',
        type: 'Deposit',
        amount: 2000,
        status: 'Approved',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        processedAt: DateTime.now().subtract(const Duration(hours: 20)),
      ),
      Transaction(
        id: '4',
        userId: '5',
        userName: 'عمر حسن',
        type: 'Withdrawal',
        amount: 750,
        status: 'Approved',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        processedAt: DateTime.now().subtract(
          const Duration(days: 1, hours: 12),
        ),
      ),
      Transaction(
        id: '5',
        userId: '3',
        userName: 'خالد سعيد',
        type: 'Deposit',
        amount: 300,
        status: 'Rejected',
        reason: 'إثبات الدفع غير واضح',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        processedAt: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
      ),
    ];
  }
}
