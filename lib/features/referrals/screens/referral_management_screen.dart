import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/admin_metric_chip.dart';
import '../controllers/referral_controller.dart';

class ReferralManagementScreen extends StatelessWidget {
  const ReferralManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReferralController());
    final fmt = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الإحالات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadReferrals,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AdminSearchField(
              hint: 'بحث بالاسم أو كود الإحالة...',
              onChanged: controller.updateSearch,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.entries.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: KasbyColors.primaryGold),
                );
              }

              if (controller.hasError.value && controller.entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: KasbyColors.error, size: 48),
                      const SizedBox(height: 12),
                      const Text('تعذّر تحميل بيانات الإحالة'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: controller.loadReferrals,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              final list = controller.filteredEntries;

              return RefreshIndicator(
                onRefresh: controller.loadReferrals,
                color: KasbyColors.primaryGold,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary metrics
                    Row(
                      children: [
                        AdminMetricChip(
                          label: 'إحالات ناجحة',
                          value: '${controller.totalReferrals}',
                          color: KasbyColors.success,
                          icon: FontAwesomeIcons.userPlus,
                        ),
                        const SizedBox(width: 10),
                        AdminMetricChip(
                          label: 'عمولات',
                          value: fmt.format(controller.totalCommissions),
                          color: KasbyColors.primaryGold,
                          icon: FontAwesomeIcons.handHoldingDollar,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        AdminMetricChip(
                          label: 'معدل التحويل',
                          value: '${controller.conversionRate.value.toStringAsFixed(1)}%',
                          color: KasbyColors.glowBlue,
                          icon: FontAwesomeIcons.percent,
                        ),
                        const SizedBox(width: 10),
                        AdminMetricChip(
                          label: 'مُحيلون نشطون',
                          value: '${controller.activeReferrers}',
                          color: KasbyColors.info,
                          icon: FontAwesomeIcons.users,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Date range filter for analytics
                    _buildAnalyticsRangeSelector(controller),
                    const SizedBox(height: 16),

                    // Referral trend chart
                    _buildReferralTrendChart(controller),
                    const SizedBox(height: 24),

                    // Top referrers tabs
                    _buildTopReferrersSection(controller, fmt),
                    const SizedBox(height: 24),

                    // Referral list
                    const Text(
                      'جميع المُحيلين',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (list.isEmpty)
                      const KasbyGlassCard(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('لا توجد بيانات مطابقة')),
                        ),
                      )
                    else
                      ...list.map((item) => _buildReferralCard(item, fmt)),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRangeSelector(ReferralController controller) {
    final ranges = {
      'last_7': '7 أيام',
      'last_30': '30 يوم',
      'last_90': '90 يوم',
      'all': 'الكل',
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
                  onSelected: (_) => controller.changeAnalyticsRange(entry.key),
                ),
              );
            }).toList(),
          )),
    );
  }

  Widget _buildReferralTrendChart(ReferralController controller) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اتجاه الإحالات',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Obx(() {
              final data = controller.dailyReferrals;
              if (data.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد بيانات للفترة المحددة',
                    style: TextStyle(color: KasbyColors.textSecondary, fontSize: 12),
                  ),
                );
              }

              final barGroups = List.generate(data.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (data[i]['count'] as int? ?? 0).toDouble(),
                      color: KasbyColors.info,
                      width: data.length > 30 ? 3 : 8,
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
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
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

  Widget _buildTopReferrersSection(ReferralController controller, NumberFormat fmt) {
    return SizedBox(
      height: 300,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: KasbyColors.primaryGold,
              labelColor: KasbyColors.primaryGold,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: 'الأكثر إحالةً'),
                Tab(text: 'الأكثر كسباً'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() => TabBarView(
                    children: [
                      _buildTopList(controller.topReferrersByCount, fmt, byCount: true),
                      _buildTopList(controller.topReferrersByEarnings, fmt, byCount: false),
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopList(List<ReferralEntry> list, NumberFormat fmt, {required bool byCount}) {
    if (list.isEmpty) {
      return const Center(
        child: Text('لا يوجد محيلون نشطون', style: TextStyle(color: KasbyColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final item = list[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: KasbyColors.primaryGold.withValues(alpha: 0.12),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: KasbyColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            item.name.isNotEmpty ? item.name : 'مستخدم',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            item.referralCode,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          trailing: Text(
            byCount ? '${item.referralCount} إحالة' : fmt.format(item.totalCommissions),
            style: TextStyle(
              color: byCount ? KasbyColors.info : KasbyColors.primaryGold,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReferralCard(ReferralEntry item, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: KasbyGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: KasbyColors.primaryGold.withValues(alpha: 0.15),
              child: const Icon(
                FontAwesomeIcons.userGroup,
                color: KasbyColors.primaryGold,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.isNotEmpty ? item.name : 'مستخدم',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KasbyColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.referralCode,
                          style: const TextStyle(
                            fontSize: 11,
                            color: KasbyColors.info,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        color: KasbyColors.textSecondary,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: item.referralCode),
                          );
                          Get.snackbar('تم', 'تم نسخ كود الإحالة');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.referralCount} إحالة',
                  style: const TextStyle(
                    color: KasbyColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  fmt.format(item.totalCommissions),
                  style: const TextStyle(
                    fontSize: 11,
                    color: KasbyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
