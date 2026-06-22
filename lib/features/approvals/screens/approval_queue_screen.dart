import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/approval_queue_controller.dart';

class ApprovalQueueScreen extends StatefulWidget {
  const ApprovalQueueScreen({super.key});

  @override
  State<ApprovalQueueScreen> createState() => _ApprovalQueueScreenState();
}

class _ApprovalQueueScreenState extends State<ApprovalQueueScreen> {
  final controller = Get.put(ApprovalQueueController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'طابور الموافقات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(theme, onSurface),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.items.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: KasbyColors.primaryGold),
                );
              }
              if (controller.filteredItems.isEmpty) {
                return _buildEmptyState(onSurface);
              }
              return RefreshIndicator(
                color: KasbyColors.primaryGold,
                onRefresh: controller.loadAllPending,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: controller.filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = controller.filteredItems[index];
                    return _buildApprovalCard(item, theme, onSurface);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, Color onSurface) {
    final categories = [
      (ApprovalCategory.all, 'الكل', FontAwesomeIcons.layerGroup),
      (ApprovalCategory.deposits, 'إيداعات', FontAwesomeIcons.arrowDown),
      (ApprovalCategory.withdrawals, 'سحوبات', FontAwesomeIcons.arrowUp),
      (ApprovalCategory.kyc, 'توثيق', FontAwesomeIcons.idCard),
      (ApprovalCategory.loans, 'سلفات', FontAwesomeIcons.handHoldingDollar),
      (ApprovalCategory.agents, 'وكلاء', FontAwesomeIcons.networkWired),
    ];

    return SizedBox(
      height: 48,
      child: Obx(() => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (cat, label, icon) = categories[index];
              final selected = controller.selectedCategory.value == cat;
              final count = controller.categoryCounts[cat] ?? 0;

              return GestureDetector(
                onTap: () => controller.setCategory(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? KasbyColors.primaryGold.withValues(alpha: 0.15)
                        : onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? KasbyColors.primaryGold.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 12,
                          color: selected
                              ? KasbyColors.primaryGold
                              : onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          color: selected
                              ? KasbyColors.primaryGold
                              : onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: selected
                                ? KasbyColors.primaryGold.withValues(alpha: 0.2)
                                : onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? KasbyColors.primaryGold
                                  : onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          )),
    );
  }

  Widget _buildEmptyState(Color onSurface) {
    final cat = controller.selectedCategory.value;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: KasbyColors.success.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات معلقة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cat == ApprovalCategory.all
                ? 'كل الطلبات تمت معالجتها'
                : 'لا توجد طلبات ${_categoryLabel(cat)} معلقة',
            style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(ApprovalItem item, ThemeData theme, Color onSurface) {
    final color = _categoryColor(item.category);
    final dateStr = DateFormat('yyyy/MM/dd — HH:mm', 'ar').format(item.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KasbyGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon(item.category), size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.userName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _categoryLabel(item.category),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.detail,
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                if (item.amount != null) ...[
                  Text(
                    '\$${NumberFormat('#,##0.00').format(item.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.access_time_rounded, size: 12, color: onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                _buildActionButton(
                  label: 'رفض',
                  color: KasbyColors.error,
                  icon: Icons.close_rounded,
                  onTap: () => _showRejectDialog(item),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: 'موافقة',
                  color: KasbyColors.success,
                  icon: Icons.check_rounded,
                  filled: true,
                  onTap: () => controller.approveItem(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    bool filled = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(ApprovalItem item) {
    final reasonController = TextEditingController();
    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KasbyColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: KasbyColors.error, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'رفض الطلب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'سبب الرفض (اختياري)',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KasbyColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Get.back();
                          controller.rejectItem(item, reasonController.text);
                        },
                        child: const Text('تأكيد الرفض'),
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

  IconData _categoryIcon(ApprovalCategory cat) {
    switch (cat) {
      case ApprovalCategory.deposits:
        return FontAwesomeIcons.arrowDown;
      case ApprovalCategory.withdrawals:
        return FontAwesomeIcons.arrowUp;
      case ApprovalCategory.kyc:
        return FontAwesomeIcons.idCard;
      case ApprovalCategory.loans:
        return FontAwesomeIcons.handHoldingDollar;
      case ApprovalCategory.agents:
        return FontAwesomeIcons.networkWired;
      case ApprovalCategory.all:
        return FontAwesomeIcons.layerGroup;
    }
  }

  String _categoryLabel(ApprovalCategory cat) {
    switch (cat) {
      case ApprovalCategory.deposits:
        return 'إيداع';
      case ApprovalCategory.withdrawals:
        return 'سحب';
      case ApprovalCategory.kyc:
        return 'توثيق';
      case ApprovalCategory.loans:
        return 'سلفة';
      case ApprovalCategory.agents:
        return 'وكيل';
      case ApprovalCategory.all:
        return 'الكل';
    }
  }

  Color _categoryColor(ApprovalCategory cat) {
    switch (cat) {
      case ApprovalCategory.deposits:
        return KasbyColors.success;
      case ApprovalCategory.withdrawals:
        return KasbyColors.error;
      case ApprovalCategory.kyc:
        return KasbyColors.info;
      case ApprovalCategory.loans:
        return KasbyColors.glowOrange;
      case ApprovalCategory.agents:
        return KasbyColors.primaryGold;
      case ApprovalCategory.all:
        return KasbyColors.primaryGold;
    }
  }
}
