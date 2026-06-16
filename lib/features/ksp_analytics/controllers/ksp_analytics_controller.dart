import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/ksp_analytics_repository.dart';
import '../../../core/services/supabase_service.dart';

class KspAnalyticsController extends GetxController {
  final KspAnalyticsRepository _repository = KspAnalyticsRepository(SupabaseService.client);

  final isLoading = false.obs;

  // Metrics
  final totalSupply = 0.obs;
  final totalDistributed = 0.obs;
  final dailyKspGenerated = 0.obs;
  final dailyKspRewards = 0.obs;
  final topEarnerName = 'N/A'.obs;
  final topEarnerAmount = 0.obs;

  // Tables
  final topHolders = <Map<String, dynamic>>[].obs;
  final topEarners = <Map<String, dynamic>>[].obs;
  final topTransfers = <Map<String, dynamic>>[].obs;

  static KspAnalyticsController get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    debugPrint('[KspAnalyticsController] Loading KSP analytics data...');
    isLoading.value = true;
    try {
      final metrics = await _repository.getKspOverviewMetrics();
      totalSupply.value = metrics['totalSupply'] ?? 0;
      totalDistributed.value = metrics['totalDistributed'] ?? 0;
      dailyKspGenerated.value = metrics['dailyKspGenerated'] ?? 0;
      dailyKspRewards.value = metrics['dailyKspRewards'] ?? 0;
      topEarnerName.value = metrics['topEarnerName'] ?? 'N/A';
      topEarnerAmount.value = metrics['topEarnerAmount'] ?? 0;

      final holders = await _repository.getTopHolders();
      topHolders.assignAll(holders);

      final earners = await _repository.getTopEarners();
      topEarners.assignAll(earners);

      final transfers = await _repository.getTopTransfers();
      topTransfers.assignAll(transfers);
      
      debugPrint('[KspAnalyticsController] Data loaded successfully.');
    } catch (e, stackTrace) {
      debugPrint('[KspAnalyticsController] Error loading data: $e\n$stackTrace');
    } finally {
      isLoading.value = false;
    }
  }
}
