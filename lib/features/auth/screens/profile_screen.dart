import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: 'أيمن محمد');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الملف الشخصي الملكي',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
          Container(color: const Color(0xFF0F172A)),
          _buildOrb(
            top: -50,
            right: -50,
            size: 300,
            color: KasbyColors.primaryGold.withValues(alpha: 0.05),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
            child: Column(
              children: [
                // Majestic Avatar
                _buildMajesticAvatar(),
                const SizedBox(height: 48),

                // Info Cards
                _buildInfoSection('المعلومات الشخصية', [
                  KasbyTextField(
                    controller: nameController,
                    hintText: 'الاسم الكامل',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  const KasbyTextField(
                    hintText: 'ayman@kasby.com',
                    prefixIcon: Icons.email_outlined,
                    enabled: false,
                  ),
                ], delay: 200),
                const SizedBox(height: 24),

                // Security Card
                _buildInfoSection('الأمان والخصوصية', [
                  KasbyTextField(
                    controller: passwordController,
                    hintText: 'كلمة المرور الجديدة',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  KasbyTextField(
                    controller: confirmPasswordController,
                    hintText: 'تأكيد كلمة المرور',
                    prefixIcon: Icons.lock_reset,
                    obscureText: true,
                  ),
                ], delay: 400),
                const SizedBox(height: 48),

                // Save Button
                KasbyButton(
                      text: 'تحديث الهوية الرقمية',
                      onPressed: () {
                        Get.snackbar(
                          'تم التحديث',
                          'تم حفظ المعلومات الشخصية بنجاح',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: KasbyColors.success.withValues(
                            alpha: 0.8,
                          ),
                          colorText: Colors.white,
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 600))
                    .scale(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajesticAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rotating Aura
        Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: const Duration(seconds: 3),
              color: KasbyColors.primaryGold.withValues(alpha: 0.2),
            ),

        // Pulsing Shadow
        Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: KasbyColors.primaryGold.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              duration: const Duration(seconds: 2),
            ),

        // Avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: KasbyColors.primaryGradient,
            shape: BoxShape.circle,
            border: Border.all(color: KasbyColors.primaryGold, width: 3),
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, size: 70, color: Colors.black),
          ),
        ),

        // Camera Badge
        Positioned(
          bottom: 0,
          right: 5,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 20,
              color: Colors.black,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _buildInfoSection(
    String title,
    List<Widget> children, {
    required int delay,
  }) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: KasbyColors.primaryGold,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.1);
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
              .moveY(begin: -20, end: 20, duration: const Duration(seconds: 5)),
    );
  }
}
