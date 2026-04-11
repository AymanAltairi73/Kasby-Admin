import 'package:flutter/material.dart';
import '../../../core/utils/numeric_utils.dart';

enum LoanStatus { pending, approved, active, partial_paid, paid, overdue, defaulted, rejected }

/// Loan Model — maps to `loans` table in Supabase
class Loan {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final double interestRate;
  final double totalDue;
  final double remainingAmount;
  final double paidAmount;
  final DateTime loanDate;
  final DateTime repaymentDate;
  final LoanStatus status;
  final String? rejectionReason;

  Loan({
    required this.id,
    this.userId = '',
    required this.userName,
    required this.amount,
    this.interestRate = 0.0,
    this.totalDue = 0.0,
    this.remainingAmount = 0.0,
    this.paidAmount = 0.0,
    required this.loanDate,
    required this.repaymentDate,
    required this.status,
    this.rejectionReason,
  });

  Loan copyWith({
    String? userName,
    double? amount,
    double? interestRate,
    double? totalDue,
    double? remainingAmount,
    double? paidAmount,
    DateTime? loanDate,
    DateTime? repaymentDate,
    LoanStatus? status,
    String? rejectionReason,
  }) {
    return Loan(
      id: id,
      userId: userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      totalDue: totalDue ?? this.totalDue,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      loanDate: loanDate ?? this.loanDate,
      repaymentDate: repaymentDate ?? this.repaymentDate,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  String get statusText {
    switch (status) {
      case LoanStatus.pending:
        return 'قيد الانتظار';
      case LoanStatus.approved:
        return 'تمت الموافقة';
      case LoanStatus.active:
        return 'نشطة / جاري السداد';
      case LoanStatus.partial_paid:
        return 'سداد جزئي';
      case LoanStatus.paid:
        return 'تم السداد بنجاح';
      case LoanStatus.overdue:
        return 'متأخرة عن السداد';
      case LoanStatus.defaulted:
        return 'متعثرة كلياً';
      case LoanStatus.rejected:
        return 'مرفوضة';
    }
  }

  Color get statusColor {
    switch (status) {
      case LoanStatus.pending:
        return Colors.orange;
      case LoanStatus.approved:
        return Colors.cyan;
      case LoanStatus.active:
        return Colors.blue;
      case LoanStatus.partial_paid:
        return Colors.teal;
      case LoanStatus.paid:
        return Colors.green;
      case LoanStatus.overdue:
        return Colors.red;
      case LoanStatus.defaulted:
        return Colors.grey;
      case LoanStatus.rejected:
        return Colors.red.shade900;
    }
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(repaymentDate)) return 0;
    return repaymentDate.difference(now).inDays;
  }

  double get percentProgress {
    if (totalDue <= 0) return 0.0;
    return (paidAmount / totalDue).clamp(0.0, 1.0);
  }

  bool get isOverdue {
    if (status == LoanStatus.paid) return false;
    return DateTime.now().isAfter(repaymentDate) || status == LoanStatus.overdue;
  }

  static LoanStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return LoanStatus.pending;
      case 'approved':
        return LoanStatus.approved;
      case 'active':
      case 'current':
        return LoanStatus.active;
      case 'partial_paid':
        return LoanStatus.partial_paid;
      case 'paid':
        return LoanStatus.paid;
      case 'overdue':
      case 'delayed':
        return LoanStatus.overdue;
      case 'defaulted':
        return LoanStatus.defaulted;
      case 'rejected':
        return LoanStatus.rejected;
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
      amount: safeToDouble(json['amount']),
      interestRate: safeToDouble(json['interest_rate'] ?? json['interestRate']),
      totalDue: safeToDouble(json['total_due'] ?? json['totalDue']),
      remainingAmount: safeToDouble(json['remaining_amount'] ?? json['remainingAmount']),
      paidAmount: safeToDouble(json['paid_amount'] ?? json['paidAmount']),
      loanDate: json['loan_date'] != null
          ? DateTime.parse(json['loan_date'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      repaymentDate: json['repayment_date'] != null
          ? DateTime.parse(json['repayment_date'])
          : DateTime.now(),
      status: _parseStatus(json['status']),
      rejectionReason: json['rejection_reason'],
    );
  }

  /// Legacy fromJson
  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? '',
      amount: safeToDouble(json['amount'] ?? json['amount']),
      interestRate: safeToDouble(json['interestRate'] ?? json['interest_rate']),
      totalDue: safeToDouble(json['totalDue'] ?? json['total_due']),
      remainingAmount: safeToDouble(json['remaining_amount'] ?? json['remaining_amount']),
      paidAmount: safeToDouble(json['paidAmount'] ?? json['paid_amount']),
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
      status: _parseStatus(json['status']),
      rejectionReason: json['rejectionReason'] ?? json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'interest_rate': interestRate,
      'total_due': totalDue,
      'remaining_amount': remainingAmount,
      'paid_amount': paidAmount,
      'loan_date': loanDate.toIso8601String(),
      'repayment_date': repaymentDate.toIso8601String(),
      'status': status.name,
      'rejection_reason': rejectionReason,
    };
  }
}
