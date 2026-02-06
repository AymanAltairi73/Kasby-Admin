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
          bottom: const TabBar(
            indicatorColor: KasbyColors.primaryGold,
            labelColor: KasbyColors.primaryGold,
            unselectedLabelColor: KasbyColors.textSecondary,
            tabs: [
              Tab(text: 'الإيداعات المعلقة'),
              Tab(text: 'السحوبات المعلقة'),
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
                      transaction.type == 'Deposit' ? 'إيداع' : 'سحب',
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
                      'إيداع',
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
}
