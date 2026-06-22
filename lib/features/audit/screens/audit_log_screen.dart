import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/kasby_colors.dart';
import '../controllers/audit_log_controller.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuditLogController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العمليات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearchSheet(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => controller.pickDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildShimmer();
              }
              if (controller.logs.isEmpty) {
                return _buildEmptyState();
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification &&
                      notification.metrics.extentAfter < 200) {
                    controller.loadMore();
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: controller.loadLogs,
                  color: KasbyColors.primaryGold,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: controller.logs.length +
                        (controller.hasMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.logs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: KasbyColors.primaryGold,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                      return _buildLogTile(controller.logs[index]);
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AuditLogController controller) {
    return Obx(() {
      final hasDateFilter = controller.dateFrom.value != null;
      final hasActionFilter = controller.selectedAction.value.isNotEmpty;
      final hasSearchFilter = controller.searchQuery.value.isNotEmpty;

      if (!hasDateFilter && !hasActionFilter && !hasSearchFilter) {
        return _buildActionTypeChips(controller);
      }

      return Column(
        children: [
          _buildActionTypeChips(controller),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                if (hasSearchFilter)
                  Chip(
                    label: Text('بحث: ${controller.searchQuery.value}'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      controller.searchQuery.value = '';
                      controller.searchController.clear();
                      controller.loadLogs();
                    },
                  ),
                if (hasDateFilter)
                  Chip(
                    label: Text(
                      '${DateFormat('M/d').format(controller.dateFrom.value!)} - '
                      '${DateFormat('M/d').format(controller.dateTo.value!)}',
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: controller.clearDateRange,
                  ),
                ActionChip(
                  label: const Text('مسح الكل'),
                  onPressed: controller.clearAllFilters,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildActionTypeChips(AuditLogController controller) {
    return SizedBox(
      height: 48,
      child: Obx(() => ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _filterChip(
            label: 'الكل',
            selected: controller.selectedAction.value.isEmpty,
            onTap: () => controller.clearActionFilter(),
          ),
          ...controller.actionTypes.map((type) => _filterChip(
            label: _actionLabel(type),
            selected: controller.selectedAction.value == type,
            onTap: () => controller.setActionFilter(type),
          )),
        ],
      )),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: KasbyColors.primaryGold.withValues(alpha: 0.2),
        checkmarkColor: KasbyColors.primaryGold,
      ),
    );
  }

  Widget _buildLogTile(AuditLogEntry entry) {
    final severity = entry.severity.toLowerCase();
    final color = _severityColor(severity);
    final timeStr = DateFormat('yyyy/MM/dd  HH:mm', 'ar').format(entry.createdAt.toLocal());
    final description = entry.details?['message'] as String? ??
        entry.details?['reason'] as String? ??
        '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_actionIcon(entry.action), size: 18, color: color),
        ),
        title: Text(
          _actionLabel(entry.action),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entry.actorName ?? entry.actorRole ?? 'نظام',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                severity,
                style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'لا توجد سجلات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض سجل النشاطات هنا',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder: (_, __) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchSheet(BuildContext context, AuditLogController controller) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'بحث في السجلات...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (val) {
                controller.applySearch(val);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KasbyColors.primaryGold,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  controller.applySearch(controller.searchController.text);
                  Navigator.pop(context);
                },
                child: const Text('بحث'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'error':
        return KasbyColors.error;
      case 'warning':
        return KasbyColors.warning;
      default:
        return KasbyColors.success;
    }
  }

  IconData _actionIcon(String action) {
    if (action.contains('delete')) return Icons.delete_outline_rounded;
    if (action.contains('block')) return Icons.block_rounded;
    if (action.contains('unblock')) return Icons.check_circle_outline_rounded;
    if (action.contains('login') || action.contains('auth')) return Icons.lock_outline_rounded;
    if (action.contains('financial') || action.contains('wallet') || action.contains('balance')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (action.contains('approve')) return Icons.thumb_up_alt_outlined;
    if (action.contains('reject')) return Icons.thumb_down_alt_outlined;
    if (action.contains('error')) return Icons.error_outline_rounded;
    if (action.contains('chat')) return Icons.chat_outlined;
    return Icons.history_rounded;
  }

  String _actionLabel(String action) {
    const labels = {
      'admin_block_user': 'حظر مستخدم',
      'admin_unblock_user': 'إلغاء حظر',
      'admin_delete_user': 'حذف مستخدم',
      'error': 'خطأ',
      'admin_approve_deposit': 'موافقة إيداع',
      'admin_reject_deposit': 'رفض إيداع',
      'admin_approve_withdrawal': 'موافقة سحب',
      'admin_reject_withdrawal': 'رفض سحب',
      'admin_approve_loan': 'موافقة قرض',
      'admin_reject_loan': 'رفض قرض',
    };
    return labels[action] ?? action;
  }
}
