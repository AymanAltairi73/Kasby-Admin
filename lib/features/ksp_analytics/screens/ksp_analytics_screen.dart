import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

                // DefaultTabController inside a Container
                SizedBox(
                  height: 480,
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          indicatorColor: KasbyColors.primaryGold,
                          labelColor: KasbyColors.primaryGold,
                          unselectedLabelColor: Colors.white60,
                          tabs: const [
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
