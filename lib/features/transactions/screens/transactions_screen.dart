import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_model.dart';
import '../../../core/models/time_filter.dart';
import '../services/report_service.dart';
import 'package:open_filex/open_filex.dart';

/// Transactions Screen
/// Manage deposits and withdrawals
class TransactionsScreen extends StatelessWidget {
  final int initialIndex;
  const TransactionsScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionController());

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
              Tab(text: 'الإيداعات قيد التدقيق'),
              Tab(text: 'التسويات المالية المعلقة'),
              Tab(text: 'السجل'),
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
              _buildTransactionsList(controller.pendingDeposits, controller),
              _buildTransactionsList(controller.pendingWithdrawals, controller),
              _buildTransactionsWithFilters(controller),
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
      return const Center(
        child: Text(
          'لا توجد معاملات',
          style: TextStyle(color: KasbyColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
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
    Color statusColor;
    String statusText;

    switch (transaction.status) {
      case 'Pending':
        statusColor = KasbyColors.warning;
        statusText = 'معلق';
        break;
      case 'Approved':
        statusColor = KasbyColors.success;
        statusText = 'موافق عليه';
        break;
      case 'Rejected':
        statusColor = KasbyColors.error;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = KasbyColors.textSecondary;
        statusText = transaction.status;
    }

    return KasbyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: transaction.type == 'Deposit'
                      ? KasbyColors.success.withValues(alpha: 0.2)
                      : KasbyColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction.type == 'Deposit'
                      ? FontAwesomeIcons.arrowDown
                      : FontAwesomeIcons.arrowUp,
                  color: transaction.type == 'Deposit'
                      ? KasbyColors.success
                      : KasbyColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.type == 'Deposit'
                          ? 'إيداع استثماري'
                          : 'تسوية مالية',
                      style: const TextStyle(
                        fontSize: 14,
                        color: KasbyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.wallet,
                  label: 'المبلغ',
                  value: '\$${transaction.amount.toStringAsFixed(2)}',
                  color: KasbyColors.primaryGold,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.clock,
                  label: 'التاريخ',
                  value: DateFormat(
                    'dd/MM/yyyy HH:mm',
                    'en',
                  ).format(transaction.createdAt),
                  color: KasbyColors.info,
                ),
              ),
            ],
          ),
          if (transaction.reason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KasbyColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: KasbyColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'السبب: ${transaction.reason}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: KasbyColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (transaction.status == 'Pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KasbyButton(
                    text: 'رفض',
                    onPressed: () => _showRejectDialog(
                      Get.context!,
                      controller,
                      transaction.id,
                    ),
                    isOutlined: true,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KasbyButton(
                    text: 'موافقة',
                    onPressed: () =>
                        controller.approveTransaction(transaction.id),
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: KasbyColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _showRejectDialog(
    BuildContext context,
    TransactionController controller,
    String transactionId,
  ) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'رفض المعاملة',
          style: TextStyle(color: KasbyColors.textPrimary),
        ),
        content: KasbyTextField(
          controller: reasonController,
          hintText: 'سبب الرفض',
          maxLines: 3,
          prefixIcon: Icons.note,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: KasbyColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                controller.rejectTransaction(
                  transactionId,
                  reasonController.text,
                );
                Get.back();
              } else {
                Get.snackbar('خطأ', 'الرجاء إدخال سبب الرفض');
              }
            },
            child: const Text(
              'رفض',
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsWithFilters(TransactionController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Time Filter
              Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSimpleFilterChip(
                        'الكل',
                        controller.selectedTimeFilter.value == TimeFilter.all,
                        () => controller.setTimeFilter(TimeFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _buildSimpleFilterChip(
                        'اليوم',
                        controller.selectedTimeFilter.value == TimeFilter.daily,
                        () => controller.setTimeFilter(TimeFilter.daily),
                      ),
                      const SizedBox(width: 8),
                      _buildSimpleFilterChip(
                        'الأسبوع',
                        controller.selectedTimeFilter.value ==
                            TimeFilter.weekly,
                        () => controller.setTimeFilter(TimeFilter.weekly),
                      ),
                      const SizedBox(width: 8),
                      _buildSimpleFilterChip(
                        'الشهر',
                        controller.selectedTimeFilter.value ==
                            TimeFilter.monthly,
                        () => controller.setTimeFilter(TimeFilter.monthly),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Type Filter
              Obx(
                () => Row(
                  children: [
                    _buildSimpleFilterChip(
                      'الكل',
                      controller.selectedType.value == 'Both',
                      () => controller.setTypeFilter('Both'),
                    ),
                    const SizedBox(width: 8),
                    _buildSimpleFilterChip(
                      'إيداع استثماري',
                      controller.selectedType.value == 'Deposit',
                      () => controller.setTypeFilter('Deposit'),
                    ),
                    const SizedBox(width: 8),
                    _buildSimpleFilterChip(
                      'سحب',
                      controller.selectedType.value == 'Withdrawal',
                      () => controller.setTypeFilter('Withdrawal'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(
            () => _buildTransactionsList(
              controller.filteredTransactions,
              controller,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? KasbyColors.primaryGold.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? KasbyColors.primaryGold
                : KasbyColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? KasbyColors.primaryGold
                : KasbyColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showReportOptions(
    BuildContext context,
    TransactionController controller,
  ) {
    Get.bottomSheet(
      KasbyCard(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'توليد تقرير مالي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
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
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: KasbyColors.textSecondary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  Future<void> _generateReport(
    TransactionController controller,
    String type,
  ) async {
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(color: KasbyColors.primaryGold),
      ),
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
        child: const Text(
          'فتح',
          style: TextStyle(
            color: KasbyColors.primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    // Also try to open it automatically
    await OpenFilex.open(path);
  }

  void _showSummaryReport(TransactionController controller) {
    final summary = ReportService.generateSummary(
      controller.filteredTransactions,
    );

    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'الملخص المالي',
          style: TextStyle(color: KasbyColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(
              'إجمالي التداول:',
              '\$${(summary['total_volume'] as double).toStringAsFixed(2)}',
            ),
            _buildSummaryRow(
              'صافي التدفق:',
              '\$${(summary['net_flow'] as double).toStringAsFixed(2)}',
            ),
            _buildSummaryRow(
              'عدد الإيداعات:',
              summary['deposit_count'].toString(),
            ),
            _buildSummaryRow(
              'عدد السحوبات:',
              summary['withdrawal_count'].toString(),
            ),
            _buildSummaryRow(
              'متوسط الإيداع:',
              '\$${(summary['average_deposit'] as double).toStringAsFixed(2)}',
            ),
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
          Text(
            label,
            style: const TextStyle(
              color: KasbyColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: KasbyColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
