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
import '../../users/controllers/user_controller.dart';
import '../../investments/controllers/investment_controller.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../models/audit_log_model.dart';
import '../../notifications/screens/notifications_screen.dart';

/// Dashboard Home Screen - Masterpiece Edition
/// Main overview with celestial aesthetics and magical interactions
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final auditController = Get.find<AuditController>();
    final userController = Get.find<UserController>();
    final investmentController = Get.find<InvestmentController>();
    final transactionController = Get.find<TransactionController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildRoyalAppBar(authController),
      body: Stack(
        children: [
          // Celestial Multi-Depth Background
          RepaintBoundary(child: _buildCelestialBackground()),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 140),

                // Magical Welcome Header
                _buildMagicalHeader(authController),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Magical Statistics Grid
                      _buildMagicalStatsGrid(
                        userController,
                        investmentController,
                        transactionController,
                      ),

                      const SizedBox(height: 32),

                      // Nebula Chart Section
                      const _SectionHeader(
                        title: 'التحليلات المالية والتدفقات',
                        subtitle: 'مؤشرات الأداء الأسبوعية للاستثمارات',
                      ).animate().fadeIn(
                        delay: const Duration(milliseconds: 800),
                      ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child:
                            KasbyGlassCard(
                                  padding: const EdgeInsets.all(24),
                                  opacity: 0.08,
                                  child: SizedBox(
                                    height: 220,
                                    child: _buildNebulaChart(),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .scale(begin: const Offset(0.95, 0.95)),
                      ),

                      const SizedBox(height: 32),

                      // Floating Action Tiles
                      const _SectionHeader(title: 'بوابات الوصول السريع'),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildFloatingActionTile(
                              'الإيداعات الاستثمارية',
                              '23 طلب قيد المعالجة',
                              FontAwesomeIcons.circleArrowDown,
                              KasbyColors.success,
                              () => Get.find<MainController>().changePage(2),
                            ),
                            _buildFloatingActionTile(
                              'التسويات المالية (السحب)',
                              '15 طلب قيد المعالجة',
                              FontAwesomeIcons.circleArrowUp,
                              KasbyColors.error,
                              () => Get.find<MainController>().changePage(2),
                            ),
                            _buildFloatingActionTile(
                              'خطط الاستثمار المعتمدة',
                              'إدارة الخطط',
                              FontAwesomeIcons.chartPie,
                              KasbyColors.info,
                              () => Get.toNamed('/investment-plans'),
                            ),
                            _buildFloatingActionTile(
                              'استثماراتنا',
                              'نشاط العملاء',
                              FontAwesomeIcons.moneyBillTrendUp,
                              KasbyColors.warning,
                              () => Get.toNamed('/user-investments'),
                            ),
                            _buildFloatingActionTile(
                              'المكافآت',
                              'النقاط والهدايا',
                              FontAwesomeIcons.gift,
                              Colors.purpleAccent,
                              () => Get.toNamed('/rewards'),
                            ),
                            _buildFloatingActionTile(
                              'الوكلاء',
                              'عرض الشبكة',
                              FontAwesomeIcons.userTie,
                              KasbyColors.glowOrange,
                              () => Get.find<MainController>().changePage(1),
                            ),
                            _buildFloatingActionTile(
                              'إرسال اشعار',
                              'إشعار عام',
                              FontAwesomeIcons.wandMagicSparkles,
                              KasbyColors.primaryGold,
                              () => Get.to(() => const NotificationsScreen()),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                        delay: const Duration(milliseconds: 1000),
                      ),

                      const SizedBox(height: 32),

                      // Celestial Activity Feed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionHeader(title: 'آخر التحركات'),
                          TextButton(
                            onPressed: () => Get.toNamed('/audit-logs'),
                            child: Row(
                              children: [
                                Text(
                                  'مشاهدة السجل',
                                  style: TextStyle(
                                    color: KasbyColors.primaryGold.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: KasbyColors.primaryGold.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(
                        delay: const Duration(milliseconds: 1100),
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
                          children: auditController.logs
                              .take(3)
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                                final int index = entry.key;
                                final log = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildCelestialLogItem(log, index),
                                );
                              })
                              .toList(),
                        );
                      }),
                      const SizedBox(height: 100), // Spacing for bottom nav bar
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

  PreferredSizeWidget _buildRoyalAppBar(AuthController authController) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.02),
            elevation: 0,
            centerTitle: true,
            title:
                const Text(
                      'منظومة كاسبي الإدارية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: const Duration(seconds: 3),
                      color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                    ),
            leadingWidth: 70,
            leading: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Get.toNamed('/profile'),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KasbyColors.primaryGold.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KasbyColors.primaryGold.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: Icon(
                      Icons.person_rounded,
                      color: KasbyColors.primaryGold,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white70,
                ),
                onPressed: () => Get.toNamed('/notifications'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.power_settings_new_rounded,
                  color: KasbyColors.error,
                ),
                onPressed: () => _showLogoutDialog(authController),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalHeader(AuthController authController) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'مرحباً، ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  TextSpan(
                    text: authController.userName.value.isNotEmpty
                        ? authController.userName.value
                        : 'المدير',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: KasbyColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 6),
          Text(
            'الحالة العامة للنظام تحت سيطرتك الآن.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.4),
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: KasbyColors.success,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    duration: const Duration(seconds: 1),
                  )
                  .fadeOut(duration: const Duration(seconds: 1)),
              const SizedBox(width: 8),
              Text(
                'حساب نشط',
                style: TextStyle(
                  fontSize: 10,
                  color: KasbyColors.success.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
        ],
      ),
    );
  }

  Widget _buildMagicalStatsGrid(
    UserController userController,
    InvestmentController investmentController,
    TransactionController transactionController,
  ) {
    return Obx(() {
      final totalInvested = investmentController.userInvestments.fold(
        0.0,
        (sum, inv) => sum + inv.amount,
      );

      final totalProfits = investmentController.userInvestments
          .where((inv) => inv.status == 'Completed')
          .fold(0.0, (sum, inv) => sum + (inv.expectedProfit));

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildMagicalStatCard(
            title: 'إجمالي المستخدمين',
            value: NumberFormat('#,###').format(userController.users.length),
            icon: FontAwesomeIcons.users,
            glowColor: KasbyColors.glowGold,
            index: 0,
          ),
          _buildMagicalStatCard(
            title: 'حجم الاستثمارات',
            value: '\$${NumberFormat.compact().format(totalInvested)}',
            icon: FontAwesomeIcons.chartLine,
            glowColor: KasbyColors.glowGreen,
            index: 1,
          ),
          _buildMagicalStatCard(
            title: 'الأرباح المدفوعة',
            value: '\$${NumberFormat.compact().format(totalProfits)}',
            icon: FontAwesomeIcons.moneyBillTrendUp,
            glowColor: KasbyColors.glowBlue,
            index: 2,
          ),
          _buildMagicalStatCard(
            title: 'المعاملات المعلقة',
            value: NumberFormat('#,###').format(
              transactionController.transactions
                  .where((t) => t.status == 'Pending')
                  .length,
            ),
            icon: FontAwesomeIcons.bolt,
            glowColor: KasbyColors.glowOrange,
            index: 3,
          ),
        ],
      );
    });
  }

  Widget _buildMagicalStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color glowColor,
    required int index,
  }) {
    return KasbyGlassCard(
          padding: const EdgeInsets.all(16),
          opacity: 0.05,
          child: Stack(
            children: [
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  icon,
                  size: 80,
                  color: glowColor.withValues(alpha: 0.05),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: glowColor.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(icon, color: glowColor, size: 20),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: const Duration(seconds: 2),
                      )
                      .shimmer(color: Colors.white24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: const Duration(milliseconds: 600))
        .scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildNebulaChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.03),
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
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: Colors.black,
                    strokeWidth: 2,
                    strokeColor: KasbyColors.primaryGold,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  KasbyColors.primaryGold.withValues(alpha: 0.2),
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

  Widget _buildFloatingActionTile(
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: KasbyGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        opacity: 0.1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: color, size: 24),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -2, end: 2, duration: const Duration(seconds: 2)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelestialLogItem(AuditLog log, int index) {
    return KasbyGlassCard(
          padding: const EdgeInsets.all(16),
          opacity: 0.05,
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _getLogTypeColor(log.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getLogTypeColor(log.type).withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  log.icon,
                  size: 20,
                  color: _getLogTypeColor(log.type),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.action,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'بواسطة: ${log.adminName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(
                      DateFormat('HH:mm', 'en').format(log.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.primaryGold,
                      ),
                    ),
                  ),
                  Text(
                    'اليوم',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .slideX(begin: 0.1);
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

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: KasbyGlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: KasbyColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: KasbyColors.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'خروج من النظام؟',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'هل أنت متأكد من رغبتك في إغلاق هذه الجلسة',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'تحليق بالبقاء',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: KasbyColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: KasbyColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            authController.logout();
                          },
                          child: const Text(
                            'تأكيد الخروج',
                            style: TextStyle(
                              color: KasbyColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        // Deep Space Base
        Container(color: const Color(0xFF0F172A)),

        // Distant Nebula Orbs (Depth 1)
        _buildOrb(
          top: -150,
          right: -100,
          size: 500,
          color: KasbyColors.primaryGold.withValues(alpha: 0.04),
          duration: const Duration(seconds: 15),
        ),

        // Dynamic Glow Orbs (Depth 2)
        _buildOrb(
          bottom: 100,
          left: -50,
          size: 350,
          color: KasbyColors.info.withValues(alpha: 0.03),
          duration: const Duration(seconds: 12),
        ),

        // Near Field Particles (Depth 3)
        _buildOrb(
          top: 300,
          right: 50,
          size: 150,
          color: KasbyColors.success.withValues(alpha: 0.02),
          duration: const Duration(seconds: 8),
        ),
      ],
    );
  }

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required Duration duration,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: RepaintBoundary(
        child:
            Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color,
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -30, end: 30, duration: duration)
                .moveX(
                  begin: -20,
                  end: 20,
                  duration: duration + const Duration(seconds: 2),
                ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
