import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/auth_controller.dart';

/// Forgot Password Screen
/// Reset password flow
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      await _authController.forgotPassword(_emailController.text);
      Get.back();
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
                    // Radiant Reset Icon
                    _buildRadiantResetIcon(),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'استعادة الوصول',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 800),
                    ),
                    const SizedBox(height: 16),

                    // Crystal Reset Form
                    KasbyGlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'أدخل بريدك الإلكتروني المسجل وسنرسل لك رابطاً سحرياً لاستعادة كلمة المرور',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: KasbyColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Email Field
                                KasbyTextField(
                                      controller: _emailController,
                                      hintText: 'البريد الإلكتروني',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال البريد الإلكتروني';
                                        }
                                        if (!GetUtils.isEmail(value)) {
                                          return 'الرجاء إدخال بريد إلكتروني صحيح';
                                        }
                                        return null;
                                      },
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: const Duration(milliseconds: 400),
                                    )
                                    .slideX(begin: -0.1),
                                const SizedBox(height: 32),

                                // Reset Button
                                Obx(
                                      () => KasbyButton(
                                        text: 'إرسال الرابط السحري',
                                        onPressed: _handleResetPassword,
                                        isLoading:
                                            _authController.isLoading.value,
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: const Duration(milliseconds: 600),
                                    )
                                    .scale(),
                                const SizedBox(height: 16),

                                // Back to Login
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text(
                                    'العودة لتسجيل الدخول',
                                    style: TextStyle(
                                      color: KasbyColors.primaryGold.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 200))
                        .slideY(begin: 0.1),
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
        Container(color: const Color(0xFF0F172A)),
        _buildOrb(
          top: -50,
          left: -50,
          size: 350,
          color: KasbyColors.error.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -100,
          right: -100,
          size: 450,
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
              .moveY(begin: -20, end: 20, duration: const Duration(seconds: 5))
              .moveX(begin: -20, end: 20, duration: const Duration(seconds: 7)),
    );
  }

  Widget _buildRadiantResetIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KasbyColors.primaryGold.withValues(alpha: 0.05),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: const Duration(seconds: 3),
            )
            .fadeIn(duration: const Duration(seconds: 2)),

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
                Icons.shield_moon_rounded,
                size: 40,
                color: KasbyColors.primaryGold,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -5, end: 5, duration: const Duration(seconds: 2)),
      ],
    );
  }
}
