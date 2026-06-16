import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_model.dart';
// import '../../../core/models/time_filter.dart';
import '../services/report_service.dart';
import 'package:open_filex/open_filex.dart';

/// Transactions Screen
/// History and Monitoring
class TransactionsScreen extends StatelessWidget {
  final int initialIndex;
  const TransactionsScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TransactionController>()) {
      Get.put(TransactionController());
    }
    final controller = Get.find<TransactionController>();

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المعاملات'),
          actions: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.fileLines),
              onPressed: () => _showReportOptions(context, controller),
              tooltip: 'توليد تقرير',
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            indicatorColor: KasbyColors.primaryGold,
            labelColor: KasbyColors.primaryGold,
            unselectedLabelColor: KasbyColors.textSecondary,
            tabs: [
              Tab(text: 'الإيداع'),
              Tab(text: 'السحب'),
              Tab(text: 'التحويل'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.transactions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: KasbyColors.primaryGold),
            );
          }

          return TabBarView(
            children: [
              _buildTransactionsList(controller.allDeposits, controller),
              _buildTransactionsList(controller.allWithdrawals, controller),
              _buildTransactionsList(controller.allTransfers, controller),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTransactionsList(
    List<Transaction> transactions,
    TransactionController controller,
  ) {
    if (transactions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
            SizedBox(height: 200),
            Center(
              child: Text(
                'لا توجد معاملات',
                style: TextStyle(color: KasbyColors.textSecondary, fontSize: 16),
              ),
            ),
          ],
        );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction, controller);
      },
    );
  }

  Widget _buildTransactionCard(
    Transaction transaction,
    TransactionController controller,
  ) {
    Color typeColor;
    IconData icon;
    String typeLabel;
    bool isCredit = false;

    switch (transaction.type) {
      case 'deposit':
      case 'admin_credit':
      case 'profit':
        typeColor = KasbyColors.success;
        icon = FontAwesomeIcons.circleArrowDown;
        typeLabel = transaction.type == 'deposit'
            ? 'إيداع'
            : transaction.type == 'profit'
                ? 'أرباح'
                : 'إيداع إداري';
        isCredit = true;
        break;
      case 'withdrawal':
      case 'admin_debit':
        typeColor = KasbyColors.warning;
        icon = FontAwesomeIcons.circleArrowUp;
        typeLabel = transaction.type == 'withdrawal' ? 'سحب' : 'خصم إداري';
        isCredit = false;
        break;
      case 'transfer_in':
        typeColor = Colors.blue;
        icon = FontAwesomeIcons.rightLeft;
        typeLabel = 'تحويل وارد';
        isCredit = true;
        break;
      case 'transfer_out':
        typeColor = Colors.purple;
        icon = FontAwesomeIcons.rightLeft;
        typeLabel = 'تحويل صادر';
        isCredit = false;
        break;
      case 'investment':
        typeColor = KasbyColors.primaryGold;
        icon = FontAwesomeIcons.chartLine;
        typeLabel = 'استثمار';
        isCredit = false;
        break;
      default:
        typeColor = KasbyColors.textSecondary;
        icon = FontAwesomeIcons.moneyBill;
        typeLabel = transaction.type;
        isCredit = true;
    }

    Color statusColor;
    String statusText;
    switch (transaction.status.toLowerCase()) {
      case 'pending':
        statusColor = KasbyColors.warning;
        statusText = 'قيد الانتظار';
        break;
      case 'approved':
      case 'completed':
        statusColor = KasbyColors.success;
        statusText = 'مكتملة';
        break;
      case 'rejected':
      case 'failed':
        statusColor = KasbyColors.error;
        statusText = 'مرفوضة';
        break;
      default:
        statusColor = KasbyColors.textSecondary;
        statusText = transaction.status;
    }

    return KasbyCard(
      child: InkWell(
        onTap: () => _showTransactionDetails(Get.context!, transaction),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: typeColor.withValues(alpha: 0.2)),
                    ),
                    child: Icon(icon, color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.userName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: KasbyColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? "+" : "-"} \$${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isCredit ? KasbyColors.success : KasbyColors.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Colors.white10),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _buildMiniInfo(
                      FontAwesomeIcons.calendarDay,
                      DateFormat('dd MMM, yyyy').format(transaction.createdAt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (transaction.counterpartUserName != null &&
                      transaction.counterpartUserName!.isNotEmpty)
                    Flexible(
                      child: _buildMiniInfo(
                        transaction.type == 'transfer_in'
                            ? FontAwesomeIcons.userPen
                            : FontAwesomeIcons.paperPlane,
                        transaction.counterpartUserName!,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (transaction.runningBalance != null)
                    Flexible(
                      child: _buildMiniInfo(
                        FontAwesomeIcons.wallet,
                        'رصيد: \$${transaction.runningBalance!.toStringAsFixed(2)}',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMiniInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: KasbyColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: KasbyColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'deposit': return 'إيداع';
      case 'withdrawal': return 'سحب';
      case 'transfer_in': return 'تحويل وارد';
      case 'transfer_out': return 'تحويل صادر';
      case 'profit': return 'أرباح';
      case 'admin_credit': return 'إيداع إداري';
      case 'admin_debit': return 'خصم إداري';
      case 'investment': return 'استثمار';
      default: return type;
    }
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    Color statusColor;
    String statusText;
    switch (transaction.status.toLowerCase()) {
      case 'pending':
        statusColor = KasbyColors.warning;
        statusText = 'قيد الانتظار';
        break;
      case 'approved':
      case 'completed':
        statusColor = KasbyColors.success;
        statusText = 'مكتملة';
        break;
      case 'rejected':
      case 'failed':
        statusColor = KasbyColors.error;
        statusText = 'مرفوضة';
        break;
      default:
        statusColor = KasbyColors.textSecondary;
        statusText = transaction.status;
    }

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: KasbyColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Grip
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                    border: Border.all(color: KasbyColors.primaryGold.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(FontAwesomeIcons.fileInvoiceDollar, size: 32, color: KasbyColors.primaryGold),
                ),
                const SizedBox(height: 16),
                
                // Amount
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Details Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('رقم المرجع', transaction.id.substring(0, 8).toUpperCase()),
                      const Divider(height: 24, color: Colors.white10),
                      _buildDetailRow('نوع العملية', _getTypeLabel(transaction.type)),
                      const Divider(height: 24, color: Colors.white10),
                      _buildDetailRow('المستخدم', transaction.userName),
                      
                      if (transaction.counterpartUserName != null && transaction.counterpartUserName!.isNotEmpty) ...[
                        const Divider(height: 24, color: Colors.white10),
                        _buildDetailRow('الطرف الآخر', transaction.counterpartUserName!),
                      ],
                      
                      if (transaction.runningBalance != null) ...[
                        const Divider(height: 24, color: Colors.white10),
                        _buildDetailRow('الرصيد الجاري', '\$${transaction.runningBalance!.toStringAsFixed(2)}'),
                      ],
                      
                      const Divider(height: 24, color: Colors.white10),
                      _buildDetailRow('تاريخ الطلب', DateFormat('dd/MM/yyyy • HH:mm a').format(transaction.createdAt)),
                      
                      if (transaction.processedAt != null) ...[
                        const Divider(height: 24, color: Colors.white10),
                        _buildDetailRow('تاريخ المعالجة', DateFormat('dd/MM/yyyy • HH:mm a').format(transaction.processedAt!)),
                      ],
                      
                      if (transaction.reason != null && transaction.reason!.isNotEmpty) ...[
                        const Divider(height: 24, color: Colors.white10),
                        _buildDetailRow('الملاحظات', transaction.reason!, color: KasbyColors.error),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KasbyColors.textPrimary,
                      foregroundColor: KasbyColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('إغلاق التفاصيل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool highlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: KasbyColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 20),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                  color: color ??
                      (highlight
                          ? KasbyColors.primaryGold
                          : KasbyColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildTransactionsWithFilters(TransactionController controller) {
  //   return Column(
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           children: [
  //             // Time Filter
  //             Obx(
  //               () => SingleChildScrollView(
  //                 scrollDirection: Axis.horizontal,
  //                 child: Row(
  //                   children: [
  //                     _buildSimpleFilterChip(
  //                       'الكل',
  //                       controller.selectedTimeFilter.value == TimeFilter.all,
  //                       () => controller.setTimeFilter(TimeFilter.all),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     _buildSimpleFilterChip(
  //                       'اليوم',
  //                       controller.selectedTimeFilter.value == TimeFilter.daily,
  //                       () => controller.setTimeFilter(TimeFilter.daily),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     _buildSimpleFilterChip(
  //                       'الأسبوع',
  //                       controller.selectedTimeFilter.value == TimeFilter.weekly,
  //                       () => controller.setTimeFilter(TimeFilter.weekly),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     _buildSimpleFilterChip(
  //                       'الشهر',
  //                       controller.selectedTimeFilter.value == TimeFilter.monthly,
  //                       () => controller.setTimeFilter(TimeFilter.monthly),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
              //const SizedBox(height: 12),
              // Type Filter
  //             Obx(
  //               () => SingleChildScrollView(
  //                 scrollDirection: Axis.horizontal,
  //                 child: Row(
  //                   children: [
  //                     _buildSimpleFilterChip(
  //                       'الكل',
  //                       controller.selectedType.value == 'Both',
  //                       () => controller.setTypeFilter('Both'),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     _buildSimpleFilterChip(
  //                       'إيداع',
  //                       controller.selectedType.value == 'deposit',
  //                       () => controller.setTypeFilter('deposit'),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     _buildSimpleFilterChip(
  //                       'سحب',
  //                       controller.selectedType.value == 'withdrawal',
  //                       () => controller.setTypeFilter('withdrawal'),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     _buildSimpleFilterChip(
  //                       'أرباح',
  //                       controller.selectedType.value == 'profit',
  //                       () => controller.setTypeFilter('profit'),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     _buildSimpleFilterChip(
  //                       'تحويلات',
  //                       controller.selectedType.value == 'transfer',
  //                       () => controller.setTypeFilter('transfer'),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       Expanded(
  //         child: Obx(
  //           () => _buildTransactionsList(
  //             controller.filteredTransactions,
  //             controller,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildSimpleFilterChip(
  //     String label, bool isSelected, VoidCallback onTap) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //       decoration: BoxDecoration(
  //         color: isSelected
  //             ? KasbyColors.primaryGold.withValues(alpha: 0.2)
  //             : Colors.transparent,
  //         borderRadius: BorderRadius.circular(12),
  //         border: Border.all(
  //           color: isSelected
  //               ? KasbyColors.primaryGold
  //               : KasbyColors.textSecondary.withValues(alpha: 0.3),
  //         ),
  //       ),
  //       child: Text(label,
  //           style: TextStyle(
  //             fontSize: 12,
  //             color: isSelected
  //                 ? KasbyColors.primaryGold
  //                 : KasbyColors.textSecondary,
  //             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
  //           )),
  //     ),
  //   );
  // }

  void _showReportOptions(BuildContext context, TransactionController controller) {
    Get.bottomSheet(
      KasbyCard(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('توليد تقرير مالي',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.textPrimary)),
            const SizedBox(height: 20),
            _buildReportOption(
              icon: FontAwesomeIcons.fileCsv,
              title: 'تقرير CSV (إكسل)',
              subtitle: 'تصدير كافة المعاملات المفلترة حالياً',
              onTap: () {
                Get.back();
                _generateReport(controller, 'CSV');
              },
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              icon: FontAwesomeIcons.filePdf,
              title: 'تقرير PDF (كشف حساب)',
              subtitle: 'تقرير منسق للطباعة والمشاركة',
              onTap: () {
                Get.back();
                _generateReport(controller, 'PDF');
              },
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              icon: FontAwesomeIcons.chartPie,
              title: 'ملخص إحصائي',
              subtitle: 'عرض ملخص سريع للأداء المالي',
              onTap: () {
                Get.back();
                _showSummaryReport(controller);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildReportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: KasbyColors.primaryGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: KasbyColors.primaryGold, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: KasbyColors.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  Future<void> _generateReport(
      TransactionController controller, String type) async {
    Get.dialog(
      const Center(
          child: CircularProgressIndicator(color: KasbyColors.primaryGold)),
      barrierDismissible: false,
    );

    String path;
    if (type == 'CSV') {
      path = await ReportService.exportToCSV(controller.filteredTransactions);
    } else {
      path = await ReportService.exportToPDF(controller.filteredTransactions);
    }

    Get.back(); // Close loading

    Get.snackbar(
      'تم التوليد',
      'تم حفظ التقرير بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: KasbyColors.surface,
      colorText: KasbyColors.textPrimary,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () => OpenFilex.open(path),
        child: const Text('فتح',
            style: TextStyle(
                color: KasbyColors.primaryGold, fontWeight: FontWeight.bold)),
      ),
    );

    await OpenFilex.open(path);
  }

  void _showSummaryReport(TransactionController controller) {
    final summary = ReportService.generateSummary(controller.filteredTransactions);
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text('الملخص المالي',
            style: TextStyle(color: KasbyColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(
                'إجمالي التداول:',
                '\$${((summary['total_volume'] ?? 0) as num).toDouble().toStringAsFixed(2)}'),
            _buildSummaryRow(
                'صافي التدفق:',
                '\$${((summary['net_flow'] ?? 0) as num).toDouble().toStringAsFixed(2)}'),
            _buildSummaryRow('عدد الإيداعات:', summary['deposit_count'].toString()),
            _buildSummaryRow(
                'عدد السحوبات:', summary['withdrawal_count'].toString()),
            _buildSummaryRow(
                'متوسط الإيداع:',
                '\$${((summary['average_deposit'] ?? 0) as num).toDouble().toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: KasbyColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: KasbyColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
