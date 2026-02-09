import 'package:flutter/material.dart';

enum LoanStatus { current, paid, delayed }

class Loan {
  final String id;
  final String userName;
  final double amount;
  final DateTime loanDate;
  final DateTime repaymentDate;
  final LoanStatus status;

  Loan({
    required this.id,
    required this.userName,
    required this.amount,
    required this.loanDate,
    required this.repaymentDate,
    required this.status,
  });

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

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] ?? '',
      userName: json['userName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      loanDate: json['loanDate'] != null
          ? DateTime.parse(json['loanDate'])
          : DateTime.now(),
      repaymentDate: json['repaymentDate'] != null
          ? DateTime.parse(json['repaymentDate'])
          : DateTime.now(),
      status: LoanStatus.values.firstWhere(
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

  static List<Loan> getMockLoans() {
    return [
      Loan(
        id: '1',
        userName: 'أحمد محمد',
        amount: 500.0,
        loanDate: DateTime.now().subtract(const Duration(days: 10)),
        repaymentDate: DateTime.now().add(const Duration(days: 20)),
        status: LoanStatus.current,
      ),
      Loan(
        id: '2',
        userName: 'سارة علي',
        amount: 1200.0,
        loanDate: DateTime.now().subtract(const Duration(days: 40)),
        repaymentDate: DateTime.now().subtract(const Duration(days: 10)),
        status: LoanStatus.paid,
      ),
      Loan(
        id: '3',
        userName: 'خالد حسن',
        amount: 300.0,
        loanDate: DateTime.now().subtract(const Duration(days: 45)),
        repaymentDate: DateTime.now().subtract(const Duration(days: 5)),
        status: LoanStatus.delayed,
      ),
      Loan(
        id: '4',
        userName: 'مريم محمود',
        amount: 2500.0,
        loanDate: DateTime.now().subtract(const Duration(days: 5)),
        repaymentDate: DateTime.now().add(const Duration(days: 55)),
        status: LoanStatus.current,
      ),
      Loan(
        id: '5',
        userName: 'ياسين زكي',
        amount: 800.0,
        loanDate: DateTime.now().subtract(const Duration(days: 20)),
        repaymentDate: DateTime.now().add(const Duration(days: 10)),
        status: LoanStatus.current,
      ),
    ];
  }
}
