import 'package:get/get.dart';
import '../repositories/dashboard_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

class DashboardController extends GetxController {
  final DashboardRepository _dashboardRepo = DashboardRepository(SupabaseService.client);

  final stats = <String, dynamic>{}.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      final data = await _dashboardRepo.getDashboardStats();
      stats.value = data;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'DashboardController',
        method: 'loadDashboardData',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper getters for UI
  int get totalUsers => stats['total_users'] ?? 0;
  int get activeUsers => stats['active_users'] ?? 0;
  double get totalInvested => (stats['total_invested'] ?? 0.0).toDouble();
  double get totalProfits => (stats['total_profits'] ?? 0.0).toDouble();
  int get pendingTransactions => stats['pending_transactions'] ?? 0;
  double get dailyVolume => (stats['daily_volume'] ?? 0.0).toDouble();
}
