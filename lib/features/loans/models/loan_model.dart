import 'package:flutter/material.dart';

enum LoanStatus { current, paid, delayed }

/// Loan Model — maps to `loans` table in Supabase
class Loan {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final DateTime loanDate;
  final DateTime repaymentDate;
  final LoanStatus status;

  Loan({
    required this.id,
    this.userId = '',
    required this.userName,
    required this.amount,
    required this.loanDate,
    required this.repaymentDate,
    required this.status,
  });

  Loan copyWith({
    String? userName,
    double? amount,
    DateTime? loanDate,
    DateTime? repaymentDate,
    LoanStatus? status,
  }) {
    return Loan(
      id: id,
      userId: userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      loanDate: loanDate ?? this.loanDate,
      repaymentDate: repaymentDate ?? this.repaymentDate,
      status: status ?? this.status,
    );
  }

  String get statusText {
    switch (status) {
      case LoanStatus.current:
        return 'قيد الانتظار';
      case LoanStatus.paid:
        return 'تم السداد';
      case LoanStatus.delayed:
        return 'متأخر';
    }
  }

  Color get statusColor {
    switch (status) {
      case LoanStatus.current:
        return Colors.blue;
      case LoanStatus.paid:
        return Colors.green;
      case LoanStatus.delayed:
        return Colors.red;
    }
  }

  static LoanStatus _parseStatus(String? status) {
    switch (status) {
      case 'paid':
        return LoanStatus.paid;
      case 'delayed':
      case 'overdue':
        return LoanStatus.delayed;
      default:
        return LoanStatus.current;
    }
  }

  /// Construct from Supabase row with nested profiles
  factory Loan.fromSupabase(Map<String, dynamic> json) {
    String uName = '';
    final profile = json['profiles'];
    if (profile is Map) {
      uName = profile['full_name'] ?? '';
    }

    return Loan(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: uName,
      amount: (json['amount'] ?? 0.0).toDouble(),
      loanDate: json['loan_date'] != null
          ? DateTime.parse(json['loan_date'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      repaymentDate: json['repayment_date'] != null
          ? DateTime.parse(json['repayment_date'])
          : DateTime.now(),
      status: _parseStatus(json['status']),
    );
  }

  /// Legacy fromJson
  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      loanDate: json['loanDate'] != null
          ? DateTime.parse(json['loanDate'])
          : (json['loan_date'] != null
                ? DateTime.parse(json['loan_date'])
                : DateTime.now()),
      repaymentDate: json['repaymentDate'] != null
          ? DateTime.parse(json['repaymentDate'])
          : (json['repayment_date'] != null
                ? DateTime.parse(json['repayment_date'])
                : DateTime.now()),
      status: json['status'] is String
          ? _parseStatus(json['status'])
          : LoanStatus.values.firstWhere(
              (e) => e.toString() == json['status'],
              orElse: () => LoanStatus.current,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'amount': amount,
      'loanDate': loanDate.toIso8601String(),
      'repaymentDate': repaymentDate.toIso8601String(),
      'status': status.toString(),
    };
  }
}
