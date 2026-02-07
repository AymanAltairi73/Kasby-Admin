import '../models/transaction_model.dart';

/// Report Service
/// Handles financial data aggregation and report generation
class ReportService {
  /// Generate a summary report for a given period
  static Map<String, dynamic> generateSummary(List<Transaction> transactions) {
    final deposits = transactions.where(
      (t) => t.type == 'Deposit' && t.status == 'Approved',
    );
    final withdrawals = transactions.where(
      (t) => t.type == 'Withdrawal' && t.status == 'Approved',
    );

    final totalDeposits = deposits.fold(0.0, (sum, t) => sum + t.amount);
    final totalWithdrawals = withdrawals.fold(0.0, (sum, t) => sum + t.amount);

    return {
      'total_volume': totalDeposits + totalWithdrawals,
      'net_flow': totalDeposits - totalWithdrawals,
      'deposit_count': deposits.length,
      'withdrawal_count': withdrawals.length,
      'average_deposit': deposits.isEmpty ? 0 : totalDeposits / deposits.length,
      'period_start': transactions.isEmpty ? null : transactions.last.createdAt,
      'period_end': transactions.isEmpty ? null : transactions.first.createdAt,
    };
  }

  /// Mock Export to CSV
  static Future<String> exportToCSV(List<Transaction> transactions) async {
    // In a real app, use 'csv' package
    final buffer = StringBuffer();
    buffer.writeln('ID,User,Type,Amount,Status,Date');

    for (final t in transactions) {
      buffer.writeln(
        '${t.id},${t.userName},${t.type},${t.amount},${t.status},${t.createdAt}',
      );
    }

    // Simulate file creation
    await Future.delayed(const Duration(seconds: 2));
    return 'reports/transactions_export_${DateTime.now().millisecondsSinceEpoch}.csv';
  }

  /// Mock Export to PDF
  static Future<String> exportToPDF(List<Transaction> transactions) async {
    // In a real app, use 'pdf' package
    await Future.delayed(const Duration(seconds: 3));
    return 'reports/financial_statement_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }
}
