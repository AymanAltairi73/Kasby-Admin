import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/system_health_controller.dart';

class SystemHealthScreen extends StatelessWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SystemHealthController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('صحة النظام'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadAll,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.supabaseStatus.value == 'checking') {
          return const Center(
            child: CircularProgressIndicator(color: KasbyColors.primaryGold),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          color: KasbyColors.primaryGold,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildAutoRefreshBadge(),
              const SizedBox(height: 16),

              // Service status indicators
              _buildSectionTitle('حالة الخدمات'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildServiceCard(
                      'Supabase',
                      FontAwesomeIcons.database,
                      controller.supabaseStatus.value,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildServiceCard(
                      'FCM',
                      FontAwesomeIcons.bell,
                      controller.fcmStatus.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildApiResponseCard(controller.apiResponseTimeMs.value),
              const SizedBox(height: 24),

              // Active users
              _buildSectionTitle('المستخدمون النشطون'),
              const SizedBox(height: 12),
              _buildActiveUsersCard(controller.activeUsersCount.value),
              const SizedBox(height: 24),

              // Pending operations
              _buildSectionTitle('العمليات المعلقة'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPendingChip(
                    'إيداعات',
                    controller.pendingDeposits.value,
                    KasbyColors.success,
                    FontAwesomeIcons.arrowDown,
                  ),
                  const SizedBox(width: 10),
                  _buildPendingChip(
                    'سحوبات',
                    controller.pendingWithdrawals.value,
                    KasbyColors.error,
                    FontAwesomeIcons.arrowUp,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildPendingChip(
                    'توثيق هوية',
                    controller.pendingKyc.value,
                    KasbyColors.info,
                    FontAwesomeIcons.idCard,
                  ),
                  const SizedBox(width: 10),
                  _buildPendingChip(
                    'إجمالي معلق',
                    controller.totalPendingOps,
                    KasbyColors.warning,
                    FontAwesomeIcons.clockRotateLeft,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent errors
              _buildSectionTitle('آخر الأخطاء'),
              const SizedBox(height: 12),
              if (controller.recentErrors.isEmpty)
                KasbyGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: KasbyColors.success.withValues(alpha: 0.6),
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'لا توجد أخطاء حديثة',
                          style: TextStyle(color: KasbyColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...controller.recentErrors.map(_buildErrorCard),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAutoRefreshBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: KasbyColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KasbyColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          const Text(
            'تحديث تلقائي كل 30 ثانية',
            style: TextStyle(
              fontSize: 11,
              color: KasbyColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildServiceCard(String name, IconData icon, String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'online':
        statusColor = KasbyColors.success;
        statusText = 'متصل';
        statusIcon = Icons.check_circle_rounded;
      case 'offline':
        statusColor = KasbyColors.error;
        statusText = 'غير متصل';
        statusIcon = Icons.cancel_rounded;
      default:
        statusColor = KasbyColors.warning;
        statusText = 'جارِ الفحص...';
        statusIcon = Icons.pending_rounded;
    }

    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: statusColor),
              Icon(statusIcon, size: 16, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiResponseCard(int ms) {
    final Color color;
    if (ms < 500) {
      color = KasbyColors.success;
    } else if (ms < 1500) {
      color = KasbyColors.warning;
    } else {
      color = KasbyColors.error;
    }

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
            child: Icon(FontAwesomeIcons.gauge, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'زمن الاستجابة (API)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${ms}ms',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersCard(int count) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KasbyColors.glowGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FontAwesomeIcons.userCheck,
              size: 18,
              color: KasbyColors.glowGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مستخدمون متصلون الآن',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: KasbyColors.glowGreen,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: count > 0 ? KasbyColors.success : KasbyColors.textSecondary,
              shape: BoxShape.circle,
              boxShadow: count > 0
                  ? [
                      BoxShadow(
                        color: KasbyColors.success.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingChip(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: KasbyColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(Map<String, dynamic> error) {
    final createdAt = error['created_at'] as String?;
    String timeStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        timeStr = DateFormat('MM/dd HH:mm').format(dt);
      } catch (_) {
        timeStr = createdAt;
      }
    }

    final message = error['message'] as String? ?? 'خطأ غير معروف';
    final context = error['context'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KasbyGlassCard(
        padding: const EdgeInsets.all(14),
        color: KasbyColors.error.withValues(alpha: 0.06),
        borderColor: KasbyColors.error.withValues(alpha: 0.15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: KasbyColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: KasbyColors.error,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (context != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
