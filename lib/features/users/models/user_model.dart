import 'user_activity_model.dart';

/// User Model — maps to `profiles` + `wallets` tables in Supabase
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status; // active, blocked, suspended, deleted
  final String country;
  final String province;
  final String city;
  final String address;
  final String accountType; // Free, Premium
  final String kycStatus; // Unverified, Pending, Verified, Rejected
  final double walletBalance;
  final double investedAmount;
  final double pendingAmount;
  final String role; // user, admin
  final DateTime createdAt;
  final String whatsapp;
  final String telegram;
  final List<String> documents;
  final List<UserActivity> activityLog;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.role,
    required this.country,
    this.province = '',
    this.city = '',
    this.address = '',
    required this.accountType,
    required this.kycStatus,
    required this.walletBalance,
    this.investedAmount = 0.0,
    this.pendingAmount = 0.0,
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
    String? role,
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
      role: role ?? this.role,
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

  /// Construct from Supabase `profiles` row (with optional nested `wallets`)
  factory User.fromSupabase(Map<String, dynamic> json) {
    // Wallet data may be nested as a list or object
    final wallet = json['wallets'];
    double availBal = 0.0;
    double investBal = 0.0;
    double pendingBal = 0.0;
    if (wallet is List && wallet.isNotEmpty) {
      availBal = (wallet[0]['available_balance'] ?? 0).toDouble();
      investBal = (wallet[0]['invested_balance'] ?? 0).toDouble();
      pendingBal = (wallet[0]['pending_balance'] ?? 0).toDouble();
    } else if (wallet is Map) {
      availBal = (wallet['available_balance'] ?? 0).toDouble();
      investBal = (wallet['invested_balance'] ?? 0).toDouble();
      pendingBal = (wallet['pending_balance'] ?? 0).toDouble();
    }

    return User(
      id: json['id'] ?? '',
      name: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'active',
      role: json['role'] ?? 'user',
      country: json['country'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      accountType: json['account_type'] ?? 'Free',
      kycStatus: json['kyc_status'] ?? 'Unverified',
      walletBalance: availBal,
      investedAmount: investBal,
      pendingAmount: pendingBal,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      whatsapp: json['whatsapp'] ?? '',
      telegram: json['telegram'] ?? '',
    );
  }

  /// Legacy fromJson for backward compat with SharedPreferences cache
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'active',
      role: json['role'] ?? 'user',
      country: json['country'] ?? '',
      province: json['province'] ?? '', 
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      accountType: json['accountType'] ?? json['account_type'] ?? 'Free',
      kycStatus: json['kycStatus'] ?? json['kyc_status'] ?? 'Unverified',
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
      investedAmount: (json['investedAmount'] ?? 0.0).toDouble(),
      pendingAmount: (json['pendingAmount'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      whatsapp: json['whatsapp'] ?? '',
      telegram: json['telegram'] ?? '',
      documents: List<String>.from(json['documents'] ?? []),
      activityLog: json['activityLog'] != null
          ? List<UserActivity>.from(
              json['activityLog'].map((a) => UserActivity.fromJson(a)),
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
      'role': role,
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
      'activityLog': activityLog.map((a) => a.toJson()).toList(),
    };
  }

  /// Convert to Supabase-compatible map for insert/update on profiles table
  Map<String, dynamic> toSupabase() {
    return {
      'full_name': name,
      'email': email,
      'phone': phone.isNotEmpty ? phone : null,
      'status': status,
      'role': role,
      'country': country,
      'province': province,
      'city': city,
      'address': address,
      'account_type': accountType,
      'kyc_status': kycStatus,
      'whatsapp': whatsapp,
      'telegram': telegram,
    };
  }
}
