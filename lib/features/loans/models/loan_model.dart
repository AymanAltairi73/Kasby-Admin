import 'package:flutter/material.dart';

enum LoanStatus { pending, current, paid, delayed, defaulted }

/// Loan Model — maps to `loans` table in Supabase
class Loan {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final double interestRate;
  final double totalDue;
  final double paidAmount;
  final DateTime loanDate;
  final DateTime repaymentDate;
  final LoanStatus status;

  Loan({
    required this.id,
    this.userId = '',
    required this.userName,
    required this.amount,
    this.interestRate = 0.0,
    this.totalDue = 0.0,
    this.paidAmount = 0.0,
    required this.loanDate,
    required this.repaymentDate,
    required this.status,
  });

  Loan copyWith({
    String? userName,
    double? amount,
    double? interestRate,
    double? totalDue,
    double? paidAmount,
    DateTime? loanDate,
    DateTime? repaymentDate,
    LoanStatus? status,
  }) {
    return Loan(
      id: id,
      userId: userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      totalDue: totalDue ?? this.totalDue,
      paidAmount: paidAmount ?? this.paidAmount,
      loanDate: loanDate ?? this.loanDate,
      repaymentDate: repaymentDate ?? this.repaymentDate,
      status: status ?? this.status,
    );
  }

  String get statusText {
    switch (status) {
      case LoanStatus.pending:
        return 'قيد الانتظار';
      case LoanStatus.current:
        return 'جاري السداد';
      case LoanStatus.paid:
        return 'تم السداد بنجاح';
      case LoanStatus.delayed:
        return 'متأخر عن السداد';
      case LoanStatus.defaulted:
        return 'متعثر كلياً';
    }
  }

  Color get statusColor {
    switch (status) {
      case LoanStatus.pending:
        return Colors.orange;
      case LoanStatus.current:
        return Colors.blue;
      case LoanStatus.paid:
        return Colors.green;
      case LoanStatus.delayed:
        return Colors.red;
      case LoanStatus.defaulted:
        return Colors.grey;
    }
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(repaymentDate)) return 0;
    return repaymentDate.difference(now).inDays;
  }

  double get percentProgress {
    final totalDuration = repaymentDate.difference(loanDate).inMilliseconds;
    if (totalDuration <= 0) return 1.0;
    
    final elapsed = DateTime.now().difference(loanDate).inMilliseconds;
    if (elapsed <= 0) return 0.0;
    
    final progress = elapsed / totalDuration;
    return progress.clamp(0.0, 1.0);
  }

  bool get isOverdue {
    if (status == LoanStatus.paid) return false;
    return DateTime.now().isAfter(repaymentDate);
  }

  static LoanStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return LoanStatus.pending;
      case 'current':
        return LoanStatus.current;
      case 'paid':
        return LoanStatus.paid;
      case 'delayed':
      case 'overdue':
        return LoanStatus.delayed;
      case 'defaulted':
        return LoanStatus.defaulted;
      default:
        return LoanStatus.pending;
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
      interestRate: (json['interest_rate'] ?? 0.0).toDouble(),
      totalDue: (json['total_due'] ?? 0.0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0.0).toDouble(),
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
      interestRate: (json['interestRate'] ?? json['interest_rate'] ?? 0.0).toDouble(),
      totalDue: (json['totalDue'] ?? json['total_due'] ?? 0.0).toDouble(),
      paidAmount: (json['paidAmount'] ?? json['paid_amount'] ?? 0.0).toDouble(),
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
      'interestRate': interestRate,
      'totalDue': totalDue,
      'paidAmount': paidAmount,
      'loanDate': loanDate.toIso8601String(),
      'repaymentDate': repaymentDate.toIso8601String(),
      'status': status.toString(),
    };
  }
}
