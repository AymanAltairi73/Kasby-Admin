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
    isLoading.value = true;
    try {
      final data = await _dashboardRepo.getDashboardStats();
      stats.value = data;
      
      // Override initial active_users with current real-time count
      stats['active_users'] = _presenceService.onlineCount;
      stats.refresh();

      // Fetch urgent alerts separately
      await _fetchUrgentAlerts();
    } catch (e) {
      // Handle silently
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
    try {
      // 1. Pending Withdrawals
      final withdrawalRes = await SupabaseService.client
          .from('transactions')
          .count(CountOption.exact)
          .eq('type', 'withdrawal')
          .eq('status', 'pending');
      pendingWithdrawalsCount.value = withdrawalRes;

      // 2. Pending KYC
      final kycRes = await SupabaseService.client
          .from('profiles')
          .count(CountOption.exact)
          .eq('kyc_status', 'pending');
      pendingKYCCount.value = kycRes;
      
    } catch (e) {
      // Handle silently
    }
  }
}
