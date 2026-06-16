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
}
