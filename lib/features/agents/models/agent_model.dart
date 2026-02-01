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
        name: 'وكيل بغداد - الكرخ',
        country: 'العراق',
        phone: '+9647701234567',
        email: 'baghdad@kasby.com',
        status: 'Active',
        successRate: 98.5,
        totalTransactions: 1250,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      Agent(
        id: '2',
        name: 'وكيل أربيل - عينكاوة',
        country: 'العراق',
        phone: '+9647501234567',
        email: 'erbil@kasby.com',
        status: 'Active',
        successRate: 97.2,
        totalTransactions: 980,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
      Agent(
        id: '3',
        name: 'وكيل البصرة - العشار',
        country: 'العراق',
        phone: '+9647801234567',
        email: 'basra@kasby.com',
        status: 'Active',
        successRate: 96.8,
        totalTransactions: 750,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      Agent(
        id: '4',
        name: 'وكيل الموصل - الجانب الأيسر',
        country: 'العراق',
        phone: '+9647711234567',
        email: 'mosul@kasby.com',
        status: 'Inactive',
        successRate: 85.3,
        totalTransactions: 320,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      Agent(
        id: '5',
        name: 'وكيل النجف الأشرف',
        country: 'العراق',
        phone: '+9647811234567',
        email: 'najaf@kasby.com',
        status: 'Active',
        successRate: 99.1,
        totalTransactions: 1500,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      ),
    ];
  }
}
