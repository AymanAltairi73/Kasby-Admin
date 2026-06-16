import 'user_activity_model.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/utils/numeric_utils.dart';

/// User Model — maps to `profiles` + `wallets` tables in Supabase
/// Updated to align with kasby_new.sql schema (no role column, country_code, referral)

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // user, admin, agent (Single source of truth)
  final String status; // active, blocked, suspended
  final String country; // maps to country_code in DB
  final String province;
  final String city;
  final String address;
  final String accountType; // free, verified, vip (Maps to account_tier in SQL)
  final String kycStatus; // unverified, pending, verified, rejected
  final double walletBalance;
  final double profitBalance;
  final double investedAmount;
  final double pendingAmount;
  final DateTime createdAt;
  final String whatsapp;
  final String telegram;
  final String avatarUrl;
  final String referralCode;
  final String? referredBy;
  final String statusReason;
  final DateTime? statusChangedAt;
  final String? statusChangedBy;
  final DateTime? updatedAt;
  final String? lastLoginIp;
  final int storedSpins;
  final List<String> documents;
  final List<UserActivity> activityLog;
  final DateTime? lastLoginAt;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isBlocked => status.toLowerCase() == 'blocked';
  bool get isSuspended => status.toLowerCase() == 'suspended';
  String get statusLabelAr => isActive
      ? 'نشط'
      : (isBlocked ? 'محظور' : (isSuspended ? 'معلق' : status));

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.country,
    this.province = '',
    this.city = '',
    this.address = '',
    required this.accountType,
    required this.kycStatus,
    required this.walletBalance,
    this.profitBalance = 0.0,
    this.investedAmount = 0.0,
    this.pendingAmount = 0.0,
    required this.createdAt,
    this.whatsapp = '',
    this.telegram = '',
    this.avatarUrl = '',
    this.referralCode = '',
    this.referredBy,
    this.statusReason = '',
    this.statusChangedAt,
    this.statusChangedBy,
    this.updatedAt,
    this.lastLoginIp,
    this.storedSpins = 0,
    this.documents = const [],
    this.activityLog = const [],
    this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? country,
    String? province,
    String? city,
    String? address,
    String? accountType,
    String? kycStatus,
    double? walletBalance,
    double? profitBalance,
    double? investedAmount,
    double? pendingAmount,
    DateTime? createdAt,
    String? whatsapp,
    String? telegram,
    String? avatarUrl,
    String? referralCode,
    String? referredBy,
    String? statusReason,
    DateTime? statusChangedAt,
    String? statusChangedBy,
    DateTime? updatedAt,
    String? lastLoginIp,
    int? storedSpins,
    List<String>? documents,
    List<UserActivity>? activityLog,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      address: address ?? this.address,
      accountType: accountType ?? this.accountType,
      kycStatus: kycStatus ?? this.kycStatus,
      walletBalance: walletBalance ?? this.walletBalance,
      profitBalance: profitBalance ?? this.profitBalance,
      investedAmount: investedAmount ?? this.investedAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      createdAt: createdAt ?? this.createdAt,
      whatsapp: whatsapp ?? this.whatsapp,
      telegram: telegram ?? this.telegram,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      statusReason: statusReason ?? this.statusReason,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      statusChangedBy: statusChangedBy ?? this.statusChangedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      storedSpins: storedSpins ?? this.storedSpins,
      documents: documents ?? this.documents,
      activityLog: activityLog ?? this.activityLog,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Construct from Supabase `profiles` row (with optional nested `wallets`)
  factory User.fromSupabase(Map<String, dynamic> json) {
    try {
    // Wallet data may be nested as a list or object
    final wallet = json['wallets'];
    double availBal = 0.0;
    double profBal = 0.0;
    double investBal = 0.0;
    double pendingBal = 0.0;
    if (wallet is List && wallet.isNotEmpty) {
      availBal = safeToDouble(wallet[0]['available_balance']);
      profBal = safeToDouble(wallet[0]['profit_balance']);
      investBal = safeToDouble(wallet[0]['invested_balance']);
      pendingBal = safeToDouble(wallet[0]['pending_balance']);
    } else if (wallet is Map) {
      availBal = safeToDouble(wallet['available_balance']);
      profBal = safeToDouble(wallet['profit_balance']);
      investBal = safeToDouble(wallet['invested_balance']);
      pendingBal = safeToDouble(wallet['pending_balance']);
    } else {
      AppLoggerService.debugTrace(
        className: 'User',
        method: 'fromSupabase',
        feature: 'Users',
        status: 'WARNING',
        message: 'Wallet data missing or incorrectly mapped',
        params: {'userId': _safeId(json['id'])},
      );
    }

    return User(
      id: json['id'] ?? '',
      name: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      country: json['country_code'] ?? json['country'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      accountType: json['account_tier'] ?? json['account_type'] ?? 'free',
      kycStatus: json['kyc_status'] ?? 'unverified',
      walletBalance: availBal,
      profitBalance: profBal,
      investedAmount: investBal,
      pendingAmount: pendingBal,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      whatsapp: json['whatsapp'] ?? '',
      telegram: json['telegram'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      referralCode: json['referral_code'] ?? '',
      referredBy: json['referred_by']?.toString() ?? json['referred_by_id']?.toString(),
      statusReason: json['status_reason'] ?? '',
      statusChangedAt: json['status_changed_at'] != null
          ? DateTime.parse(json['status_changed_at'])
          : null,
      statusChangedBy: json['status_changed_by']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      lastLoginIp: json['last_login_ip']?.toString(),
      storedSpins: (json['stored_spins'] as num?)?.toInt() ?? 0,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : (json['admin_profiles'] != null && json['admin_profiles']['last_login_at'] != null
              ? DateTime.parse(json['admin_profiles']['last_login_at'])
              : null),
    );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'User',
        method: 'fromSupabase',
        feature: 'Users',
        status: 'FAILED',
        params: {'userId': _safeId(json['id'])},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  static String _safeId(dynamic id) {
    final text = id?.toString() ?? '';
    return text.length > 8 ? '${text.substring(0, 8)}...' : text;
  }

  /// Legacy fromJson for backward compat with SharedPreferences cache
  factory User.fromJson(Map<String, dynamic> json) {
    try {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      country: json['country'] ?? json['country_code'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      accountType:
          json['accountType'] ??
          json['account_type'] ??
          json['account_tier'] ??
          'free',
      kycStatus: json['kycStatus'] ?? json['kyc_status'] ?? 'unverified',
      walletBalance: safeToDouble(json['walletBalance']),
      profitBalance: safeToDouble(json['profitBalance']),
      investedAmount: safeToDouble(json['investedAmount']),
      pendingAmount: safeToDouble(json['pendingAmount']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      whatsapp: json['whatsapp'] ?? '',
      telegram: json['telegram'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'] ?? '',
      referralCode: json['referralCode'] ?? json['referral_code'] ?? '',
      documents: List<String>.from(json['documents'] ?? []),
      activityLog: json['activityLog'] != null
          ? List<UserActivity>.from(
              json['activityLog'].map((a) => UserActivity.fromJson(a)),
            )
          : [],
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
    );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'User',
        method: 'fromJson',
        feature: 'Users',
        status: 'FAILED',
        params: {'userId': _safeId(json['id'])},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'country': country,
      'province': province,
      'city': city,
      'address': address,
      'accountType': accountType,
      'kycStatus': kycStatus,
      'walletBalance': walletBalance,
      'profitBalance': profitBalance,
      'investedAmount': investedAmount,
      'pendingAmount': pendingAmount,
      'createdAt': createdAt.toIso8601String(),
      'whatsapp': whatsapp,
      'telegram': telegram,
      'avatarUrl': avatarUrl,
      'referralCode': referralCode,
      'documents': documents,
      'activityLog': activityLog.map((a) => a.toJson()).toList(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  /// Convert to Supabase-compatible map for insert/update on profiles table
  /// Aligned with kasby_new.sql schema
  Map<String, dynamic> toSupabase() {
    return {
      'full_name': name,
      'email': email,
      'phone': phone.isNotEmpty ? phone : null,
      'role': role,
      'status': status,
      'country_code': country.isNotEmpty ? country : null,
      'province': province,
      'city': city,
      'address': address,
      'account_tier': accountType,
      'kyc_status': kycStatus,
      'whatsapp': whatsapp,
      'telegram': telegram,
      'avatar_url': avatarUrl.isNotEmpty ? avatarUrl : null,
    };
  }
}
