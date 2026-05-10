import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/network_service.dart';

/// حالات الاتصال المُحسّنة
enum NetworkQuality {
  /// متصل بشكل جيد
  good,

  /// اتصال ضعيف/بطيء
  weak,

  /// منقطع completely
  offline,
}

/// Snackbar ذكي للأدمن يظهر عند انقطاع الإنترنت أو ضعفه
/// يستخدم GetX Snackbar بدلاً من overlay مع تفاصيل تقنية إضافية
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  NetworkQuality _lastQuality = NetworkQuality.good;
  DateTime? _lastSnackbarTime;
  static const _minSnackbarInterval = Duration(seconds: 3);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _buildWithListener(),
    );
  }

  Widget _buildWithListener() {
    return Obx(() {
      final network = NetworkService.to;
      final quality = _determineQuality(network);

      // Show snackbar when quality changes to bad
      if (quality != _lastQuality) {
        _lastQuality = quality;

        if (quality == NetworkQuality.offline) {
          _showOfflineSnackbar(network);
        } else if (quality == NetworkQuality.weak) {
          _showWeakConnectionSnackbar(network);
        }
      }

      return widget.child;
    });
  }

  /// تحديد جودة الاتصال
  NetworkQuality _determineQuality(NetworkService network) {
    if (!network.isConnected.value) {
      return NetworkQuality.offline;
    }

    // استخدام جودة الاتصال المقاسة
    switch (network.connectionQuality.value) {
      case ConnectionQuality.weak:
        return NetworkQuality.weak;
      case ConnectionQuality.good:
        return NetworkQuality.good;
      case ConnectionQuality.unknown:
        // إذا لم يتم القياس بعد، نفترض أنه جيد
        return NetworkQuality.good;
    }
  }

  /// عرض Snackbar للاتصال المنقطع - نسخة الأدمن مع تفاصيل تقنية
  void _showOfflineSnackbar(NetworkService network) {
    if (!_shouldShowSnackbar()) return;

    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 6),
      backgroundColor: const Color(0xFFDC2626),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      snackStyle: SnackStyle.FLOATING,
      mainButton: TextButton(
        onPressed: () => network.retryConnection(),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'إعادة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      titleText: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'لا يوجد اتصال بالإنترنت',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
        ],
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(right: 38),
        child: Obx(() => Text(
          'نوع الشبكة: ${network.networkType.value} · '
          'الانقطاعات: ${network.disconnectCount.value}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'IBMPlexSansArabic',
          ),
        )),
      ),
    );
  }

  /// عرض Snackbar للاتصال الضعيف - نسخة الأدمن
  void _showWeakConnectionSnackbar(NetworkService network) {
    if (!_shouldShowSnackbar()) return;

    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
      backgroundColor: const Color(0xFFF59E0B), // لون برتقالي للتحذير
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      snackStyle: SnackStyle.FLOATING,
      mainButton: TextButton(
        onPressed: () => network.retryConnection(),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'إعادة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      titleText: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.signal_cellular_connected_no_internet_4_bar_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'اتصال ضعيف',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
        ],
      ),
      messageText: const Padding(
        padding: EdgeInsets.only(right: 38),
        child: Text(
          'جاري تحميل البيانات ببطء، يرجى الانتظار أو التحقق من الشبكة',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
    );
  }

  /// التحقق من عدم إظهار Snackbar متتالية بسرعة
  bool _shouldShowSnackbar() {
    final now = DateTime.now();
    if (_lastSnackbarTime != null) {
      final diff = now.difference(_lastSnackbarTime!);
      if (diff < _minSnackbarInterval) {
        return false;
      }
    }
    _lastSnackbarTime = now;
    return true;
  }
}
