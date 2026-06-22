import 'package:get/get.dart';
import '../repositories/ksp_analytics_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

class KspAnalyticsController extends GetxController {
  final KspAnalyticsRepository _repository = KspAnalyticsRepository(SupabaseService.client);

  final isLoading = false.obs;

  final totalSupply = 0.obs;
  final totalDistributed = 0.obs;
  final dailyKspGenerated = 0.obs;
  final dailyKspRewards = 0.obs;
  final topEarnerName = 'N/A'.obs;
  final topEarnerAmount = 0.obs;

  final topHolders = <Map<String, dynamic>>[].obs;
  final topEarners = <Map<String, dynamic>>[].obs;
  final topTransfers = <Map<String, dynamic>>[].obs;

  // Chart data
  final supplyTrend = <Map<String, dynamic>>[].obs;
  final dailyGenerationHistory = <Map<String, dynamic>>[].obs;
  final distributionData = <Map<String, dynamic>>[].obs;

  static KspAnalyticsController get to => Get.find();

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'KspAnalyticsController',
      method: 'onInit',
      feature: 'KspAnalytics',
      status: 'INFO',
    );
    super.onInit();
    loadAllData();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'KspAnalyticsController',
      method: 'onClose',
      feature: 'KspAnalytics',
      status: 'INFO',
    );
    super.onClose();
  }

  Future<void> loadAllData() async {
    AppLoggerService.debugTrace(
      className: 'KspAnalyticsController',
      method: 'loadAllData',
      feature: 'KspAnalytics',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final metrics = await _repository.getKspOverviewMetrics();
      totalSupply.value = metrics['totalSupply'] ?? 0;
      totalDistributed.value = metrics['totalDistributed'] ?? 0;
      dailyKspGenerated.value = metrics['dailyKspGenerated'] ?? 0;
      dailyKspRewards.value = metrics['dailyKspRewards'] ?? 0;
      topEarnerName.value = metrics['topEarnerName'] ?? 'N/A';
      topEarnerAmount.value = metrics['topEarnerAmount'] ?? 0;

      topHolders.assignAll(await _repository.getTopHolders());
      topEarners.assignAll(await _repository.getTopEarners());
      topTransfers.assignAll(await _repository.getTopTransfers());

      await Future.wait([
        _loadSupplyTrend(),
        _loadDailyGenerationHistory(),
        _loadDistributionData(),
      ]);

      AppLoggerService.debugTrace(
        className: 'KspAnalyticsController',
        method: 'loadAllData',
        feature: 'KspAnalytics',
        status: 'SUCCESS',
      );
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'KspAnalyticsController',
        method: 'loadAllData',
        feature: 'KspAnalytics',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSupplyTrend() async {
    try {
      final now = DateTime.now().toUtc();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final res = await SupabaseService.client
          .from('point_history')
          .select('points, type, created_at')
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .order('created_at', ascending: true);

      final dayMap = <String, int>{};
      for (final row in res as List) {
        final dateKey = (row['created_at'] as String).substring(0, 10);
        final pts = row['points'] as int? ?? 0;
        final type = row['type'] as String? ?? '';
        final delta = (type == 'spend' || type == 'transfer_out') ? -pts : pts;
        dayMap[dateKey] = (dayMap[dateKey] ?? 0) + delta;
      }

      final sortedDays = dayMap.keys.toList()..sort();
      final accumulated = <Map<String, dynamic>>[];
      int cumulativeDelta = 0;
      for (final day in sortedDays) {
        cumulativeDelta += dayMap[day] ?? 0;
        accumulated.add({'date': day, 'supply': cumulativeDelta});
      }

      supplyTrend.assignAll(accumulated);
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'KspAnalyticsController',
        method: '_loadSupplyTrend',
        feature: 'KspAnalytics',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      supplyTrend.clear();
    }
  }

  Future<void> _loadDailyGenerationHistory() async {
    try {
      final now = DateTime.now().toUtc();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final res = await SupabaseService.client
          .from('point_history')
          .select('points, type, created_at')
          .inFilter('type', ['earn', 'transfer_in'])
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .order('created_at', ascending: true);

      final dayMap = <String, int>{};
      for (final row in res as List) {
        final dateKey = (row['created_at'] as String).substring(0, 10);
        final pts = row['points'] as int? ?? 0;
        dayMap[dateKey] = (dayMap[dateKey] ?? 0) + pts;
      }

      final sortedDays = dayMap.keys.toList()..sort();
      dailyGenerationHistory.assignAll(
        sortedDays.map((d) => {'date': d, 'generated': dayMap[d] ?? 0}),
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'KspAnalyticsController',
        method: '_loadDailyGenerationHistory',
        feature: 'KspAnalytics',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      dailyGenerationHistory.clear();
    }
  }

  Future<void> _loadDistributionData() async {
    try {
      // Top 5 holders vs rest
      final holders = topHolders.take(5).toList();
      final topTotal = holders.fold<int>(
        0,
        (sum, h) => sum + ((h['balance'] as int?) ?? 0),
      );
      final rest = totalSupply.value - topTotal;

      final dist = <Map<String, dynamic>>[];
      for (final h in holders) {
        dist.add({
          'name': h['name'] ?? 'N/A',
          'balance': h['balance'] ?? 0,
        });
      }
      if (rest > 0) {
        dist.add({'name': 'آخرون', 'balance': rest});
      }

      distributionData.assignAll(dist);
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'KspAnalyticsController',
        method: '_loadDistributionData',
        feature: 'KspAnalytics',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      distributionData.clear();
    }
  }
}
