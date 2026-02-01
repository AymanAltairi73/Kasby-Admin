import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isMaintenanceActive = false;
  final _messageController = TextEditingController(
    text: 'نحن نقوم ببعض الصيانة للنظام. سنعود قريباً!',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'وضع الصيانة',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildCelestialBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildControlHeader(),
                  const SizedBox(height: 32),

                  // Main Toggle Card
                  KasbyGlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تفعيل وضع الصيانة',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'سيتم حظر وصول المستخدمين للتطبيق',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: KasbyColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isMaintenanceActive,
                              onChanged: (value) =>
                                  setState(() => _isMaintenanceActive = value),
                              activeColor: KasbyColors.primaryGold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Message Card
                  KasbyGlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'رسالة التنبيه للمستخدمين',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: KasbyColors.primaryGold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            KasbyTextField(
                              controller: _messageController,
                              hintText: 'اكتب رسالة الصيانة هنا...',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'معاينة الرسالة:',
                              style: TextStyle(
                                fontSize: 12,
                                color: KasbyColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                _messageController.text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 200))
                      .slideY(begin: 0.1),

                  const SizedBox(height: 40),

                  // Action Buttons
                  KasbyButton(
                        text: 'حفظ و تحديث الحالة',
                        onPressed: () {
                          Get.snackbar(
                            'تم الحفظ',
                            'تم تحديث إعدادات وضع الصيانة بنجاح',
                            backgroundColor: KasbyColors.success.withValues(
                              alpha: 0.8,
                            ),
                            colorText: Colors.white,
                          );
                        },
                      )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 400))
                      .scale(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (_isMaintenanceActive
                                ? KasbyColors.error
                                : KasbyColors.primaryGold)
                            .withValues(alpha: 0.1),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: const Duration(seconds: 2),
                ),

            Icon(
              _isMaintenanceActive
                  ? Icons.engineering_rounded
                  : Icons.lock_open_rounded,
              size: 50,
              color: _isMaintenanceActive
                  ? KasbyColors.error
                  : KasbyColors.primaryGold,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _isMaintenanceActive
              ? 'وضع الصيانة نشط حالياً'
              : 'النظام يعمل بشكل طبيعي',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isMaintenanceActive
                ? KasbyColors.error
                : KasbyColors.primaryGold,
          ),
        ),
      ],
    );
  }

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF0F172A)),
        _buildOrb(
          top: -50,
          right: -100,
          size: 300,
          color: KasbyColors.error.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -100,
          left: -100,
          size: 400,
          color: KasbyColors.primaryGold.withValues(alpha: 0.05),
        ),
      ],
    );
  }

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child:
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: const Duration(seconds: 2),
              ),
    );
  }
}
