import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../models/loan_model.dart';
import '../models/loan_repayment_model.dart';
import '../controllers/loan_controller.dart';

/// Loan Detail Screen
/// Comprehensive view of a single loan including financial breakdown and status history
class LoanDetailScreen extends StatelessWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('تفاصيل السلفة'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildCelestialBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Status Header
                  _buildStatusHeader(loan),
                  
                  const SizedBox(height: 24),
                  
                  // Primary Metrics Card
                  _buildMainMetricsCard(loan, currencyFormat),
                  
                  const SizedBox(height: 20),
                  
                  // Financial Breakdown
                  _buildFinancialBreakdown(loan, currencyFormat),
                  
                  const SizedBox(height: 20),
                  
                  // Repayment History
                  _buildRepaymentHistory(context, loan, currencyFormat, dateFormat),
                  
                  const SizedBox(height: 20),
                  
                  // Timeline Section
                  _buildTimelineSection(loan, dateFormat),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(Loan loan) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: loan.statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: loan.statusColor.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(
            _getStatusIcon(loan.status),
            size: 40,
            color: loan.statusColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          loan.statusText,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: loan.statusColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'معرف السلفة: ${loan.id.substring(0, 8).toUpperCase()}',
          style: const TextStyle(fontSize: 12, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildMainMetricsCard(Loan loan, NumberFormat format) {
    return KasbyGlassCard(
      child: Column(
        children: [
          const Text(
            'المبلغ الإجمالي المستحق',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
          const SizedBox(height: 8),
          Text(
            format.format(loan.totalDue),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: KasbyColors.primaryGold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSimpleMetric('المدفوع', format.format(loan.paidAmount), KasbyColors.success),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildSimpleMetric('المتبقي', format.format(loan.totalDue - loan.paidAmount), Colors.white70),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: loan.totalDue > 0 ? (loan.paidAmount / loan.totalDue) : 0,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                loan.status == LoanStatus.paid ? KasbyColors.success : KasbyColors.primaryGold,
              ),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMetric(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialBreakdown(Loan loan, NumberFormat format) {
    return KasbyGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التفاصيل المالية',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('قيمة القرض', format.format(loan.amount)),
          _buildDetailRow('نسبة الفائدة', '${loan.interestRate}%'),
          _buildDetailRow('إجمالي المستحق', format.format(loan.totalDue), color: Colors.white70),
          const Divider(color: Colors.white10, height: 32),
          _buildDetailRow('المدفوع', format.format(loan.paidAmount), color: KasbyColors.success),
          _buildDetailRow('المتبقي للسداد', format.format(loan.remainingAmount), isBold: true, color: KasbyColors.primaryGold),
        ],
      ),
    );
  }

  Widget _buildRepaymentHistory(BuildContext context, Loan loan, NumberFormat currencyFormat, DateFormat dateFormat) {
    final controller = Get.find<LoanController>();

    return KasbyGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'سجل عمليات السداد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (loan.status != LoanStatus.paid && loan.status != LoanStatus.rejected)
                TextButton.icon(
                  onPressed: () => _showRecordRepaymentDialog(context, controller),
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: KasbyColors.primaryGold),
                  label: const Text('تسجيل دفعة', style: TextStyle(color: KasbyColors.primaryGold, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<LoanRepayment>>(
            future: controller.fetchRepayments(loan.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: KasbyColors.primaryGold));
              }
              
              final repayments = snapshot.data ?? [];
              
              if (repayments.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('لا توجد عمليات سداد مسجلة', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: repayments.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final rep = repayments[index];
                  final amount = rep.amount;
                  final type = rep.type == RepaymentType.full ? 'سداد كلي' : 'سداد جزئي';
                  final date = rep.createdAt;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(type, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(dateFormat.format(date), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                            Text(
                              currencyFormat.format(amount),
                              style: const TextStyle(color: KasbyColors.success, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        if (rep.paymentMethod.isNotEmpty || (rep.notes != null && rep.notes!.isNotEmpty)) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  rep.paymentMethod,
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ),
                              if (rep.notes != null && rep.notes!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rep.notes!,
                                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(Loan loan, DateFormat format) {
    return KasbyGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الجدول الزمني',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem('تاريخ الطلب', format.format(loan.loanDate), Icons.add_circle_outline),
          _buildTimelineItem('تاريخ الاستحقاق', format.format(loan.repaymentDate), Icons.event_available, isLast: loan.status != LoanStatus.paid),
          if (loan.status == LoanStatus.paid)
             _buildTimelineItem('تاريخ السداد الكامل', format.format(DateTime.now()), Icons.check_circle_outline, color: KasbyColors.success, isLast: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color color = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.white38)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String date, IconData icon, {bool isLast = false, Color color = Colors.white38}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, size: 20, color: color),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelestialBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(LoanStatus status) {
    switch (status) {
      case LoanStatus.pending: return Icons.hourglass_empty_rounded;
      case LoanStatus.approved: return Icons.thumb_up_alt_rounded;
      case LoanStatus.active: return Icons.trending_up_rounded;
      case LoanStatus.partial_paid: return Icons.payments_rounded;
      case LoanStatus.paid: return Icons.verified_user_rounded;
      case LoanStatus.overdue: return Icons.warning_amber_rounded;
      case LoanStatus.defaulted: return Icons.block_rounded;
      case LoanStatus.rejected: return Icons.cancel_rounded;
    }
  }

  void _showRecordRepaymentDialog(BuildContext context, LoanController controller) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final receiptController = TextEditingController();
    String selectedMethod = 'نقدي';
    RepaymentType selectedType = RepaymentType.partial;

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('تسجيل دفعة سداد يدوية', style: TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المستلم',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'وسيلة الدفع',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                items: ['نقدي', 'تحويل بنكي', 'محفظة كاسبي', 'أخرى'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => selectedMethod = v ?? 'نقدي',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RepaymentType>(
                value: selectedType,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'نوع السداد',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                items: const [
                  DropdownMenuItem(value: RepaymentType.partial, child: Text('سداد جزئي')),
                  DropdownMenuItem(value: RepaymentType.full, child: Text('سداد كلي (إغلاق السلفة)')),
                ],
                onChanged: (v) => selectedType = v ?? RepaymentType.partial,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: receiptController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'رقم الإيصال / المرجع',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text) ?? 0.0;
              if (amt <= 0) {
                Get.snackbar('تنبيه', 'يرجى إدخال مبلغ صحيح');
                return;
              }
              Get.back();
              await controller.recordRepayment(
                loanId: loan.id,
                amount: amt,
                paymentMethod: selectedMethod,
                type: selectedType,
                notes: notesController.text,
                receiptId: receiptController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: KasbyColors.primaryGold),
            child: const Text('تسجيل الآن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
