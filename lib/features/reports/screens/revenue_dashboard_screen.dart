import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/admin_metric_chip.dart';

// ═══════════════════════════════════════════════════════════
//  CONTROLLER
// ═══════════════════════════════════════════════════════════

class ReportsController extends GetxController {
  final isLoading = false.obs;
  final hasError = false.obs;
  final summary = <String, dynamic>{}.obs;

  final selectedRange = 'last_30'.obs;
  final customStart = Rxn<DateTime>();
  final customEnd = Rxn<DateTime>();

  // Chart data
  final dailyRevenue = <Map<String, dynamic>>[].obs;
  final dailyVolume = <Map<String, dynamic>>[].obs;
  final investmentDistribution = <Map<String, dynamic>>[].obs;

  // Previous period comparison
  final prevDeposits = 0.0.obs;
  final prevWithdrawals = 0.0.obs;
  final prevProfits = 0.0.obs;
  final prevNetFlow = 0.0.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'ReportsController',
      method: 'onInit',
      feature: 'Reports',
      status: 'INFO',
    );
    super.onInit();
    loadSummary();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'ReportsController',
      method: 'onClose',
      feature: 'Reports',
      status: 'INFO',
    );
    super.onClose();
  }

  DateTime get _rangeStart {
    if (selectedRange.value == 'custom' && customStart.value != null) {
      return customStart.value!;
    }
    final now = DateTime.now();
    switch (selectedRange.value) {
      case 'last_7':
        return now.subtract(const Duration(days: 7));
      case 'last_90':
        return now.subtract(const Duration(days: 90));
      case 'last_30':
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  DateTime get _rangeEnd {
    if (selectedRange.value == 'custom' && customEnd.value != null) {
      return customEnd.value!;
    }
    return DateTime.now();
  }

  int get _rangeDays => _rangeEnd.difference(_rangeStart).inDays.clamp(1, 365);

  void changeRange(String range) {
    selectedRange.value = range;
    loadSummary();
  }

  Future<void> pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: customStart.value ?? DateTime.now().subtract(const Duration(days: 30)),
        end: customEnd.value ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: KasbyColors.primaryGold,
              onPrimary: Colors.black,
              surface: KasbyColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      customStart.value = picked.start;
      customEnd.value = picked.end;
      selectedRange.value = 'custom';
      loadSummary();
    }
  }

  Future<void> loadSummary() async {
    AppLoggerService.debugTrace(
      className: 'ReportsController',
      method: 'loadSummary',
      feature: 'Reports',
      status: 'INFO',
    );
    isLoading.value = true;
    hasError.value = false;
    try {
      final startIso = _rangeStart.toUtc().toIso8601String();
      final endIso = _rangeEnd.toUtc().toIso8601String();

      final response = await SupabaseService.client
          .from('transactions')
          .select('id, type, amount, status, created_at')
          .gte('created_at', startIso)
          .lte('created_at', endIso)
          .order('created_at', ascending: true)
          .limit(5000);

      final rows = (response as List).map((e) => {
            'type': e['type'],
            'amount': (e['amount'] as num? ?? 0).toDouble(),
            'status': e['status'],
            'created_at': e['created_at'],
          }).toList();

      double deposits = 0;
      double withdrawals = 0;
      double profits = 0;
      double adminCredits = 0;

      final dailyMap = <String, Map<String, double>>{};
      final volumeMap = <String, Map<String, double>>{};

      for (final row in rows) {
        final type = (row['type'] as String? ?? '').toLowerCase();
        final status = (row['status'] as String? ?? '').toLowerCase();
        final amount = row['amount'] as double;
        final dateKey = (row['created_at'] as String).substring(0, 10);

        dailyMap.putIfAbsent(dateKey, () => {'revenue': 0});
        volumeMap.putIfAbsent(dateKey, () => {'deposits': 0, 'withdrawals': 0});

        if (!['completed', 'approved'].contains(status)) continue;

        switch (type) {
          case 'deposit':
            deposits += amount;
            volumeMap[dateKey]!['deposits'] =
                (volumeMap[dateKey]!['deposits'] ?? 0) + amount;
            dailyMap[dateKey]!['revenue'] =
                (dailyMap[dateKey]!['revenue'] ?? 0) + amount;
          case 'withdrawal':
            withdrawals += amount;
            volumeMap[dateKey]!['withdrawals'] =
                (volumeMap[dateKey]!['withdrawals'] ?? 0) + amount;
          case 'profit':
            profits += amount;
            dailyMap[dateKey]!['revenue'] =
                (dailyMap[dateKey]!['revenue'] ?? 0) + amount;
          case 'admin_credit':
            adminCredits += amount;
          default:
            break;
        }
      }

      summary.value = {
        'total_deposits': deposits,
        'total_withdrawals': withdrawals,
        'net_flow': deposits - withdrawals,
        'total_profits': profits,
        'admin_credits': adminCredits,
        'transaction_count': rows.length,
      };

      // Build chart data
      final sortedDays = dailyMap.keys.toList()..sort();
      dailyRevenue.assignAll(
        sortedDays.map((d) => {'date': d, 'revenue': dailyMap[d]!['revenue'] ?? 0.0}),
      );

      final sortedVolDays = volumeMap.keys.toList()..sort();
      dailyVolume.assignAll(
        sortedVolDays.map((d) => {
              'date': d,
              'deposits': volumeMap[d]!['deposits'] ?? 0.0,
              'withdrawals': volumeMap[d]!['withdrawals'] ?? 0.0,
            }),
      );

      // Investment distribution
      await _loadInvestmentDistribution();

      // Previous period for trend comparison
      await _loadPreviousPeriod();

      AppLoggerService.debugTrace(
        className: 'ReportsController',
        method: 'loadSummary',
        feature: 'Reports',
        status: 'SUCCESS',
        params: {'transactionCount': rows.length},
      );
    } catch (e, stackTrace) {
      hasError.value = true;
      AppLoggerService.logError(
        controller: 'ReportsController',
        method: 'loadSummary',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل تحميل التقارير');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadInvestmentDistribution() async {
    try {
      final res = await SupabaseService.client
          .from('user_investments')
          .select('investment_plans(name), amount')
          .eq('status', 'active');

      final distMap = <String, double>{};
      for (final row in res as List) {
        final plan = row['investment_plans'] as Map?;
        final name = (plan?['name'] as String?) ?? 'غير محدد';
        final amount = (row['amount'] as num? ?? 0).toDouble();
        distMap[name] = (distMap[name] ?? 0) + amount;
      }

      investmentDistribution.assignAll(
        distMap.entries.map((e) => {'name': e.key, 'amount': e.value}),
      );
    } catch (_) {
      investmentDistribution.clear();
    }
  }

  Future<void> _loadPreviousPeriod() async {
    try {
      final days = _rangeDays;
      final prevStart = _rangeStart.subtract(Duration(days: days));
      final prevEnd = _rangeStart;

      final response = await SupabaseService.client
          .from('transactions')
          .select('type, amount, status')
          .gte('created_at', prevStart.toUtc().toIso8601String())
          .lt('created_at', prevEnd.toUtc().toIso8601String())
          .limit(5000);

      double pDep = 0, pWit = 0, pProf = 0;
      for (final row in response as List) {
        final type = (row['type'] as String? ?? '').toLowerCase();
        final status = (row['status'] as String? ?? '').toLowerCase();
        if (!['completed', 'approved'].contains(status)) continue;
        final amount = (row['amount'] as num? ?? 0).toDouble();
        switch (type) {
          case 'deposit':
            pDep += amount;
          case 'withdrawal':
            pWit += amount;
          case 'profit':
            pProf += amount;
          default:
            break;
        }
      }
      prevDeposits.value = pDep;
      prevWithdrawals.value = pWit;
      prevProfits.value = pProf;
      prevNetFlow.value = pDep - pWit;
    } catch (_) {
      prevDeposits.value = 0;
      prevWithdrawals.value = 0;
      prevProfits.value = 0;
      prevNetFlow.value = 0;
    }
  }

  double trendPercent(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }
}

// ═══════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════

class RevenueDashboardScreen extends StatelessWidget {
  const RevenueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportsController());
    final fmt = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإيرادات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadSummary,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.summary.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: KasbyColors.primaryGold),
          );
        }

        if (controller.hasError.value && controller.summary.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: KasbyColors.error, size: 48),
                const SizedBox(height: 12),
                const Text('تعذّر تحميل التقارير'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.loadSummary,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final s = controller.summary;
        return RefreshIndicator(
          onRefresh: controller.loadSummary,
          color: KasbyColors.primaryGold,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Date range selector
              _buildDateRangeSelector(context, controller),
              const SizedBox(height: 16),

              // Summary cards with trend indicators
              _buildTrendCard(
                'إجمالي الإيداع',
                fmt.format(s['total_deposits'] ?? 0),
                KasbyColors.success,
                FontAwesomeIcons.arrowDown,
                controller.trendPercent(
                  (s['total_deposits'] ?? 0).toDouble(),
                  controller.prevDeposits.value,
                ),
              ),
              const SizedBox(height: 10),
              _buildTrendCard(
                'إجمالي السحب',
                fmt.format(s['total_withdrawals'] ?? 0),
                KasbyColors.error,
                FontAwesomeIcons.arrowUp,
                controller.trendPercent(
                  (s['total_withdrawals'] ?? 0).toDouble(),
                  controller.prevWithdrawals.value,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  AdminMetricChip(
                    label: 'صافي التدفق',
                    value: fmt.format(s['net_flow'] ?? 0),
                    color: KasbyColors.info,
                    icon: FontAwesomeIcons.scaleBalanced,
                  ),
                  const SizedBox(width: 10),
                  AdminMetricChip(
                    label: 'الأرباح',
                    value: fmt.format(s['total_profits'] ?? 0),
                    color: KasbyColors.primaryGold,
                    icon: FontAwesomeIcons.chartLine,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Revenue trend line chart
              _buildChartTitle('اتجاه الإيرادات'),
              const SizedBox(height: 12),
              _buildRevenueLineChart(controller),
              const SizedBox(height: 24),

              // Transaction volume bar chart
              _buildChartTitle('حجم المعاملات (إيداع vs سحب)'),
              const SizedBox(height: 12),
              _buildVolumeBarChart(controller),
              const SizedBox(height: 24),

              // Investment distribution pie chart
              if (controller.investmentDistribution.isNotEmpty) ...[
                _buildChartTitle('توزيع الاستثمارات'),
                const SizedBox(height: 12),
                _buildInvestmentPieChart(controller),
                const SizedBox(height: 24),
              ],

              // Additional info
              KasbyGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عدد المعاملات المحللة: ${s['transaction_count'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'رصيد إداري مضاف: ${fmt.format(s['admin_credits'] ?? 0)}',
                      style: const TextStyle(color: KasbyColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context, ReportsController controller) {
    final ranges = {
      'last_7': '7 أيام',
      'last_30': '30 يوم',
      'last_90': '90 يوم',
      'custom': 'مخصص',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() => Row(
            children: ranges.entries.map((entry) {
              final isSelected = controller.selectedRange.value == entry.key;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  selectedColor: KasbyColors.primaryGold.withValues(alpha: 0.2),
                  backgroundColor: KasbyColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? KasbyColors.primaryGold : KasbyColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? KasbyColors.primaryGold.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                  onSelected: (_) {
                    if (entry.key == 'custom') {
                      controller.pickCustomRange(context);
                    } else {
                      controller.changeRange(entry.key);
                    }
                  },
                ),
              );
            }).toList(),
          )),
    );
  }

  Widget _buildTrendCard(
    String label,
    String value,
    Color color,
    IconData icon,
    double trendPercent,
  ) {
    final isUp = trendPercent >= 0;
    final trendColor = isUp ? KasbyColors.success : KasbyColors.error;
    final trendIcon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: KasbyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: 4),
                Text(
                  '${trendPercent.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRevenueLineChart(ReportsController controller) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.06,
      child: SizedBox(
        height: 200,
        child: Obx(() {
          final data = controller.dailyRevenue;
          if (data.isEmpty) {
            return const Center(
              child: Text('لا توجد بيانات', style: TextStyle(color: KasbyColors.textSecondary)),
            );
          }

          final spots = List.generate(
            data.length,
            (i) => FlSpot(i.toDouble(), (data[i]['revenue'] as double?) ?? 0),
          );

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
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) => Text(
                      '\$${NumberFormat.compact().format(value)}',
                      style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: KasbyColors.primaryGold,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
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
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVolumeBarChart(ReportsController controller) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.06,
      child: SizedBox(
        height: 200,
        child: Obx(() {
          final data = controller.dailyVolume;
          if (data.isEmpty) {
            return const Center(
              child: Text('لا توجد بيانات', style: TextStyle(color: KasbyColors.textSecondary)),
            );
          }

          final barGroups = List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (data[i]['deposits'] as double?) ?? 0,
                  color: KasbyColors.success,
                  width: data.length > 30 ? 3 : 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
                BarChartRodData(
                  toY: (data[i]['withdrawals'] as double?) ?? 0,
                  color: KasbyColors.error,
                  width: data.length > 30 ? 3 : 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            );
          });

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _legendDot(KasbyColors.success, 'إيداع'),
                  const SizedBox(width: 12),
                  _legendDot(KasbyColors.error, 'سحب'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withValues(alpha: 0.03),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) => Text(
                            '\$${NumberFormat.compact().format(value)}',
                            style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInvestmentPieChart(ReportsController controller) {
    final pieColors = [
      KasbyColors.primaryGold,
      KasbyColors.info,
      KasbyColors.success,
      KasbyColors.glowOrange,
      KasbyColors.error,
      KasbyColors.glowBlue,
      Colors.purpleAccent,
      Colors.cyanAccent,
    ];

    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.06,
      child: SizedBox(
        height: 220,
        child: Obx(() {
          final data = controller.investmentDistribution;
          if (data.isEmpty) {
            return const Center(
              child: Text('لا توجد بيانات', style: TextStyle(color: KasbyColors.textSecondary)),
            );
          }

          final total = data.fold<double>(
            0,
            (sum, e) => sum + ((e['amount'] as double?) ?? 0),
          );

          final sections = List.generate(data.length, (i) {
            final amount = (data[i]['amount'] as double?) ?? 0;
            final pct = total > 0 ? (amount / total * 100) : 0.0;
            return PieChartSectionData(
              value: amount,
              color: pieColors[i % pieColors.length],
              radius: 50,
              title: '${pct.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          });

          return Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(data.length.clamp(0, 6), (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: pieColors[i % pieColors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data[i]['name'] as String? ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}
