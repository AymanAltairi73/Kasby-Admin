import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'app_logger_service.dart';

/// حالة الاتصال بالإنترنت - نسخة الأدمن (تفاصيل أكثر)
enum ConnectionStatus {
  /// اتصال فعال ومستقر
  connected,

  /// منقطع عن الإنترنت تماماً
  disconnected,

  /// جاري التحقق من الاتصال
  checking,
}

/// خدمة مركزية لإدارة حالة الاتصال - نسخة الأدمن.
/// تتميز عن نسخة المستخدم بـ:
///   • تسجيل الأخطاء تلقائياً عبر AppLoggerService
///   • عرض نوع الشبكة (WiFi/Mobile/Other)
///   • عداد مرات الانقطاع
///   • معلومات تقنية إضافية
class NetworkService extends GetxService {
  // ─────────── State ───────────
  final connectionStatus = ConnectionStatus.checking.obs;
  final isConnected = true.obs;
  final networkType = 'unknown'.obs;
  final disconnectCount = 0.obs;
  final lastChecked = Rxn<DateTime>();

  // ─────────── Internal ───────────
  final Connectivity _connectivity = Connectivity();
  late final InternetConnection _internetChecker;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<InternetStatus>? _internetSub;
  Timer? _retryTimer;

  /// Whether the device currently has internet access.
  bool get hasConnection => isConnected.value;

  // ─────────── Lifecycle ───────────

  Future<NetworkService> init() async {
    _internetChecker = InternetConnection.createInstance(
      checkInterval: const Duration(seconds: 10),
    );

    // 1. Check initial state
    await _checkConnection();

    // 2. Listen to connectivity changes
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      (results) => _onConnectivityChanged(results),
    );

    // 3. Listen to actual internet
    _internetSub = _internetChecker.onStatusChange.listen(
      (status) => _onInternetStatusChanged(status),
    );

    debugPrint('[NetworkService:Admin] ✓ Initialized. Online: ${isConnected.value}');
    return this;
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    _internetSub?.cancel();
    _retryTimer?.cancel();
    super.onClose();
  }

  // ─────────── Core Logic ───────────

  Future<void> _checkConnection() async {
    connectionStatus.value = ConnectionStatus.checking;
    lastChecked.value = DateTime.now();
    try {
      final hasInternet = await _internetChecker.hasInternetAccess;
      _updateStatus(hasInternet);
    } catch (e) {
      _updateStatus(false);
      debugPrint('[NetworkService:Admin] ✗ Check failed: $e');
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateNetworkType(results);

    final hasAnyConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasAnyConnection) {
      _updateStatus(false);
    } else {
      _checkConnection();
    }
  }

  void _onInternetStatusChanged(InternetStatus status) {
    _updateStatus(status == InternetStatus.connected);
  }

  /// Update the human-readable network type name.
  void _updateNetworkType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      networkType.value = 'WiFi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      networkType.value = 'بيانات الهاتف';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      networkType.value = 'Ethernet';
    } else if (results.contains(ConnectivityResult.vpn)) {
      networkType.value = 'VPN';
    } else if (results.contains(ConnectivityResult.other)) {
      networkType.value = 'أخرى';
    } else {
      networkType.value = 'غير متصل';
    }
  }

  void _updateStatus(bool online) {
    final wasOffline = !isConnected.value;
    isConnected.value = online;
    connectionStatus.value =
        online ? ConnectionStatus.connected : ConnectionStatus.disconnected;

    if (online && wasOffline) {
      debugPrint('[NetworkService:Admin] ✓ Connection restored.');
      _retryTimer?.cancel();
    } else if (!online && !wasOffline) {
      disconnectCount.value++;
      debugPrint(
          '[NetworkService:Admin] ✗ Connection lost. Total disconnects: ${disconnectCount.value}');

      // Log to server (fire-and-forget, doesn't need internet itself)
      AppLoggerService.logError(
        controller: 'NetworkService',
        method: 'connectionLost',
        error: 'Internet connection lost. Network type: ${networkType.value}. '
            'Disconnect #${disconnectCount.value}',
      );

      _startRetryLoop();
    }
  }

  void _startRetryLoop() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!isConnected.value) {
        _checkConnection();
      } else {
        _retryTimer?.cancel();
      }
    });
  }

  /// Force a manual retry.
  Future<void> retryConnection() async {
    debugPrint('[NetworkService:Admin] ℹ Manual retry triggered.');
    await _checkConnection();
  }

  // ─────────── API Guard ───────────

  Future<T?> guardedRequest<T>(Future<T> Function() request) async {
    if (!isConnected.value) {
      Get.snackbar(
        'لا يوجد اتصال',
        'يرجى التحقق من اتصالك بالإنترنت ثم حاول مرة أخرى.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return null;
    }

    try {
      return await request();
    } on SocketException catch (e) {
      _updateStatus(false);
      AppLoggerService.logError(
        controller: 'NetworkService',
        method: 'guardedRequest',
        error: 'SocketException: $e',
      );
      return null;
    } on TimeoutException catch (e) {
      AppLoggerService.logError(
        controller: 'NetworkService',
        method: 'guardedRequest',
        error: 'TimeoutException: $e',
      );
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Shortcut
  static NetworkService get to => Get.find<NetworkService>();
}
