import 'user_activity_model.dart';

/// Mock User Model
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status; // Active, Blocked
  final String country;
  final String province; // New
  final String city; // New
  final String address; // New
  final String accountType; // Free, Verified, VIP // New
  final String kycStatus; // Unverified, Pending, Verified // New
  final double walletBalance;
  final double investedAmount;
  final double pendingAmount;
  final DateTime createdAt;
  final String whatsapp; // New
  final String telegram; // New
  final List<String> documents; // List of document URLs (images) // New
  final List<UserActivity> activityLog; // User history // New

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.country,
    required this.province,
    required this.city,
    required this.address,
    required this.accountType,
    required this.kycStatus,
    required this.walletBalance,
    required this.investedAmount,
    required this.pendingAmount,
    required this.createdAt,
    this.whatsapp = '',
    this.telegram = '',
    this.documents = const [],
    this.activityLog = const [],
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? status,
    String? country,
    String? province,
    String? city,
    String? address,
    String? accountType,
    String? kycStatus,
    double? walletBalance,
    double? investedAmount,
    double? pendingAmount,
    DateTime? createdAt,
    String? whatsapp,
    String? telegram,
    List<String>? documents,
    List<UserActivity>? activityLog,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      address: address ?? this.address,
      accountType: accountType ?? this.accountType,
      kycStatus: kycStatus ?? this.kycStatus,
      walletBalance: walletBalance ?? this.walletBalance,
      investedAmount: investedAmount ?? this.investedAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      createdAt: createdAt ?? this.createdAt,
      whatsapp: whatsapp ?? this.whatsapp,
      telegram: telegram ?? this.telegram,
      documents: documents ?? this.documents,
      activityLog: activityLog ?? this.activityLog,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'Active',
      country: json['country'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      accountType: json['accountType'] ?? 'Free',
      kycStatus: json['kycStatus'] ?? 'Unverified',
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
      investedAmount: (json['investedAmount'] ?? 0.0).toDouble(),
      pendingAmount: (json['pendingAmount'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      whatsapp: json['whatsapp'] ?? '',
      telegram: json['telegram'] ?? '',
      documents: List<String>.from(json['documents'] ?? []),
      activityLog: json['activityLog'] != null
          ? List<UserActivity>.from(
              json['activityLog'].map((x) => UserActivity.fromJson(x)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'country': country,
      'province': province,
      'city': city,
      'address': address,
      'accountType': accountType,
      'kycStatus': kycStatus,
      'walletBalance': walletBalance,
      'investedAmount': investedAmount,
      'pendingAmount': pendingAmount,
      'createdAt': createdAt.toIso8601String(),
      'whatsapp': whatsapp,
      'telegram': telegram,
      'documents': documents,
      'activityLog': activityLog.map((x) => x.toJson()).toList(),
    };
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
        country: 'Saudi Arabia',
        province: 'Riyadh Province',
        city: 'الرياض',
        address: 'شارع التخصصي، حي العليا',
        accountType: 'VIP',
        kycStatus: 'Verified',
        walletBalance: 5000.0,
        investedAmount: 15000.0,
        pendingAmount: 500.0,
        createdAt: now.subtract(const Duration(minutes: 30)), // Today
        whatsapp: '+966501234567',
        telegram: 'ahmed_mo',
        activityLog: [
          UserActivity(
            id: 'a1',
            action: 'تسجيل دخول',
            details: 'تم تسجيل الدخول من الرياض',
            timestamp: now.subtract(const Duration(hours: 1)),
            type: 'Security',
          ),
          UserActivity(
            id: 'a2',
            action: 'إيداع',
            details: 'إيداع بنكي بقيمة 5000 ريال',
            timestamp: now.subtract(const Duration(days: 1)),
            type: 'Transaction',
          ),
        ],
        documents: [
          'assets/images/id_card_front.jpg',
          'assets/images/id_card_back.jpg',
        ],
      ),
      User(
        id: '2',
        name: 'فاطمة علي',
        email: 'fatima@example.com',
        phone: '+971507654321',
        status: 'Active',
        country: 'UAE',
        province: 'Dubai',
        city: 'دبي',
        address: 'شارع الشيخ زايد، داون تاون',
        accountType: 'Verified',
        kycStatus: 'Verified',
        walletBalance: 3200.0,
        investedAmount: 8000.0,
        pendingAmount: 0.0,
        createdAt: now.subtract(const Duration(days: 2)), // This Week
        activityLog: [
          UserActivity(
            id: 'a3',
            action: 'تحديث البيانات',
            details: 'تحديث رقم الهاتف',
            timestamp: now.subtract(const Duration(days: 3)),
            type: 'System',
          ),
        ],
        whatsapp: '+971507654321',
        telegram: 'fatima_dxb',
        documents: ['assets/images/passport.jpg'],
      ),
      User(
        id: '3',
        name: 'خالد سعيد',
        email: 'khaled@example.com',
        phone: '+965509876543',
        status: 'Blocked',
        country: 'Kuwait',
        province: 'Kuwait City',
        city: 'الكويت',
        address: 'منطقة السالمية، شارع الخليج العربي',
        accountType: 'Free',
        kycStatus: 'Unverified',
        walletBalance: 0.0,
        investedAmount: 0.0,
        pendingAmount: 0.0,
        createdAt: now.subtract(const Duration(days: 10)), // This Month
        whatsapp: '+965509876543',
        telegram: 'khaled_kwt',
      ),
      User(
        id: '4',
        name: 'نورة عبدالله',
        email: 'noura@example.com',
        phone: '+966502345678',
        status: 'Active',
        country: 'Saudi Arabia',
        province: 'Makkah Province',
        city: 'جدة',
        address: 'شارع فلسطين، مقابل الحمراء',
        accountType: 'VIP',
        kycStatus: 'Verified',
        walletBalance: 12000.0,
        investedAmount: 25000.0,
        pendingAmount: 1200.0,
        createdAt: now.subtract(const Duration(hours: 5)), // Today

        whatsapp: '+966502345678',
        telegram: 'noura_abd',
      ),
      User(
        id: '5',
        name: 'عمر حسن',
        email: 'omar@example.com',
        phone: '+201508765432',
        status: 'Active',
        country: 'Egypt',
        province: 'Cairo',
        city: 'القاهرة',
        address: 'حي المعادي، شارع 9',
        accountType: 'Verified',
        kycStatus: 'Pending',
        walletBalance: 7500.0,
        investedAmount: 18000.0,
        pendingAmount: 300.0,
        createdAt: now.subtract(const Duration(days: 4)), // This Week
        whatsapp: '+201508765432',
        telegram: 'omar_cairo',
        documents: ['assets/images/national_id.jpg'], // Pending verification
      ),
      User(
        id: '6',
        name: 'ليلى يوسف',
        email: 'layla@example.com',
        phone: '+968501112223',
        status: 'Active',
        country: 'Oman',
        province: 'Muscat',
        city: 'مسقط',
        address: 'روي، شارع الفرسان',
        accountType: 'Free',
        kycStatus: 'Unverified',
        walletBalance: 1500.0,
        investedAmount: 5000.0,
        pendingAmount: 100.0,
        createdAt: now.subtract(const Duration(days: 40)), // Older
        whatsapp: '+968501112223',
        telegram: 'layla_mus',
      ),
    ];
  }
}
