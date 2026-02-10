import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
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

  /// Export transactions to CSV
  static Future<String> exportToCSV(List<Transaction> transactions) async {
    final List<List<dynamic>> rows = [];

    // Header in Arabic
    rows.add(['المعرف', 'المستخدم', 'النوع', 'المبلغ', 'الحالة', 'التاريخ']);

    for (var t in transactions) {
      rows.add([
        t.id,
        t.userName,
        t.type == 'Deposit' ? 'إيداع' : 'سحب',
        t.amount,
        t.status,
        DateFormat('yyyy-MM-dd HH:mm').format(t.createdAt),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);

    // Add UTF-8 BOM for Excel to recognize Arabic characters
    final bom = '\uFEFF';
    final result = bom + csvString;

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
    );

    await file.writeAsString(result, encoding: utf8);
    return file.path;
  }

  /// Export transactions to PDF with Arabic support
  static Future<String> exportToPDF(List<Transaction> transactions) async {
    final pdf = pw.Document();

    // Load the Arabic font
    final fontData = await rootBundle.load(
      'assets/fonts/IBM_Plex_Sans_Arabic/IBMPlexSansArabic-Regular.ttf',
    );
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            _reshape('كشف حساب مالي - كاسبي'),
            style: pw.TextStyle(
              font: ttf,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'التاريخ',
              'الحالة',
              'المبلغ',
              'النوع',
              'المستخدم',
            ].map((e) => _reshape(e)).toList(),
            data: transactions
                .map(
                  (t) => [
                    DateFormat('yyyy-MM-dd HH:mm').format(t.createdAt),
                    _reshape(t.status == 'Approved' ? 'موافق' : 'معلق'),
                    '\$${t.amount.toStringAsFixed(2)}',
                    _reshape(t.type == 'Deposit' ? 'إيداع' : 'سحب'),
                    _reshape(t.userName),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              font: ttf,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.amber700),
            cellStyle: pw.TextStyle(font: ttf),
            cellAlignment: pw.Alignment.centerRight,
            tableDirection: pw.TextDirection.rtl,
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Manual Arabic Reshaper for PDF compatibility without external packages
  /// This handles basic shaping (Initial, Medial, Final, Isolated) forms.
  static String _reshape(String text) {
    if (text.isEmpty) return text;

    // Simple Arabic character map for shaping (subset for demonstration)
    final Map<int, List<int>> shapingMap = {
      0x0627: [0x0627, 0x0627, 0xFE8E, 0xFE8E], // Alef
      0x0628: [0x0628, 0xFE91, 0xFE92, 0xFE90], // Beh
      0x062A: [0x062A, 0xFE97, 0xFE98, 0xFE96], // Teh
      0x062B: [0x062B, 0xFE9B, 0xFE9C, 0xFE9A], // Theh
      0x062C: [0x062C, 0xFE9F, 0xFEA0, 0xFE9E], // Jeem
      0x062D: [0x062D, 0xFEA3, 0xFEA4, 0xFEA2], // Hah
      0x062E: [0x062E, 0xFEA7, 0xFEA8, 0xFEA6], // Khah
      0x062F: [0x062F, 0x062F, 0xFEAA, 0xFEAA], // Dal
      0x0630: [0x0630, 0x0630, 0xFEAC, 0xFEAC], // Thal
      0x0631: [0x0631, 0x0631, 0xFEAE, 0xFEAE], // Reh
      0x0632: [0x0632, 0x0632, 0xFEB0, 0xFEB0], // Zain
      0x0633: [0x0633, 0xFEB3, 0xFEB4, 0xFEB2], // Seen
      0x0634: [0x0634, 0xFEB7, 0xFEB8, 0xFEB6], // Sheen
      0x0635: [0x0635, 0xFEBB, 0xFEBC, 0xFEBA], // Sad
      0x0636: [0x0636, 0xFEBF, 0xFEC0, 0xFEBE], // Dad
      0x0637: [0x0637, 0xFEC3, 0xFEC4, 0xFEC2], // Tah
      0x0638: [0x0638, 0xFEC7, 0xFEC8, 0xFEC6], // Zah
      0x0639: [0x0639, 0xFECB, 0xFECC, 0xFECA], // Ain
      0x063A: [0x063A, 0xFECF, 0xFED0, 0xFECE], // Ghain
      0x0641: [0x0641, 0xFED3, 0xFED4, 0xFED2], // Feh
      0x0642: [0x0642, 0xFED7, 0xFED8, 0xFED6], // Qaf
      0x0643: [0x0643, 0xFEDB, 0xFEDC, 0xFEDA], // Kaf
      0x0644: [0x0644, 0xFEDF, 0xFEE0, 0xFEDE], // Lam
      0x0645: [0x0645, 0xFEE3, 0xFEE4, 0xFEE2], // Meem
      0x0646: [0x0646, 0xFEE7, 0xFEE8, 0xFEE6], // Noon
      0x0647: [0x0647, 0xFEEB, 0xFEEC, 0xFEEA], // Heh
      0x0648: [0x0648, 0x0648, 0xFEEE, 0xFEEE], // Waw
      0x064A: [0x064A, 0xFEF3, 0xFEF4, 0xFEF2], // Yeh
      0x0629: [0x0629, 0x0629, 0xFE94, 0xFE94], // Teh Marbuta
      0x0649: [0x0649, 0x0649, 0xFEF0, 0xFEF0], // Alef Maksura
      0x0622: [0x0622, 0x0622, 0xFE82, 0xFE82], // Alef Madda
      0x0623: [0x0623, 0x0623, 0xFE84, 0xFE84], // Alef Hamza Above
      0x0625: [0x0625, 0x0625, 0xFE88, 0xFE88], // Alef Hamza Below
    };

    final List<int> codes = text.runes.toList();
    final List<int> reshaped = [];

    for (int i = 0; i < codes.length; i++) {
      final int code = codes[i];
      if (shapingMap.containsKey(code)) {
        final bool hasPrev =
            i > 0 &&
            shapingMap.containsKey(codes[i - 1]) &&
            !_isNonConnecting(codes[i - 1]);
        final bool hasNext =
            i < codes.length - 1 && shapingMap.containsKey(codes[i + 1]);

        if (hasPrev && hasNext) {
          reshaped.add(shapingMap[code]![2]); // Medial
        } else if (hasPrev) {
          reshaped.add(shapingMap[code]![3]); // Final
        } else if (hasNext) {
          reshaped.add(shapingMap[code]![1]); // Initial
        } else {
          reshaped.add(shapingMap[code]![0]); // Isolated
        }
      } else {
        reshaped.add(code);
      }
    }

    return String.fromCharCodes(reshaped);
  }

  static bool _isNonConnecting(int code) {
    return [
      0x0627,
      0x0622,
      0x0623,
      0x0625,
      0x062F,
      0x0630,
      0x0631,
      0x0632,
      0x0648,
      0x0629,
      0x0649,
    ].contains(code);
  }
}
