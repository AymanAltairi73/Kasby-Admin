import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/services/app_logger_service.dart';

class SystemHealthController extends GetxController {
  final isLoading = false.obs;

  // Service statuses
  final supabaseStatus = 'checking'.obs; // 'online', 'offline', 'checking'
  final fcmStatus = 'checking'.obs;

  // Metrics
  final activeUsersCount = 0.obs;
  final pendingDeposits = 0.obs;
  final pendingWithdrawals = 0.obs;
  final pendingKyc = 0.obs;
  final apiResponseTimeMs = 0.obs;

  // Error logs
  final recentErrors = <Map<String, dynamic>>[].obs;

  Timer? _autoRefreshTimer;
  late PresenceService _presenceService;
  Worker? _presenceWorker;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'SystemHealthController',
      method: 'onInit',
      feature: 'Monitoring',
      status: 'INFO',
    );
    super.onInit();
    _presenceService = Get.find<PresenceService>();

    _presenceWorker = ever(_presenceService.onlineUsers, (_) {
      activeUsersCount.value = _presenceService.onlineCount;
    });
    activeUsersCount.value = _presenceService.onlineCount;

    loadAll();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadAll(),
    );
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'SystemHealthController',
      method: 'onClose',
      feature: 'Monitoring',
      status: 'INFO',
    );
    _autoRefreshTimer?.cancel();
    _presenceWorker?.dispose();
    super.onClose();
  }

  Future<void> loadAll() async {
    AppLoggerService.debugTrace(
      className: 'SystemHealthController',
      method: 'loadAll',
      feature: 'Monitoring',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      await Future.wait([
        _checkSupabaseHealth(),
        _fetchPendingOperations(),
        _fetchRecentErrors(),
      ]);
      AppLoggerService.debugTrace(
        className: 'SystemHealthController',
        method: 'loadAll',
        feature: 'Monitoring',
        status: 'SUCCESS',
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'SystemHealthController',
        method: 'loadAll',
        feature: 'Monitoring',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _checkSupabaseHealth() async {
    supabaseStatus.value = 'checking';
    fcmStatus.value = 'checking';
    final stopwatch = Stopwatch()..start();
    try {
      await SupabaseService.client
          .from('profiles')
          .select('id')
          .limit(1);
      stopwatch.stop();
      apiResponseTimeMs.value = stopwatch.elapsedMilliseconds;
      supabaseStatus.value = 'online';
    } catch (_) {
      stopwatch.stop();
      apiResponseTimeMs.value = stopwatch.elapsedMilliseconds;
      supabaseStatus.value = 'offline';
    }

    // FCM status — infer from Firebase availability
    try {
      // If we can reach Supabase, FCM is likely available too.
      // A more granular check would require Firebase Admin SDK;
      // for now we mirror Supabase connectivity as a proxy.
      fcmStatus.value = supabaseStatus.value == 'online' ? 'online' : 'offline';
    } catch (_) {
      fcmStatus.value = 'offline';
    }
  }

  Future<void> _fetchPendingOperations() async {
    try {
      pendingDeposits.value = await SupabaseService.client
          .from('transactions')
          .count(CountOption.exact)
          .eq('type', 'deposit')
          .eq('status', 'pending');

      pendingWithdrawals.value = await SupabaseService.client
          .from('transactions')
          .count(CountOption.exact)
          .eq('type', 'withdrawal')
          .eq('status', 'pending');

      pendingKyc.value = await SupabaseService.client
          .from('kyc_documents')
          .count(CountOption.exact)
          .eq('status', 'pending');
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'SystemHealthController',
        method: '_fetchPendingOperations',
        feature: 'Monitoring',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _fetchRecentErrors() async {
    try {
      final response = await SupabaseService.client
          .from('system_logs')
          .select('id, level, message, context, created_at')
          .eq('level', 'error')
          .order('created_at', ascending: false)
          .limit(10);

      recentErrors.assignAll(
        (response as List).map((row) => Map<String, dynamic>.from(row)),
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'SystemHealthController',
        method: '_fetchRecentErrors',
        feature: 'Monitoring',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      recentErrors.clear();
    }
  }

  int get totalPendingOps =>
      pendingDeposits.value + pendingWithdrawals.value + pendingKyc.value;
}
