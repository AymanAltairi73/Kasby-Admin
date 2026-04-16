import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/main_controller.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../controllers/dashboard_controller.dart';

/// Dashboard Home Screen — Restructured Edition
/// Clean sections: Stats → Financial → Actions → Activity
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final dashboardController = Get.put(DashboardController());
    final transactionController = Get.find<TransactionController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(authController),
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Content
          RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                dashboardController.loadDashboardData(),
                transactionController.loadTransactions(),
              ]);
            },
            color: KasbyColors.primaryGold,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),

                  // ═══════════════════════════════════════
                  // Section 1: Welcome + Date
                  // ═══════════════════════════════════════
                  _buildWelcomeSection(authController),
                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════
                  // Section 2: Horizontal Stats Bar
                  // ═══════════════════════════════════════
                  _buildHorizontalStats(dashboardController),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ═══════════════════════════════════════
                        // Section 3: Urgent Alerts
                        // ═══════════════════════════════════════
                        _buildUrgentAlerts(dashboardController),

                        // ═══════════════════════════════════════
                        // Section 4: Financial Overview
                        // ═══════════════════════════════════════
                        _buildSectionTitle(
                          icon: FontAwesomeIcons.chartLine,
                          title: 'النظرة المالية',
                          subtitle: 'ملخص الاستثمارات والأرباح',
                        ),
                        const SizedBox(height: 12),
                        _buildFinancialCards(dashboardController),
                        const SizedBox(height: 16),
                        _buildChart(),
                        const SizedBox(height: 28),

                        // ═══════════════════════════════════════
                        // Section 5: Quick Actions
                        // ═══════════════════════════════════════
                        _buildSectionTitle(
                          icon: FontAwesomeIcons.grip,
                          title: 'مركز التحكم',
                          subtitle: 'وصول سريع لكافة الأقسام',
                        ),
                        const SizedBox(height: 12),
                        _buildActionHub(),
                        const SizedBox(height: 28),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BACKGROUND
  // ═══════════════════════════════════════════════════════════

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF0F172A)),
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  KasbyColors.primaryGold.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  KasbyColors.primaryGoldLight.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  APP BAR
  // ═══════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(AuthController authController) {
    final chatController = Get.find<ChatController>();
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.02),
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'لوحة التحكم',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
            leadingWidth: 70,
            leading: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Get.toNamed('/profile'),
                child: Obx(() {
                  final avatarUrl = authController.profile.value?.avatarUrl;
                  return Container(
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
                    child: CircleAvatar(
                      backgroundColor: Colors.black26,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              color: KasbyColors.primaryGold,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white70,
                ),
                onPressed: () => Get.toNamed('/notifications-list'),
              ),
              Obx(
                () => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.commentDots,
                        color: KasbyColors.primaryGold,
                        size: 20,
                      ),
                      onPressed: () => Get.toNamed('/chat-list'),
                    ),
                    if (chatController.unreadTotal.value > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: KasbyColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${chatController.unreadTotal.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // IconButton(
              //   icon: const Icon(
              //     Icons.power_settings_new_rounded,
              //     color: KasbyColors.error,
              //   ),
              //   onPressed: () => _showLogoutDialog(authController),
              // ),
              // const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SECTION 1: WELCOME
  // ═══════════════════════════════════════════════════════════

  Widget _buildWelcomeSection(AuthController authController) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);
    final greeting = _getGreeting(now.hour);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$greeting، ',
                  style: TextStyle(
                    fontSize: 22,
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
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: KasbyColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء الخير';
  }

  // ═══════════════════════════════════════════════════════════
  //  SECTION 2: HORIZONTAL STATS BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildHorizontalStats(DashboardController dc) {
    return SizedBox(
      height: 100,
      child: Obx(
        () => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildStatChip(
              title: 'المستخدمين',
              value: NumberFormat('#,###').format(dc.totalUsers),
              icon: FontAwesomeIcons.users,
              color: KasbyColors.glowGold,
            ),
            _buildStatChip(
              title: 'النشطون',
              value: NumberFormat('#,###').format(dc.activeUsers),
              icon: FontAwesomeIcons.userCheck,
              color: KasbyColors.glowGreen,
            ),
            // _buildStatChip(
            //   title: 'معاملات معلقة',
            //   value: NumberFormat('#,###').format(dc.pendingTransactions),
            //   icon: FontAwesomeIcons.clockRotateLeft,
            //   color: KasbyColors.glowOrange,
            // ),
            // _buildStatChip(
            //   title: 'حجم التداول',
            //   value: '\$${NumberFormat.compact().format(dc.dailyVolume)}',
            //   icon: FontAwesomeIcons.arrowTrendUp,
            //   color: KasbyColors.glowBlue,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(left: 10),
      child: KasbyGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        opacity: 0.08,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: color),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SECTION 3: URGENT ALERTS
  // ═══════════════════════════════════════════════════════════

  Widget _buildUrgentAlerts(DashboardController dc) {
    return Obx(() {
      final wCount = dc.pendingWithdrawalsCount.value;
      final kCount = dc.pendingKYCCount.value;

      if (wCount == 0 && kCount == 0) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            if (wCount > 0)
              _buildAlertCard(
                title: 'طلبات سحب معلقة',
                subtitle: '$wCount طلب سحب بانتظار الموافقة',
                icon: Icons.account_balance_wallet_rounded,
                color: KasbyColors.error,
                onTap: () => Get.toNamed('/transactions', arguments: 1),
              ),
            if (wCount > 0 && kCount > 0) const SizedBox(height: 12),
            if (kCount > 0)
              _buildAlertCard(
                title: 'توثيق هوية معلق',
                subtitle: '$kCount حساب بانتظار التوثيق',
                icon: Icons.verified_user_rounded,
                color: KasbyColors.info,
                onTap: () => Get.toNamed('/kyc'),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildAlertCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return KasbyGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: color.withValues(alpha: 0.5),
            size: 14,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SECTION 4: FINANCIAL OVERVIEW
  // ═══════════════════════════════════════════════════════════

  Widget _buildFinancialCards(DashboardController dc) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildFinancialTile(
              title: 'إجمالي الاستثمار',
              value: '\$${NumberFormat('#,##0').format(dc.totalInvested)}',
              icon: FontAwesomeIcons.chartPie,
              color: KasbyColors.glowBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFinancialTile(
              title: 'الأرباح المحققة',
              value: '\$${NumberFormat('#,##0').format(dc.totalProfits)}',
              icon: FontAwesomeIcons.moneyBillTrendUp,
              color: KasbyColors.glowGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تدفقات الأسبوع',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '7 أيام',
                  style: TextStyle(
                    fontSize: 10,
                    color: KasbyColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: SizedBox(
              height: 160,
              child: LineChart(
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
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 4),
                        FlSpot(2, 3.5),
                        FlSpot(3, 5),
                        FlSpot(4, 4.5),
                        FlSpot(5, 6),
                        FlSpot(6, 5.8),
                      ],
                      isCurved: true,
                      color: KasbyColors.primaryGold,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 3,
                              color: Colors.black,
                              strokeWidth: 2,
                              strokeColor: KasbyColors.primaryGold,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            KasbyColors.primaryGold.withValues(alpha: 0.15),
                            KasbyColors.primaryGold.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      shadow: Shadow(
                        color: KasbyColors.primaryGold.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SECTION 5: ACTION HUB (4 columns)
  // ═══════════════════════════════════════════════════════════

  Widget _buildActionHub() {
    final actions = [
      _ActionItem(
        'المستخدمين',
        FontAwesomeIcons.usersGear,
        KasbyColors.primaryGold,
        route: '/users',
      ),
      _ActionItem(
        'المعاملات',
        FontAwesomeIcons.moneyBillTransfer,
        KasbyColors.error,
        page: 2,
      ),
      _ActionItem(
        'الاستثمار',
        FontAwesomeIcons.chartPie,
        KasbyColors.info,
        route: '/investment-plans',
      ),
      _ActionItem(
        'الوكلاء',
        FontAwesomeIcons.networkWired,
        KasbyColors.glowOrange,
        page: 1,
      ),
      _ActionItem(
        'الإعدادات',
        FontAwesomeIcons.gears,
        Colors.purpleAccent,
        route: '/settings',
      ),
      _ActionItem(
        'السلفات',
        FontAwesomeIcons.handHoldingDollar,
        KasbyColors.success,
        route: '/loans',
      ),
      // _ActionItem('الإشعارات', FontAwesomeIcons.bullhorn, KasbyColors.warning, route: '/notifications'),
      _ActionItem(
        'الاشتراكات',
        FontAwesomeIcons.crown,
        KasbyColors.primaryGold,
        route: '/subscriptions',
      ),
      _ActionItem(
        'توثيق الهوية',
        FontAwesomeIcons.idCard,
        Colors.cyanAccent,
        route: '/kyc',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return KasbyGlassCard(
          onTap: () {
            if (action.page != null) {
              Get.find<MainController>().changePage(action.page!);
            } else if (action.route != null) {
              Get.toNamed(action.route!);
            }
          },
          padding: const EdgeInsets.all(8),
          opacity: 0.06,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: KasbyColors.primaryGold),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 22),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Color _getSeverityColor(String severity) {
  //   switch (severity.toLowerCase()) {
  //     case 'critical':
  //       return KasbyColors.error;
  //     case 'warning':
  //       return KasbyColors.warning;
  //     case 'info':
  //     default:
  //       return KasbyColors.success;
  //   }
  // }

  // IconData _getActionIcon(String action) {
  //   final act = action.toLowerCase();
  //   if (act.contains('error')) return Icons.error_outline_rounded;
  //   if (act.contains('login') || act.contains('auth')) {
  //     return Icons.lock_outline_rounded;
  //   }
  //   if (act.contains('financial') || act.contains('wallet')) {
  //     return Icons.account_balance_wallet_outlined;
  //   }
  //   if (act.contains('agent')) return Icons.person_search_rounded;
  //   if (act.contains('user')) return Icons.people_outline_rounded;
  //   return Icons.history_rounded;
  // }

  // void _showLogoutDialog(AuthController authController) {
  //   Get.dialog(
  //     Center(
  //       child: KasbyGlassCard(
  //         margin: const EdgeInsets.symmetric(horizontal: 32),
  //         padding: const EdgeInsets.all(24),
  //         opacity: 0.1,
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 color: KasbyColors.error.withValues(alpha: 0.1),
  //                 shape: BoxShape.circle,
  //               ),
  //               child: const Icon(
  //                 Icons.logout_rounded,
  //                 color: KasbyColors.error,
  //                 size: 32,
  //               ),
  //             ),
  //             const SizedBox(height: 24),
  //             const Text(
  //               'تسجيل الخروج',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.white,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
  //               textAlign: TextAlign.center,
  //               style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
  //             ),
  //             const SizedBox(height: 32),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: TextButton(
  //                     onPressed: () => Get.back(),
  //                     child: Text(
  //                       'إلغاء',
  //                       style: TextStyle(
  //                         color: Colors.white.withValues(alpha: 0.5),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 16),
  //                 Expanded(
  //                   child: Container(
  //                     decoration: BoxDecoration(
  //                       color: KasbyColors.error.withValues(alpha: 0.2),
  //                       borderRadius: BorderRadius.circular(12),
  //                       border: Border.all(
  //                         color: KasbyColors.error.withValues(alpha: 0.3),
  //                       ),
  //                     ),
  //                     child: TextButton(
  //                       onPressed: () {
  //                         Get.back();
  //                         authController.logout();
  //                       },
  //                       child: const Text(
  //                         'تأكيد الخروج',
  //                         style: TextStyle(
  //                           color: KasbyColors.error,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

// Simple data class for action items
class _ActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final String? route;
  final int? page;

  const _ActionItem(this.title, this.icon, this.color, {this.route, this.page});
}
