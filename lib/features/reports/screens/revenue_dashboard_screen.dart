import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/admin_metric_chip.dart';

class ReportsController extends GetxController {
  final isLoading = false.obs;
  final hasError = false.obs;
  final summary = <String, dynamic>{}.obs;

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
      final response = await SupabaseService.client
          .from('transactions')
          .select(
            'id, type, amount, status, created_at, profiles!transactions_user_id_fkey(full_name)',
          )
          .order('created_at', ascending: false)
          .limit(1000);

      final rows = (response as List).map((e) {
        final profile = e['profiles'] as Map? ?? {};
        return {
          'id': e['id'],
          'type': e['type'],
          'amount': (e['amount'] as num? ?? 0).toDouble(),
          'status': e['status'],
          'created_at': e['created_at'],
          'user_name': profile['full_name'] ?? '',
        };
      }).toList();

      double deposits = 0;
      double withdrawals = 0;
      double profits = 0;
      double adminCredits = 0;

      for (final row in rows) {
        final type = (row['type'] as String? ?? '').toLowerCase();
        final status = (row['status'] as String? ?? '').toLowerCase();
        if (!['completed', 'approved'].contains(status)) continue;
        final amount = row['amount'] as double;
        switch (type) {
          case 'deposit':
            deposits += amount;
          case 'withdrawal':
            withdrawals += amount;
          case 'profit':
            profits += amount;
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
}

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
              Row(
                children: [
                  AdminMetricChip(
                    label: 'إجمالي الإيداع',
                    value: fmt.format(s['total_deposits'] ?? 0),
                    color: KasbyColors.success,
                    icon: FontAwesomeIcons.arrowDown,
                  ),
                  const SizedBox(width: 10),
                  AdminMetricChip(
                    label: 'إجمالي السحب',
                    value: fmt.format(s['total_withdrawals'] ?? 0),
                    color: KasbyColors.error,
                    icon: FontAwesomeIcons.arrowUp,
                  ),
                ],
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
              const SizedBox(height: 20),
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
            ],
          ),
        );
      }),
    );
  }
}
