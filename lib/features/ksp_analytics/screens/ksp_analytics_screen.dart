import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/ksp_analytics_controller.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';

class KspAnalyticsScreen extends StatelessWidget {
  const KspAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(KspAnalyticsController());
    final formatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تحليلات KSP Coin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => controller.loadAllData(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: RefreshIndicator(
        onRefresh: () => controller.loadAllData(),
        color: KasbyColors.primaryGold,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: KasbyColors.primaryGold),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Core metrics grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _buildMetricCard(
                      'إجمالي المعروض (Supply)',
                      formatter.format(controller.totalSupply.value),
                      'assets/images/ksp_coin.png',
                      KasbyColors.primaryGold,
                    ),
                    _buildMetricCard(
                      'إجمالي الموزع (Distributed)',
                      formatter.format(controller.totalDistributed.value),
                      'assets/images/ksp_coin.png',
                      Colors.cyanAccent,
                    ),
                    _buildMetricCard(
                      'التوليد اليومي (Daily Gen)',
                      '+${formatter.format(controller.dailyKspGenerated.value)}',
                      null,
                      KasbyColors.success,
                      iconData: FontAwesomeIcons.chartLine,
                    ),
                    _buildMetricCard(
                      'المكافآت اليومية (Rewards)',
                      '+${formatter.format(controller.dailyKspRewards.value)}',
                      null,
                      KasbyColors.glowOrange,
                      iconData: FontAwesomeIcons.gift,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Top Earner Box
                _buildTopEarnerCard(
                  controller.topEarnerName.value,
                  formatter.format(controller.topEarnerAmount.value),
                ),
                const SizedBox(height: 24),

                // ═══════════════════════════════════════
                // Charts Section
                // ═══════════════════════════════════════
                const Text(
                  'الرسوم البيانية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // KSP Supply Trend Line Chart
                _buildSupplyTrendChart(controller, formatter),
                const SizedBox(height: 16),

                // Distribution Pie Chart
                _buildDistributionPieChart(controller, formatter),
                const SizedBox(height: 16),

                // Daily Generation Bar Chart
                _buildDailyGenerationChart(controller, formatter),
                const SizedBox(height: 24),

                // Tables Section
                const Text(
                  'لوحات الصدارة وقوائم المعاملات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 480,
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(
                          indicatorColor: KasbyColors.primaryGold,
                          labelColor: KasbyColors.primaryGold,
                          unselectedLabelColor: Colors.white60,
                          tabs: [
                            Tab(text: 'كبار الملاك'),
                            Tab(text: 'الأكثر كسباً'),
                            Tab(text: 'التحويلات الكبرى'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildHoldersList(controller.topHolders, formatter),
                              _buildEarnersList(controller.topEarners, formatter),
                              _buildTransfersList(controller.topTransfers, formatter),
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
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CHARTS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSupplyTrendChart(KspAnalyticsController controller, NumberFormat formatter) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'اتجاه المعروض (30 يوم)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'KSP',
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
          SizedBox(
            height: 180,
            child: Obx(() {
              final data = controller.supplyTrend;
              if (data.isEmpty) {
                return const Center(
                  child: Text('لا توجد بيانات', style: TextStyle(color: Colors.white38)),
                );
              }

              final spots = List.generate(
                data.length,
                (i) => FlSpot(i.toDouble(), (data[i]['supply'] as int? ?? 0).toDouble()),
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
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) => Text(
                          NumberFormat.compact().format(value),
                          style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
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
        ],
      ),
    );
  }

  Widget _buildDistributionPieChart(KspAnalyticsController controller, NumberFormat formatter) {
    final pieColors = [
      KasbyColors.primaryGold,
      Colors.cyanAccent,
      KasbyColors.success,
      KasbyColors.glowOrange,
      KasbyColors.info,
      Colors.white38,
    ];

    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزيع KSP (كبار الملاك vs الآخرون)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Obx(() {
              final data = controller.distributionData;
              if (data.isEmpty) {
                return const Center(
                  child: Text('لا توجد بيانات', style: TextStyle(color: Colors.white38)),
                );
              }

              final total = data.fold<int>(
                0,
                (sum, e) => sum + ((e['balance'] as int?) ?? 0),
              );

              final sections = List.generate(data.length, (i) {
                final balance = (data[i]['balance'] as int?) ?? 0;
                final pct = total > 0 ? (balance / total * 100) : 0.0;
                return PieChartSectionData(
                  value: balance.toDouble(),
                  color: pieColors[i % pieColors.length],
                  radius: 45,
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
                        centerSpaceRadius: 25,
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
                                  '${data[i]['name']} (${formatter.format(data[i]['balance'])})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: Colors.white70),
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
        ],
      ),
    );
  }

  Widget _buildDailyGenerationChart(KspAnalyticsController controller, NumberFormat formatter) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التوليد اليومي (30 يوم)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Obx(() {
              final data = controller.dailyGenerationHistory;
              if (data.isEmpty) {
                return const Center(
                  child: Text('لا توجد بيانات', style: TextStyle(color: Colors.white38)),
                );
              }

              final barGroups = List.generate(data.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (data[i]['generated'] as int? ?? 0).toDouble(),
                      color: KasbyColors.success,
                      width: data.length > 20 ? 4 : 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ],
                );
              });

              return BarChart(
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
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          NumberFormat.compact().format(value),
                          style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  EXISTING WIDGETS (preserved)
  // ═══════════════════════════════════════════════════════════

  Widget _buildMetricCard(
    String title,
    String value,
    String? assetPath,
    Color color, {
    IconData? iconData,
  }) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              assetPath != null
                  ? Image.asset(assetPath, width: 18, height: 18)
                  : Icon(iconData, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTopEarnerCard(String name, String amount) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(18),
      opacity: 0.08,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KasbyColors.primaryGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FontAwesomeIcons.trophy,
              color: KasbyColors.primaryGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الأكثر تحقيقاً للأرباح KSP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$amount KSP',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: KasbyColors.primaryGold,
                ),
              ),
              const Text(
                'إجمالي الأرباح الكلية',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoldersList(List<Map<String, dynamic>> list, NumberFormat formatter) {
    if (list.isEmpty) return _buildEmptyState();

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final item = list[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: KasbyColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            item['name'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            item['email'],
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${formatter.format(item['balance'])} KSP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'كسب: ${formatter.format(item['totalEarned'])}',
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarnersList(List<Map<String, dynamic>> list, NumberFormat formatter) {
    if (list.isEmpty) return _buildEmptyState();

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final item = list[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            item['name'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            item['email'],
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${formatter.format(item['totalEarned'])} KSP',
                style: const TextStyle(
                  color: KasbyColors.primaryGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'الرصيد: ${formatter.format(item['balance'])}',
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransfersList(List<Map<String, dynamic>> list, NumberFormat formatter) {
    if (list.isEmpty) return _buildEmptyState();

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final item = list[index];
        final isTransferIn = item['type'] == 'transfer_in';
        final date = item['createdAt'] as DateTime;
        final dateStr = '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: (isTransferIn ? KasbyColors.success : KasbyColors.error).withValues(alpha: 0.1),
            child: Icon(
              isTransferIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isTransferIn ? KasbyColors.success : KasbyColors.error,
              size: 18,
            ),
          ),
          title: Text(
            item['name'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${item['description'] ?? ''} • $dateStr',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${formatter.format(item['amount'])} KSP',
            style: TextStyle(
              color: isTransferIn ? KasbyColors.success : KasbyColors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'لا توجد بيانات متاحة بعد',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
