import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/audit_controller.dart';
import '../controllers/main_controller.dart';
import '../models/audit_log_model.dart';
import '../../notifications/screens/notifications_screen.dart';

/// Dashboard Home Screen
/// Main overview with statistics and quick actions
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final auditController = Get.put(AuditController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Kasby Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Get.toNamed('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(authController),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient blobs
          Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 800))
              .scale(begin: const Offset(0.5, 0.5)),

          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radiant Welcome Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        KasbyColors.primaryGold.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                            () => Text(
                              'مرحباً، ${authController.userRole.value}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 200))
                          .slideX(begin: -0.2),
                      const SizedBox(height: 8),
                      const Text(
                        'إليك ملخص أداء النظام اليوم',
                        style: TextStyle(
                          fontSize: 16,
                          color: KasbyColors.textSecondary,
                        ),
                      ).animate().fadeIn(
                        delay: const Duration(milliseconds: 400),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Glowing Statistics Grid
                      GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children: [
                              _buildGlowingStatCard(
                                title: 'إجمالي المستخدمين',
                                value: '12,543',
                                icon: FontAwesomeIcons.users,
                                glowColor: KasbyColors.glowGold,
                              ),
                              _buildGlowingStatCard(
                                title: 'حجم الاستثمارات',
                                value: '\$2.4M',
                                icon: FontAwesomeIcons.chartLine,
                                glowColor: KasbyColors.glowGreen,
                              ),
                              _buildGlowingStatCard(
                                title: 'الأرباح المدفوعة',
                                value: '\$184K',
                                icon: FontAwesomeIcons.moneyBillTrendUp,
                                glowColor: KasbyColors.glowBlue,
                              ),
                              _buildGlowingStatCard(
                                title: 'المعاملات اليومية',
                                value: '1,234',
                                icon: FontAwesomeIcons.bolt,
                                glowColor: KasbyColors.glowOrange,
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 600))
                          .slideY(begin: 0.2),

                      const SizedBox(height: 32),

                      // Chart Section with Glassmorphism
                      const _SectionHeader(
                        title: 'الاتجاه الأسبوعي (المعاملات)',
                      ),
                      const SizedBox(height: 16),
                      KasbyGlassCard(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          height: 220,
                          child: _buildEnhancedChart(),
                        ),
                      ).animate().fadeIn(
                        delay: const Duration(milliseconds: 800),
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions
                      const _SectionHeader(title: 'إجراءات سريعة'),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCompactAction(
                              'الإيداعات',
                              '23 طلب',
                              FontAwesomeIcons.circleArrowDown,
                              () => Get.find<MainController>().changePage(2),
                            ),
                            _buildCompactAction(
                              'السحوبات',
                              '15 طلب',
                              FontAwesomeIcons.circleArrowUp,
                              () => Get.find<MainController>().changePage(2),
                            ),
                            _buildCompactAction(
                              'إرسال إشعار',
                              'عام',
                              FontAwesomeIcons.paperPlane,
                              () => Get.to(() => const NotificationsScreen()),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                        delay: const Duration(milliseconds: 900),
                      ),

                      const SizedBox(height: 32),

                      // Recent Activity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionHeader(title: 'آخر النشاطات'),
                          TextButton(
                            onPressed: () => Get.toNamed('/audit-logs'),
                            child: const Text(
                              'عرض الكل',
                              style: TextStyle(color: KasbyColors.primaryGold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        if (auditController.isLoading.value &&
                            auditController.logs.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: KasbyColors.primaryGold,
                            ),
                          );
                        }
                        return Column(
                          children: auditController.logs.take(3).map((log) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildActivityItem(log),
                            );
                          }).toList(),
                        );
                      }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color glowColor,
  }) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.05,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 60,
              color: glowColor.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: glowColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: glowColor, size: 18),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: const Duration(seconds: 2),
                    color: glowColor.withValues(alpha: 0.2),
                  ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: KasbyColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 3),
              const FlSpot(1, 4),
              const FlSpot(2, 3.5),
              const FlSpot(3, 5),
              const FlSpot(4, 4.5),
              const FlSpot(5, 6),
              const FlSpot(6, 5.8),
            ],
            isCurved: true,
            color: KasbyColors.primaryGold,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  KasbyColors.primaryGold.withValues(alpha: 0.3),
                  KasbyColors.primaryGold.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            shadow: Shadow(
              color: KasbyColors.primaryGold.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAction(
    String title,
    String sub,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: KasbyGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: KasbyColors.primaryGold, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              sub,
              style: const TextStyle(
                color: KasbyColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      KasbyGlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 250),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: KasbyColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'تسجيل الخروج',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
              textAlign: TextAlign.center,
              style: TextStyle(color: KasbyColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(color: KasbyColors.textSecondary),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      authController.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KasbyColors.error,
                    ),
                    child: const Text(
                      'خروج',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(AuditLog log) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(12),
      opacity: 0.05,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getLogTypeColor(log.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(log.icon, size: 18, color: _getLogTypeColor(log.type)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  log.adminName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: KasbyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              DateFormat('HH:mm', 'en').format(log.timestamp),
              style: const TextStyle(
                fontSize: 11,
                color: KasbyColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogTypeColor(AuditLogType type) {
    switch (type) {
      case AuditLogType.security:
        return KasbyColors.error;
      case AuditLogType.financial:
        return KasbyColors.success;
      case AuditLogType.userManagement:
        return KasbyColors.info;
      case AuditLogType.investment:
        return KasbyColors.primaryGold;
      case AuditLogType.system:
        return KasbyColors.warning;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }
}
