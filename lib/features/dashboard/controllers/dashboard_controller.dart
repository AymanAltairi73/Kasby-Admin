import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../repositories/dashboard_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/presence_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardController extends GetxController {
  final DashboardRepository _dashboardRepo = DashboardRepository(SupabaseService.client);

  final stats = <String, dynamic>{}.obs;
  final isLoading = false.obs;
  
  // Urgent alerts
  final pendingWithdrawalsCount = 0.obs;
  final pendingKYCCount = 0.obs;
  
  late PresenceService _presenceService;

  @override
  void onInit() {
    super.onInit();
    _presenceService = Get.find<PresenceService>();
    loadDashboardData();

    // Listen for presence changes to update "active users" real-time
    ever(_presenceService.onlineUsers, (_) {
      stats['active_users'] = _presenceService.onlineCount;
      stats.refresh();
    });
  }

  Future<void> loadDashboardData() async {
    debugPrint('[DashboardController][loadDashboardData] Fetching data from /dashboard');
    isLoading.value = true;
    try {
      final data = await _dashboardRepo.getDashboardStats();
      debugPrint('[DashboardController][loadDashboardData] Response: ${data.keys.toList()}');
      stats.value = data;
      
      // Override initial active_users with current real-time count
      stats['active_users'] = _presenceService.onlineCount;
      stats.refresh();

      // Fetch urgent alerts separately
      await _fetchUrgentAlerts();
      debugPrint('[DashboardController][loadDashboardData] Dashboard data loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('[DashboardController][loadDashboardData] Error: $e');
      debugPrint('[DashboardController][loadDashboardData] Stack trace: $stackTrace');
      debugPrint('[DashboardController][loadDashboardData] Endpoint: /dashboard');
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

  Future<void> _fetchUrgentAlerts() async {
    debugPrint('[DashboardController][_fetchUrgentAlerts] Fetching urgent alerts');
    try {
      // 1. Pending Withdrawals
      debugPrint('[DashboardController][_fetchUrgentAlerts] Checking pending withdrawals from /transactions');
      final withdrawalRes = await SupabaseService.client
          .from('transactions')
          .count(CountOption.exact)
          .eq('type', 'withdrawal')
          .eq('status', 'pending');
      pendingWithdrawalsCount.value = withdrawalRes;
      debugPrint('[DashboardController][_fetchUrgentAlerts] Pending withdrawals count: $withdrawalRes');

      // 2. Pending KYC
      debugPrint('[DashboardController][_fetchUrgentAlerts] Checking pending KYC from /profiles');
      final kycRes = await SupabaseService.client
          .from('profiles')
          .count(CountOption.exact)
          .eq('kyc_status', 'pending');
      pendingKYCCount.value = kycRes;
      debugPrint('[DashboardController][_fetchUrgentAlerts] Pending KYC count: $kycRes');
      debugPrint('[DashboardController][_fetchUrgentAlerts] Urgent alerts fetched successfully');
      
    } catch (e, stackTrace) {
      debugPrint('[DashboardController][_fetchUrgentAlerts] Error: $e');
      debugPrint('[DashboardController][_fetchUrgentAlerts] Stack trace: $stackTrace');
      debugPrint('[DashboardController][_fetchUrgentAlerts] Endpoint: /transactions, /profiles');
    }
  }
}
