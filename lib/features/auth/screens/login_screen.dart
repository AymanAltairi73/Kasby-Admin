import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/auth_controller.dart';

/// Login Screen
/// Admin authentication with username and password
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill username if remembered
    if (_authController.rememberMe.value) {
      _usernameController.text = _authController.savedUsername.value;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success) {
        Get.toNamed('/otp');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Celestial Background (Moving Orbs)
          _buildCelestialBackground(),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Radiant Logo
                    _buildRadiantLogo(),
                    const SizedBox(height: 32),

                    // Title Section
                    const Text(
                          'Kasby Panel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 800))
                        .slideY(begin: 0.2),
                    const SizedBox(height: 8),
                    const Text(
                      'مرحباً بك في لوحة التحكم ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: KasbyColors.textSecondary,
                      ),
                    ).animate().fadeIn(
                      delay: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 48),

                    // Crystal Login Form
                    KasbyGlassCard(
                          padding: const EdgeInsets.all(24),
                          opacity: 0.1,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: KasbyColors.primaryGold.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Username Field
                                KasbyTextField(
                                      controller: _usernameController,
                                      hintText: 'اسم المستخدم',
                                      prefixIcon: Icons.person_outline,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال اسم المستخدم';
                                        }
                                        return null;
                                      },
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: const Duration(milliseconds: 400),
                                    )
                                    .slideX(begin: -0.1),
                                const SizedBox(height: 16),

                                // Password Field
                                KasbyTextField(
                                      controller: _passwordController,
                                      hintText: 'كلمة المرور',
                                      prefixIcon: Icons.lock_outline,
                                      suffixIcon: _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      onSuffixIconTap: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      obscureText: _obscurePassword,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال كلمة المرور';
                                        }
                                        return null;
                                      },
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: const Duration(milliseconds: 500),
                                    )
                                    .slideX(begin: -0.1),
                                const SizedBox(height: 12),

                                // Remember me & Forgot Password
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Obx(
                                          () => SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _authController
                                                  .rememberMe
                                                  .value,
                                              onChanged: (value) =>
                                                  _authController
                                                      .toggleRememberMe(
                                                        value ?? false,
                                                      ),
                                              activeColor:
                                                  KasbyColors.primaryGold,
                                              checkColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'تذكرني',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: KasbyColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Get.toNamed('/forgot-password'),
                                      child: const Text(
                                        'نسيت كلمة المرور؟',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: KasbyColors.primaryGold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(
                                  delay: const Duration(milliseconds: 600),
                                ),
                                const SizedBox(height: 24),

                                // Login Button
                                Obx(
                                  () => KasbyButton(
                                    text: 'دخول آمن',
                                    onPressed: _handleLogin,
                                    isLoading: _authController.isLoading.value,
                                  ),
                                ).animate().fadeIn(delay: 700.ms).scale(),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 300))
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
        // Dark Base
        Container(color: const Color(0xFF0F172A)),

        // Animated Orbs
        _buildOrb(
          top: -100,
          left: -100,
          size: 400,
          color: KasbyColors.primaryGold.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -150,
          right: -150,
          size: 500,
          color: KasbyColors.info.withValues(alpha: 0.05),
        ),
        _buildOrb(
          top: 200,
          right: -50,
          size: 300,
          color: KasbyColors.success.withValues(alpha: 0.03),
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
              .moveY(begin: -30, end: 30, duration: const Duration(seconds: 6))
              .moveX(begin: -30, end: 30, duration: const Duration(seconds: 8)),
    );
  }

  Widget _buildRadiantLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Aura
        Container(
              width: 140,
              height: 140,
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

        // Brand Circle
        Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: KasbyColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: KasbyColors.primaryGold.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'K',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: const Duration(seconds: 3),
              color: Colors.white.withValues(alpha: 0.2),
            ),
      ],
    );
  }
}
