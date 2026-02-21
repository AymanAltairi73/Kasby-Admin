import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/auth_controller.dart';
import 'register_screen.dart';

/// Login Screen
/// Admin authentication with username and password
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill username if remembered
    if (_authController.rememberMe.value) {
      _emailController.text = _authController.savedEmail.value;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        Get.offAllNamed('/main');
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
            top:
                false, // Allow logo to go under status bar if desired, but we'll use a container
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Radiant Logo (Now Full Width Header)
                  _buildRadiantLogo(),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: KasbyColors.primaryGold
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Username Field
                                    KasbyTextField(
                                          controller: _emailController,
                                          hintText: 'البريد الإلكتروني',
                                          prefixIcon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'الرجاء إدخال البريد الإلكتروني';
                                            }
                                            return null;
                                          },
                                        )
                                        .animate()
                                        .fadeIn(
                                          delay: const Duration(
                                            milliseconds: 400,
                                          ),
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
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          obscureText: _obscurePassword,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'الرجاء إدخال كلمة المرور';
                                            }
                                            return null;
                                          },
                                        )
                                        .animate()
                                        .fadeIn(
                                          delay: const Duration(
                                            milliseconds: 500,
                                          ),
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
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'تذكرني',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    KasbyColors.textSecondary,
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
                                        text: 'تسجيل دخول',
                                        onPressed: _handleLogin,
                                        isLoading:
                                            _authController.isLoading.value,
                                      ),
                                    ).animate().fadeIn(delay: 700.ms).scale(),
                                  ],
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: const Duration(milliseconds: 300))
                            .slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'ليس لديك حساب؟',
                              style: TextStyle(
                                color: KasbyColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Get.to(() => const RegisterScreen()),
                              child: const Text(
                                'إنشاء حساب جديد',
                                style: TextStyle(
                                  color: KasbyColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 1000.ms),
                      ],
                    ),
                  ),
                ],
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
    return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ClipPath(
            clipper: BottomArchClipper(),
            child: Image.asset(
              'assets/images/logoo.png',
              width: double.infinity,
              height: 350,
              fit: BoxFit.cover,
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms)
        .shimmer(
          duration: const Duration(seconds: 3),
          color: Colors.white.withValues(alpha: 0.2),
        );
  }
}

class BottomArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
