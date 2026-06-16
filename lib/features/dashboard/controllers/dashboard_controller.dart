import 'dart:async';
import 'package:get/get.dart';
import '../repositories/dashboard_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardController extends GetxController {
  final DashboardRepository _dashboardRepo = DashboardRepository(SupabaseService.client);

  final stats = <String, dynamic>{}.obs;
  final weeklyChartData = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  final pendingWithdrawalsCount = 0.obs;
  final pendingKYCCount = 0.obs;

  late PresenceService _presenceService;
  Worker? _presenceWorker;
  Worker? _authWorker;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _kycSubscription;
  StreamSubscription? _profilesSubscription;
  Timer? _reloadDebounce;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'DashboardController',
      method: 'onInit',
      feature: 'Dashboard',
      status: 'INFO',
    );
    super.onInit();
    _presenceService = Get.find<PresenceService>();

    _presenceWorker = ever(_presenceService.onlineUsers, (_) {
      stats['active_users'] = _presenceService.onlineCount;
      stats.refresh();
    });

    try {
      final auth = Get.find<AuthController>();
      _authWorker = ever(auth.isLoggedIn, (loggedIn) {
        if (loggedIn) {
          loadDashboardData();
          _startRealtimeListeners();
        } else {
          _stopRealtimeListeners();
        }
      });
      if (auth.isLoggedIn.value) {
        loadDashboardData();
        _startRealtimeListeners();
      }
    } catch (_) {
      loadDashboardData();
      _startRealtimeListeners();
    }
  }

  void _startRealtimeListeners() {
    _stopRealtimeListeners();

    void scheduleReload() {
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 800), loadDashboardData);
    }

    _transactionsSubscription = SupabaseService.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});

    _kycSubscription = SupabaseService.client
        .from('kyc_documents')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});

    _profilesSubscription = SupabaseService.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});
  }

  void _stopRealtimeListeners() {
    _reloadDebounce?.cancel();
    _transactionsSubscription?.cancel();
    _transactionsSubscription = null;
    _kycSubscription?.cancel();
    _kycSubscription = null;
    _profilesSubscription?.cancel();
    _profilesSubscription = null;
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'DashboardController',
      method: 'onClose',
      feature: 'Dashboard',
      status: 'INFO',
    );
    _stopRealtimeListeners();
    _presenceWorker?.dispose();
    _authWorker?.dispose();
    super.onClose();
  }

  Future<void> loadDashboardData() async {
    AppLoggerService.debugTrace(
      className: 'DashboardController',
      method: 'loadDashboardData',
      feature: 'Dashboard',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      stats.value = await _dashboardRepo.getDashboardStats();
      stats['active_users'] = _presenceService.onlineCount;
      stats.refresh();

      weeklyChartData.value = await _dashboardRepo.getWeeklylyVolume();
      await _fetchUrgentAlerts();
      AppLoggerService.debugTrace(
        className: 'DashboardController',
        method: 'loadDashboardData',
        feature: 'Dashboard',
        status: 'SUCCESS',
      );
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'DashboardController',
        method: 'loadDashboardData',
        feature: 'Dashboard',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      isLoading.value = false;
    }
  }

  int get totalUsers => stats['total_users'] ?? 0;
  int get activeUsers => stats['active_users'] ?? 0;
  double get totalInvested => (stats['total_invested'] ?? 0.0).toDouble();
  double get totalProfits => (stats['total_profits'] ?? 0.0).toDouble();
  int get pendingTransactions => stats['pending_txns'] ?? 0;
  double get dailyVolume => (stats['daily_volume'] ?? 0.0).toDouble();

  /// Chart Y values scaled for display (raw total_volume per day)
  List<double> get chartYValues {
    if (weeklyChartData.isEmpty) return List.filled(7, 0);
    return weeklyChartData.map((row) {
      final volume = (row['total_volume'] as num? ?? 0).toDouble();
      return volume > 0 ? (volume / 1000).clamp(0, 999).toDouble() : 0.0;
    }).toList();
  }

  Future<void> _fetchUrgentAlerts() async {
    try {
      pendingWithdrawalsCount.value = await SupabaseService.client
          .from('transactions')
          .count(CountOption.exact)
          .eq('type', 'withdrawal')
          .eq('status', 'pending');

      pendingKYCCount.value = await SupabaseService.client
          .from('kyc_documents')
          .count(CountOption.exact)
          .eq('status', 'pending');
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'DashboardController',
        method: '_fetchUrgentAlerts',
        feature: 'Dashboard',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
