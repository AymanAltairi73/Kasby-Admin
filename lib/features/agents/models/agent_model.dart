/// Agent Model
class Agent {
  final String id;
  final String name;
  final String country;
  final String phone;
  final String email;
  final String status; // Active, Inactive
  final double successRate;
  final int totalTransactions;
  final DateTime createdAt;

  Agent({
    required this.id,
    required this.name,
    required this.country,
    required this.phone,
    required this.email,
    required this.status,
    required this.successRate,
    required this.totalTransactions,
    required this.createdAt,
  });

  static List<Agent> getMockAgents() {
    return [
      Agent(
        id: '1',
        name: 'وكيل السعودية - الرياض',
        country: 'السعودية',
        phone: '+966501234567',
        email: 'riyadh@kasby.com',
        status: 'Active',
        successRate: 98.5,
        totalTransactions: 1250,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      Agent(
        id: '2',
        name: 'وكيل الإمارات - دبي',
        country: 'الإمارات',
        phone: '+971501234567',
        email: 'dubai@kasby.com',
        status: 'Active',
        successRate: 97.2,
        totalTransactions: 980,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
      Agent(
        id: '3',
        name: 'وكيل الكويت',
        country: 'الكويت',
        phone: '+965501234567',
        email: 'kuwait@kasby.com',
        status: 'Active',
        successRate: 96.8,
        totalTransactions: 750,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      Agent(
        id: '4',
        name: 'وكيل مصر - القاهرة',
        country: 'مصر',
        phone: '+201001234567',
        email: 'cairo@kasby.com',
        status: 'Inactive',
        successRate: 85.3,
        totalTransactions: 320,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
    ];
  }
}
