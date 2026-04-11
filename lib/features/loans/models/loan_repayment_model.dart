
enum RepaymentType { full, partial }

class LoanRepayment {
  final String id;
  final String loanId;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final String? receiptId;
  final RepaymentType type;
  final DateTime createdAt;

  LoanRepayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    this.receiptId,
    required this.type,
    required this.createdAt,
  });

  factory LoanRepayment.fromSupabase(Map<String, dynamic> json) {
    return LoanRepayment(
      id: json['id'] ?? '',
      loanId: json['loan_id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'نقدي',
      notes: json['notes'],
      receiptId: json['receipt_id'],
      type: json['type'] == 'full' ? RepaymentType.full : RepaymentType.partial,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loan_id': loanId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'receipt_id': receiptId,
      'type': type == RepaymentType.full ? 'full' : 'partial',
    };
  }
}
