import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../auth/controllers/auth_controller.dart';

/// Dashboard Home Screen
/// Main overview with statistics and quick actions
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  backgroundColor: KasbyColors.surface,
                  title: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: KasbyColors.textPrimary),
                  ),
                  content: const Text(
                    'هل أنت متأكد من تسجيل الخروج؟',
                    style: TextStyle(color: KasbyColors.textBody),
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
                        Get.back();
                        authController.logout();
                      },
                      child: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: KasbyColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Obx(
              () => Text(
                'مرحباً، ${authController.userRole.value}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: KasbyColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'نظرة عامة على النظام',
              style: TextStyle(fontSize: 14, color: KasbyColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  title: 'إجمالي المستخدمين',
                  value: '12,543',
                  icon: FontAwesomeIcons.users,
                  color: KasbyColors.primaryGold,
                ),
                _buildStatCard(
                  title: 'حجم الاستثمارات',
                  value: '\$2.4M',
                  icon: FontAwesomeIcons.chartLine,
                  color: KasbyColors.success,
                ),
                _buildStatCard(
                  title: 'الأرباح المدفوعة',
                  value: '\$184K',
                  icon: FontAwesomeIcons.moneyBillTrendUp,
                  color: KasbyColors.info,
                ),
                _buildStatCard(
                  title: 'المعاملات اليومية',
                  value: '1,234',
                  icon: FontAwesomeIcons.arrowRightArrowLeft,
                  color: KasbyColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weekly Trend Chart
            const Text(
              'الاتجاه الأسبوعي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            KasbyCard(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          const FlSpot(0, 3),
                          const FlSpot(1, 4),
                          const FlSpot(2, 3.5),
                          const FlSpot(3, 5),
                          const FlSpot(4, 4),
                          const FlSpot(5, 6),
                          const FlSpot(6, 5.5),
                        ],
                        isCurved: true,
                        color: KasbyColors.primaryGold,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: KasbyColors.primaryGold.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionCard(
              title: 'الإيداعات المعلقة',
              subtitle: '23 طلب جديد',
              icon: FontAwesomeIcons.clockRotateLeft,
              onTap: () {
                // Navigate to pending deposits
                Get.snackbar('قريباً', 'هذه الميزة قيد التطوير');
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActionCard(
              title: 'السحوبات المعلقة',
              subtitle: '15 طلب جديد',
              icon: FontAwesomeIcons.moneyBillTransfer,
              onTap: () {
                // Navigate to pending withdrawals
                Get.snackbar('قريباً', 'هذه الميزة قيد التطوير');
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActionCard(
              title: 'إرسال إشعار',
              subtitle: 'إرسال إشعار لجميع المستخدمين',
              icon: FontAwesomeIcons.bellConcierge,
              onTap: () {
                // Navigate to send notification
                Get.snackbar('قريباً', 'هذه الميزة قيد التطوير');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: KasbyColors.surface,
        selectedItemColor: KasbyColors.primaryGold,
        unselectedItemColor: KasbyColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'المستخدمين',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'المعاملات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on dashboard
              break;
            case 1:
              Get.toNamed('/users');
              break;
            case 2:
              Get.toNamed('/transactions');
              break;
            case 3:
              Get.toNamed('/settings');
              break;
          }
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return KasbyCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: KasbyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return KasbyCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: KasbyColors.primaryGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: KasbyColors.primaryGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: KasbyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: KasbyColors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }
}
