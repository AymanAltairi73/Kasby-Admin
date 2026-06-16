import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
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
                          label: 'مُحيلون نشطون',
                          value: '${controller.activeReferrers}',
                          color: KasbyColors.info,
                          icon: FontAwesomeIcons.users,
                        ),
                        const SizedBox(width: 10),
                        AdminMetricChip(
                          label: 'أكواد',
                          value: '${controller.entries.length}',
                          color: KasbyColors.warning,
                          icon: FontAwesomeIcons.qrcode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (list.isEmpty)
                      const KasbyGlassCard(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('لا توجد بيانات مطابقة')),
                        ),
                      )
                    else
                      ...list.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: KasbyGlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      KasbyColors.primaryGold.withValues(alpha: 0.15),
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
                      }),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
