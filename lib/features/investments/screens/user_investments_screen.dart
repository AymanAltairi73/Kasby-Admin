import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../controllers/investment_controller.dart';
import '../models/investment_model.dart';

/// User Investments Screen
/// View active and completed user investments
class UserInvestmentsScreen extends StatelessWidget {
  const UserInvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InvestmentController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('استثمارات المستخدمين'),
          bottom: const TabBar(
            indicatorColor: KasbyColors.primaryGold,
            labelColor: KasbyColors.primaryGold,
            unselectedLabelColor: KasbyColors.textSecondary,
            tabs: [
              Tab(text: 'النشطة'),
              Tab(text: 'المكتملة'),
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
          children: const [
            SizedBox(height: 100),
            Center(
              child: Text(
                'لا توجد استثمارات',
                style: TextStyle(color: KasbyColors.textSecondary, fontSize: 16),
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
          return _buildInvestmentCard(investment);
        },
      ),
    );
  }

  Widget _buildInvestmentCard(UserInvestment investment) {
    final progress = investment.status == 'Active'
        ? (DateTime.now().difference(investment.startDate).inDays /
              investment.endDate.difference(investment.startDate).inDays)
        : 1.0;

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
                    investment.userName[0],
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
                  color: investment.status == 'Active'
                      ? KasbyColors.success.withValues(alpha: 0.2)
                      : KasbyColors.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  investment.status == 'Active' ? 'نشط' : 'مكتمل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: investment.status == 'Active'
                        ? KasbyColors.success
                        : KasbyColors.info,
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
                  value: '\$${investment.amount.toStringAsFixed(2)}',
                  color: KasbyColors.primaryGold,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.chartLine,
                  label: 'الربح المتوقع',
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
                  label: 'نسبة الربح',
                  value: '${investment.profitPercentage}%',
                  color: KasbyColors.info,
                ),
              ),
            ],
          ),
          if (investment.status == 'Active') ...[
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
}
