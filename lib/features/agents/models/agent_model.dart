/// Agent Model
class Agent {
  final String id;
  final String name;
  final String country;
  final String province; // New
  final String city;
  final String address; // New
  final String phone;
  final String whatsapp; // New
  final String telegram; // New
  final String email;
  final String status; // Active, Inactive
  final bool isAvailableNow;
  final List<String> supportedMethods; // WhatsApp, Telegram, Call
  final double successRate;
  final int totalTransactions;
  final String notes; // New
  final DateTime createdAt;

  Agent({
    required this.id,
    required this.name,
    required this.country,
    required this.province,
    required this.city,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.telegram,
    required this.email,
    required this.status,
    required this.isAvailableNow,
    required this.supportedMethods,
    required this.successRate,
    required this.totalTransactions,
    this.notes = '',
    required this.createdAt,
  });

  Agent copyWith({
    String? name,
    String? country,
    String? province,
    String? city,
    String? address,
    String? phone,
    String? whatsapp,
    String? telegram,
    String? email,
    String? status,
    bool? isAvailableNow,
    List<String>? supportedMethods,
    double? successRate,
    int? totalTransactions,
    String? notes,
    DateTime? createdAt,
  }) {
    return Agent(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      telegram: telegram ?? this.telegram,
      email: email ?? this.email,
      status: status ?? this.status,
      isAvailableNow: isAvailableNow ?? this.isAvailableNow,
      supportedMethods: supportedMethods ?? this.supportedMethods,
      successRate: successRate ?? this.successRate,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? (json['phone'] ?? ''),
      telegram: json['telegram'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'Active',
      isAvailableNow: json['isAvailableNow'] ?? false,
      supportedMethods: List<String>.from(json['supportedMethods'] ?? []),
      successRate: (json['successRate'] ?? 0.0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'province': province,
      'city': city,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'telegram': telegram,
      'email': email,
      'status': status,
      'isAvailableNow': isAvailableNow,
      'supportedMethods': supportedMethods,
      'successRate': successRate,
      'totalTransactions': totalTransactions,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<Agent> getMockAgents() {
    return [
      Agent(
        id: '1',
        name: 'وكيل بغداد',
        country: 'العراق',
        province: 'بغداد',
        city: 'بغداد',
        address: 'شارع المنصور، قرب المتنبي',
        phone: '+9647701234567',
        whatsapp: '+9647701234567',
        telegram: 'baghdad_agent',
        email: 'baghdad@kasby.com',
        status: 'Active',
        isAvailableNow: true,
        supportedMethods: ['WhatsApp', 'Telegram', 'Call'],
        successRate: 98.5,
        totalTransactions: 1250,
        notes: 'وكيل معتمد في منطقة المنصور، يتميز بسرعة الاستجابة.',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      Agent(
        id: '2',
        name: 'وكيل البصرة',
        country: 'العراق',
        province: 'البصرة',
        city: 'البصرة',
        address: 'شارع الجزائر، المعقل',
        phone: '+9647801234567',
        whatsapp: '+9647801234567',
        telegram: 'basra_agent',
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
        name: 'وكيل أربيل',
        country: 'العراق',
        province: 'أربيل',
        city: 'أربيل',
        address: 'طريق عينكاوة، حي بختياري',
        phone: '+9647501234567',
        whatsapp: '+9647501234567',
        telegram: 'erbil_agent',
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
        name: 'وكيل كربلاء',
        country: 'العراق',
        province: 'كربلاء',
        city: 'كربلاء',
        address: 'حي البلدي، مقابل القبلة',
        phone: '+9647711234567',
        whatsapp: '+9647711234567',
        telegram: 'karbala_agent',
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
        name: 'وكيل النجف الأشرف',
        country: 'العراق',
        province: 'النجف',
        city: 'النجف الأشرف',
        address: 'حي السعد، شارع الكوفة',
        phone: '+9647811234567',
        whatsapp: '+9647811234567',
        telegram: 'najaf_agent',
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
