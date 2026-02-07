/// Agent Model
class Agent {
  final String id;
  final String name;
  final String country;
  final String city;
  final String phone;
  final String email;
  final String status; // Active, Inactive
  final bool isAvailableNow;
  final List<String> supportedMethods; // WhatsApp, Telegram, Call
  final double successRate;
  final int totalTransactions;
  final DateTime createdAt;

  Agent({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.phone,
    required this.email,
    required this.status,
    required this.isAvailableNow,
    required this.supportedMethods,
    required this.successRate,
    required this.totalTransactions,
    required this.createdAt,
  });

  static List<Agent> getMockAgents() {
    return [
      Agent(
        id: '1',
        name: 'وكيل بغداد المعتمد',
        country: 'العراق',
        city: 'بغداد',
        phone: '+9647701234567',
        email: 'baghdad@kasby.com',
        status: 'Active',
        isAvailableNow: true,
        supportedMethods: ['WhatsApp', 'Telegram', 'Call'],
        successRate: 98.5,
        totalTransactions: 1250,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      Agent(
        id: '2',
        name: 'وكيل البصرة المعتمد',
        country: 'العراق',
        city: 'البصرة',
        phone: '+9647801234567',
        email: 'basra@kasby.com',
        status: 'Active',
        isAvailableNow: true,
        supportedMethods: ['WhatsApp', 'Telegram', 'Call'],
        successRate: 98.5,
        totalTransactions: 980,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
      Agent(
        id: '3',
        name: 'وكيل أربيل المعتمد',
        country: 'العراق',
        city: 'أربيل',
        phone: '+9647501234567',
        email: 'erbil@kasby.com',
        status: 'Active',
        isAvailableNow: true,
        supportedMethods: ['WhatsApp', 'Telegram', 'Call'],
        successRate: 98.5,
        totalTransactions: 750,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      Agent(
        id: '4',
        name: 'وكيل كربلاء المعتمد',
        country: 'العراق',
        city: 'كربلاء',
        phone: '+9647711234567',
        email: 'karbala@kasby.com',
        status: 'Active',
        isAvailableNow: true,
        supportedMethods: ['WhatsApp', 'Telegram', 'Call'],
        successRate: 98.5,
        totalTransactions: 320,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      Agent(
        id: '5',
        name: 'وكيل النجف الأشرف المعتمد',
        country: 'العراق',
        city: 'النجف الأشرف',
        phone: '+9647811234567',
        email: 'najaf@kasby.com',
        status: 'Active',
        isAvailableNow: true,
        supportedMethods: ['WhatsApp', 'Telegram', 'Call'],
        successRate: 98.5,
        totalTransactions: 1500,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      ),
    ];
  }
}
