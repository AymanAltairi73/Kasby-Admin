import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/network_service.dart';

/// شريط تنبيه ذكي للأدمن — يعرض تفاصيل إضافية مع زر إعادة المحاولة.
class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          child,
          Obx(() {
            final network = NetworkService.to;
            final isOffline = !network.isConnected.value;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              top: isOffline ? 0 : -100,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: _buildBanner(context, network),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context, NetworkService network) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: !network.isConnected.value ? 1.0 : 0.0,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: topPadding + 8,
          bottom: 14,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Icon + Message + Retry button
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'لا يوجد اتصال بالإنترنت',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(() => Text(
                              'نوع الشبكة: ${network.networkType.value} · '
                              'الانقطاعات: ${network.disconnectCount.value}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontFamily: 'IBMPlexSansArabic',
                              ),
                            )),
                      ],
                    ),
                  ),

                  // Retry Button
                  Obx(() {
                    final checking = network.connectionStatus.value ==
                        ConnectionStatus.checking;
                    return InkWell(
                      onTap: checking ? null : () => network.retryConnection(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: checking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'إعادة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'IBMPlexSansArabic',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
