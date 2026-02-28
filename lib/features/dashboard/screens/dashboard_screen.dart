import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

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
import '../../chat/controllers/chat_controller.dart';

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
          // Professional Golden Transparent Background
          _buildPremiumGoldenBackground(),

          // Main Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),

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

                      const SizedBox(height: 16),

                      // Urgent Alerts (New Section)
                      _buildUrgentAlerts(transactionController),

                      const SizedBox(height: 16),

                      // Nebula Chart Section
                      const _SectionHeader(
                        title: 'مركز التحليلات المالية والتدفقات',
                        subtitle: 'مؤشرات الأداء الأسبوعية للمحافظ الاستثمارية',
                      ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: KasbyGlassCard(
                          padding: const EdgeInsets.all(16),
                          opacity: 0.08,
                          child: SizedBox(
                            height: 180,
                            child: _buildNebulaChart(),
                          ),
                        ),
                      ),

                      SizedBox(height: 25),

                      // Magical Command Hub
                      const _SectionHeader(
                        title: 'مركز القيادة والتحكم',
                        subtitle: 'وصول فوري لكافة أركان المنظومة',
                      ),
                      SizedBox(height: 25),
                      _buildMagicalActionHub(),

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
                      ),
                      const SizedBox(height: 8),
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

  Widget _buildUrgentAlerts(TransactionController transactionController) {
    return Obx(() {
      final pendingWithdrawals = transactionController.pendingWithdrawals;
      if (pendingWithdrawals.isEmpty) return const SizedBox.shrink();

      return KasbyGlassCard(
        padding: const EdgeInsets.all(12),
        color: KasbyColors.error.withValues(alpha: 0.05),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: KasbyColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تنبيه: هناك ${pendingWithdrawals.length} معاملات سحب بانتظار الموافقة.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/transactions', arguments: 1),
              child: const Text(
                'مراجعة',
                style: TextStyle(color: KasbyColors.primaryGold),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPremiumGoldenBackground() {
    return Stack(
      children: [
        // Base Deep Background
        Container(
          color: const Color(0xFF0F172A), // Slate 900
        ),

        // Subtle Ambient Glows - Top Right
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
                  KasbyColors.primaryGold.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Subtle Ambient Glows - Bottom Left
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
                  KasbyColors.primaryGoldLight.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Noise Texture Overlay (Optional for subtle grain)
        Opacity(
          opacity: 0.03,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/noise.png'),
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
        ),

        // Glass Overlay
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildRoyalAppBar(AuthController authController) {
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
              'لوحة تحكم',
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
              // Magical Chat Trigger
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'مرحباً، ',
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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: KasbyColors.success,
                  shape: BoxShape.circle,
                ),
              ),
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
          ),
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
          .where((inv) => inv.status.toLowerCase() == 'completed')
          .fold(0.0, (sum, inv) => sum + (inv.expectedProfit));

      final totalUsersCount = userController.users
          .where((u) => u.role == 'user')
          .length;
      final activeUsers = userController.users
          .where((u) => u.role == 'user' && u.status.toLowerCase() == 'active')
          .length;
      final pendingTransactions = transactionController.transactions
          .where((t) => t.status.toLowerCase() == 'pending')
          .length;

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          _buildMagicalStatCard(
            title: 'إجمالي المستخدمين',
            value: NumberFormat('#,###').format(totalUsersCount),
            icon: FontAwesomeIcons.users,
            glowColor: KasbyColors.glowGold,
            index: 0,
          ),
          _buildMagicalStatCard(
            title: 'المستخدمون النشطون',
            value: NumberFormat('#,###').format(activeUsers),
            icon: FontAwesomeIcons.userCheck,
            glowColor: KasbyColors.glowGreen,
            index: 1,
          ),
          _buildMagicalStatCard(
            title: 'إجمالي المحافظ الاستثمارية',
            value: '\$${NumberFormat.compact().format(totalInvested)}',
            icon: FontAwesomeIcons.chartLine,
            glowColor: KasbyColors.glowBlue,
            index: 2,
          ),
          _buildMagicalStatCard(
            title: 'الأرباح المحققة',
            value: '\$${NumberFormat.compact().format(totalProfits)}',
            icon: FontAwesomeIcons.moneyBillTrendUp,
            glowColor: KasbyColors.glowGreen,
            index: 3,
          ),
          _buildMagicalStatCard(
            title: 'المعاملات المعلقة',
            value: NumberFormat('#,###').format(pendingTransactions),
            icon: FontAwesomeIcons.bolt,
            glowColor: KasbyColors.glowOrange,
            index: 4,
          ),
          _buildMagicalStatCard(
            title: 'حجم التداول اليومي',
            value:
                '\$${NumberFormat.compact().format(transactionController.transactions.where((t) => t.createdAt.day == DateTime.now().day && t.createdAt.month == DateTime.now().month && t.createdAt.year == DateTime.now().year).fold(0.0, (sum, t) => sum + t.amount))}',
            icon: FontAwesomeIcons.arrowTrendUp,
            glowColor: KasbyColors.glowGold,
            index: 5,
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
      padding: const EdgeInsets.all(12),
      opacity: 0.08,
      child: Stack(
        children: [
          // Inner Glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  center: Alignment.topLeft,
                  radius: 1.2,
                ),
              ),
            ),
          ),

          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 70,
              color: glowColor.withValues(alpha: 0.03),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlowingIcon(icon: icon, color: glowColor, size: 18),
                  Icon(
                    Icons.trending_up_rounded,
                    size: 14,
                    color: glowColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    title,
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
        ],
      ),
    );
  }

  Widget _buildMagicalActionHub() {
    final actions = [
      {
        'title': 'إدارة المستخدمين',
        'icon': FontAwesomeIcons.usersGear,
        'color': KasbyColors.primaryGold,
        'route': '/users',
        'sub': 'تحكم كامل',
      },
      {
        'title': 'طلبات السحب',
        'icon': FontAwesomeIcons.moneyBillTransfer,
        'color': KasbyColors.error,
        'page': 2,
        'sub': '15 طلب معلق',
      },
      {
        'title': 'خطط الاستثمار',
        'icon': FontAwesomeIcons.chartPie,
        'color': KasbyColors.info,
        'route': '/investment-plans',
        'sub': 'إدارة المحافظ',
      },
      {
        'title': 'شبكة الوكلاء',
        'icon': FontAwesomeIcons.networkWired,
        'color': KasbyColors.glowOrange,
        'page': 1,
        'sub': 'نظام التوزيع',
      },
      {
        'title': 'إعدادات النظام',
        'icon': FontAwesomeIcons.gears,
        'color': Colors.purpleAccent,
        'route': '/settings',
        'sub': 'خيارات الطوارئ',
      },
      {
        'title': 'سلفات كاسبي',
        'icon': FontAwesomeIcons.handHoldingDollar,
        'color': KasbyColors.success,
        'route': '/loans',
        'sub': 'نظام القروض',
      },
      {
        'title': 'مركز الإشعارات',
        'icon': FontAwesomeIcons.bullhorn,
        'color': KasbyColors.warning,
        'route': '/notifications',
        'sub': 'تواصل ذكي',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.05,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final color = action['color'] as Color;
        return KasbyGlassCard(
          onTap: () {
            if (action.containsKey('page')) {
              Get.find<MainController>().changePage(action['page'] as int);
            } else if (action.containsKey('route')) {
              Get.toNamed(action['route'] as String);
            }
          },
          padding: const EdgeInsets.all(8),
          opacity: 0.08,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGlowingIcon(
                icon: action['icon'] as IconData,
                color: color,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                action['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action['sub'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        );
      },
    );
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
              color: _getSeverityColor(log.severity).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getSeverityColor(log.severity).withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              _getActionIcon(log.action),
              size: 20,
              color: _getSeverityColor(log.severity),
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
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return KasbyColors.error;
      case 'warning':
        return KasbyColors.warning;
      case 'info':
      default:
        return KasbyColors.success;
    }
  }

  IconData _getActionIcon(String action) {
    final act = action.toLowerCase();
    if (act.contains('error')) return Icons.error_outline_rounded;
    if (act.contains('login') || act.contains('auth'))
      return Icons.lock_outline_rounded;
    if (act.contains('financial') || act.contains('wallet'))
      return Icons.account_balance_wallet_outlined;
    if (act.contains('agent')) return Icons.person_search_rounded;
    if (act.contains('user')) return Icons.people_outline_rounded;
    return Icons.history_rounded;
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      Center(
        child: KasbyGlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          opacity: 0.1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KasbyColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: KasbyColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
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
    );
  }

  // --- NEW MASTERPIECE WIDGETS ---

  Widget _buildGlowingIcon({
    required IconData icon,
    required Color color,
    double size = 20,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size),
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
