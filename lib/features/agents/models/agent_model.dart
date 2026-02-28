/// Agent Model — maps to `agents` table in Supabase
class Agent {
  final String id;
  final String name;
  final String country;
  final String province;
  final String city;
  final String address;
  final String phone;
  final String whatsapp;
  final String telegram;
  final String email;
  final String status; // Active, Inactive
  final bool isAvailableNow;
  final List<String> supportedMethods; // WhatsApp, Telegram, Call
  final double successRate;
  final int totalTransactions;
  final String notes;
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

  /// Construct from Supabase row
  /// Updated: supported_methods is now JSONB in kasby_new.sql
  factory Agent.fromSupabase(Map<String, dynamic> json) {
    // Parse supported_methods from JSONB (can be array, string, or null)
    List<String> parseSupportedMethods(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return List<String>.from(value.map((e) => e.toString()));
      }
      if (value is String) return [value];
      return [];
    }

    return Agent(
      id: json['id'] ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      country: json['country'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? (json['phone'] ?? ''),
      telegram: json['telegram'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'active',
      isAvailableNow: json['is_available_now'] ?? false,
      supportedMethods: parseSupportedMethods(json['supported_methods']),
      successRate: (json['success_rate'] ?? 0.0).toDouble(),
      totalTransactions: json['total_transactions'] ?? 0,
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Legacy fromJson for backward compat
  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      country: json['country'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? (json['phone'] ?? ''),
      telegram: json['telegram'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'Active',
      isAvailableNow:
          json['isAvailableNow'] ?? json['is_available_now'] ?? false,
      supportedMethods: List<String>.from(
        json['supportedMethods'] ?? json['supported_methods'] ?? [],
      ),
      successRate: (json['successRate'] ?? json['success_rate'] ?? 0.0)
          .toDouble(),
      totalTransactions:
          json['totalTransactions'] ?? json['total_transactions'] ?? 0,
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
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

  /// Convert to Supabase-compatible map for insert/update
  /// Note: agents table in kasby_new.sql uses column 'name' not 'full_name'
  Map<String, dynamic> toSupabase() {
    return {
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
      'is_available_now': isAvailableNow,
      'supported_methods': supportedMethods, // JSONB in kasby_new.sql
    };
  }
}
