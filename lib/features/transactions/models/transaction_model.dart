/// Transaction Model — maps to `transactions` table in Supabase
class Transaction {
  final String id;
  final String userId;
  final String userName;
  final String
  type; // deposit, withdrawal, transfer_in, transfer_out, investment, profit, etc.
  final double amount;
  final String status; // pending, processing, completed, rejected, failed
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

  Transaction copyWith({
    String? status,
    String? reason,
    String? proofUrl,
    DateTime? processedAt,
    String? userName,
    double? amount,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      userName: userName ?? this.userName,
      type: type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      proofUrl: proofUrl ?? this.proofUrl,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  /// Construct from Supabase row (with optional nested profiles for userName)
  factory Transaction.fromSupabase(Map<String, dynamic> json) {
    // Extract user name from nested profile join
    String uName = '';
    final profile = json['profiles'];
    if (profile is Map) {
      uName = profile['full_name'] ?? '';
    }

    return Transaction(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: uName,
      type: json['type'] ?? 'deposit',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      reason: json['rejection_reason'],
      proofUrl: json['proof_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
    );
  }

  /// Legacy fromJson for backward compat
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? '',
      type: json['type'] ?? 'deposit',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      reason: json['reason'] ?? json['rejection_reason'],
      proofUrl: json['proofUrl'] ?? json['proof_url'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : (json['processed_at'] != null
                ? DateTime.parse(json['processed_at'])
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'type': type,
      'amount': amount,
      'status': status,
      'reason': reason,
      'proofUrl': proofUrl,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}
