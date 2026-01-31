import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/kasby_colors.dart';
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
  final _otpController = TextEditingController();
  final _authController = Get.find<AuthController>();
  String _currentOtp = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (_currentOtp.length == 6) {
      final success = await _authController.verifyOtp(_currentOtp);
      if (success) {
        Get.offAllNamed('/dashboard');
      }
    } else {
      Get.snackbar(
        'خطأ',
        'الرجاء إدخال رمز التحقق المكون من 6 أرقام',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: KasbyColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: KasbyColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'التحقق من الهوية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Obx(
                  () => Text(
                    'تم إرسال رمز التحقق: ${_authController.generatedOtp.value}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: KasbyColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '(في التطبيق الحقيقي، سيتم إرسال الرمز عبر SMS أو البريد الإلكتروني)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: KasbyColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 48),

                // PIN Code Field
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    onChanged: (value) {
                      setState(() {
                        _currentOtp = value;
                      });
                    },
                    onCompleted: (value) {
                      _currentOtp = value;
                    },
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 56,
                      fieldWidth: 48,
                      activeFillColor: KasbyColors.surface,
                      inactiveFillColor: KasbyColors.surface,
                      selectedFillColor: KasbyColors.surface,
                      activeColor: KasbyColors.primaryGold,
                      inactiveColor: KasbyColors.surface,
                      selectedColor: KasbyColors.primaryGold,
                    ),
                    cursorColor: KasbyColors.primaryGold,
                    animationDuration: const Duration(milliseconds: 300),
                    backgroundColor: Colors.transparent,
                    enableActiveFill: true,
                    keyboardType: TextInputType.number,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: KasbyColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Verify Button
                Obx(
                  () => KasbyButton(
                    text: 'تحقق',
                    onPressed: _handleVerifyOtp,
                    isLoading: _authController.isLoading.value,
                  ),
                ),
                const SizedBox(height: 16),

                // Resend OTP
                TextButton(
                  onPressed: () {
                    // In real app, resend OTP
                    Get.snackbar(
                      'تم الإرسال',
                      'تم إعادة إرسال رمز التحقق',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text(
                    'إعادة إرسال الرمز',
                    style: TextStyle(color: KasbyColors.primaryGold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
