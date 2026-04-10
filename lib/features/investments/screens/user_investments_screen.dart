import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../controllers/investment_controller.dart';
import '../models/investment_model.dart';

/// User Investments Screen
/// View pending, active and completed user investments
class UserInvestmentsScreen extends StatelessWidget {
  const UserInvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InvestmentController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('user_investments'.tr),
          bottom: TabBar(
            indicatorColor: KasbyColors.primaryGold,
            labelColor: KasbyColors.primaryGold,
            unselectedLabelColor: KasbyColors.textSecondary,
            tabs: [
              Tab(text: 'tab_pending_investments'.tr),
              Tab(text: 'tab_active_investments'.tr),
              Tab(text: 'tab_completed_investments'.tr),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value &&
              controller.userInvestments.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: KasbyColors.primaryGold),
            );
          }

          return TabBarView(
            children: [
              _buildInvestmentsList(controller.pendingInvestments),
              _buildInvestmentsList(controller.activeInvestments),
              _buildInvestmentsList(controller.completedInvestments),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInvestmentsList(List<UserInvestment> investments) {
    final controller = Get.find<InvestmentController>();
    
    if (investments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => controller.loadUserInvestments(),
        color: KasbyColors.primaryGold,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Text(
                'no_investments_found'.tr,
                style: const TextStyle(color: KasbyColors.textSecondary, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadUserInvestments(),
      color: KasbyColors.primaryGold,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: investments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final investment = investments[index];
          return _buildInvestmentCard(context, investment);
        },
      ),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, UserInvestment investment) {
    final isPending = investment.status.toLowerCase() == 'pending';
    final progress = (investment.status.toLowerCase() == 'active' || investment.status.toLowerCase() == 'completed')
        ? (DateTime.now().difference(investment.startDate).inDays /
              investment.endDate.difference(investment.startDate).inDays)
        : 0.0;

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
                  gradient: KasbyColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    investment.userName.isNotEmpty ? investment.userName[0] : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      investment.planName,
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
                  color: _getStatusColor(investment.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(investment.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(investment.status),
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
                  label: 'amount'.tr,
                  value: '\$${investment.amount.toStringAsFixed(2)}',
                  color: KasbyColors.primaryGold,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.chartLine,
                  label: 'expected_profit'.tr,
                  value: '\$${investment.expectedProfit.toStringAsFixed(2)}',
                  color: KasbyColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.percent,
                  label: 'tooltip_profit_percentage'.tr,
                  value: '${investment.profitPercentage}%',
                  color: KasbyColors.info,
                ),
              ),
            ],
          ),
          if (investment.status.toLowerCase() == 'active') ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'التقدم',
                      style: TextStyle(
                        fontSize: 12,
                        color: KasbyColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.primaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: KasbyColors.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      KasbyColors.primaryGold,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmApproval(context, investment),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text('activate_now'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KasbyColors.success,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context, investment),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text('reject'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KasbyColors.error,
                      side: const BorderSide(color: KasbyColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return KasbyColors.success;
      case 'pending':
        return KasbyColors.primaryGold;
      case 'matured':
      case 'completed':
        return KasbyColors.info;
      case 'rejected':
      case 'cancelled':
        return KasbyColors.error;
      default:
        return KasbyColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'active'.tr;
      case 'pending':
        return 'pending'.tr;
      case 'matured':
      case 'completed':
        return 'completed'.tr;
      case 'rejected':
        return 'rejected'.tr;
      case 'cancelled':
        return 'enum_status_cancelled'.tr;
      default:
        return status;
    }
  }

  void _confirmApproval(BuildContext context, UserInvestment inv) {
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: Text('confirm_now'.tr),
        content: Text('${'confirm_approve_investment'.tr} (${inv.userName})'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء', style: TextStyle(color: KasbyColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<InvestmentController>().approveUserInvestment(inv.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: KasbyColors.success),
            child: Text('confirm'.tr, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, UserInvestment inv) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: Text('reject_investment_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('rejection_reason_hint'.tr),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'rejection_reason_hint'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء', style: TextStyle(color: KasbyColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar('خطأ', 'يرجى إدخال سبب الرفض');
                return;
              }
              Get.back();
              Get.find<InvestmentController>().rejectUserInvestment(
                inv.id,
                reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: KasbyColors.error),
            child: Text('confirm'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
