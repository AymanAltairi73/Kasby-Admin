import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../controllers/auth_controller.dart';

/// OTP Verification Screen
/// Verify the OTP sent to admin
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authController = Get.find<AuthController>();
  String _currentOtp = '';

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (_currentOtp.length != 6) {
      Get.snackbar(
        'خطأ',
        'الرجاء إدخال رمز التحقق المكون من 6 أرقام',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final email = Get.arguments is String ? Get.arguments as String : null;
    final success = await _authController.verifyOtp(_currentOtp, email: email);
    if (success) {
      Get.offAllNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Celestial Background
          _buildCelestialBackground(),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Radiant Lock Icon
                    _buildRadiantLockIcon(),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'التحقق من الهوية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description & OTP Display
                    KasbyGlassCard(
                      padding: const EdgeInsets.all(20),
                      opacity: 0.1,
                      child: Column(
                        children: [
                          const Text(
                            'تم إرسال رمز الأمان الخاص بك',
                            style: TextStyle(color: KasbyColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: KasbyColors.primaryGold.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: KasbyColors.primaryGold.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Text(
                                '------',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: KasbyColors.primaryGold,
                                  letterSpacing: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // PIN Code Entry
                    KasbyGlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'أدخل الرمز المكون من 6 أرقام',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Directionality(
                            textDirection: ui.TextDirection.ltr,
                            child: PinCodeTextField(
                              appContext: context,
                              length: 6,
                              onChanged: (value) =>
                                  setState(() => _currentOtp = value),
                              pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                borderRadius: BorderRadius.circular(12),
                                fieldHeight: 50,
                                fieldWidth: 42,
                                activeFillColor: Theme.of(context).colorScheme.onSurface.withValues(
                                  alpha: 0.05,
                                ),
                                inactiveFillColor: Theme.of(context).colorScheme.onSurface.withValues(
                                  alpha: 0.05,
                                ),
                                selectedFillColor: Theme.of(context).colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                                activeColor: KasbyColors.primaryGold,
                                inactiveColor: Theme.of(context).colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                                selectedColor: KasbyColors.primaryGold,
                              ),
                              cursorColor: KasbyColors.primaryGold,
                              animationDuration: const Duration(
                                milliseconds: 300,
                              ),
                              backgroundColor: Colors.transparent,
                              enableActiveFill: true,
                              keyboardType: TextInputType.number,
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: KasbyColors.primaryGold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Verify Button
                          Obx(
                            () => KasbyButton(
                              text: 'تأكيد الرمز',
                              onPressed: _handleVerifyOtp,
                              isLoading: _authController.isLoading.value,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Resend Section
                          TextButton(
                            onPressed: () {
                              Get.snackbar(
                                'تم الإرسال',
                                'تم إعادة إرسال رمز التحقق بنجاح',
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                  color: KasbyColors.primaryGold.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'إرسال الرمز مرة أخرى',
                                  style: TextStyle(
                                    color: KasbyColors.primaryGold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        Container(color: Theme.of(context).scaffoldBackgroundColor),
        _buildOrb(
          top: -100,
          right: -100,
          size: 400,
          color: KasbyColors.info.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -150,
          left: -150,
          size: 500,
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
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiantLockIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: KasbyColors.primaryGold.withValues(alpha: 0.03),
          ),
        ),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: KasbyColors.primaryGold.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: KasbyColors.primaryGold.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: KasbyColors.primaryGold.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_open_rounded,
            size: 40,
            color: KasbyColors.primaryGold,
          ),
        ),
      ],
    );
  }
}
