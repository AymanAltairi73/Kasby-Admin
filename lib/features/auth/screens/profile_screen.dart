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
    final emailController = TextEditingController(text: 'ayman@kasby.com');
    final phoneController = TextEditingController(text: '+964 77660444646');

    final countryController = TextEditingController(
      text: 'العراق',
    );
    final provinceController = TextEditingController(text: 'بغداد');
    final cityController = TextEditingController(text: 'الكرخ');
    final addressController = TextEditingController(
      text: 'شارع التخصصي، حي العليا',
    );

    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Get.offAllNamed('/login'),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
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

                // Personal Info
                _buildInfoSection('المعلومات الشخصية', [
                  KasbyTextField(
                    controller: nameController,
                    hintText: 'الاسم الكامل',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  KasbyTextField(
                    controller: emailController,
                    hintText: 'البريد الإلكتروني',
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  KasbyTextField(
                    controller: phoneController,
                    hintText: 'رقم الهاتف',
                    prefixIcon: Icons.phone_android_outlined,
                  ),
                ], delay: 100),
                const SizedBox(height: 24),

                // Location Details
                _buildInfoSection('تفاصيل الموقع', [
                  KasbyTextField(
                    controller: countryController,
                    hintText: 'الدولة',
                    prefixIcon: Icons.public_outlined,
                  ),
                  const SizedBox(height: 16),
                  KasbyTextField(
                    controller: provinceController,
                    hintText: 'المحافظة / المنطقة',
                    prefixIcon: Icons.map_outlined,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: KasbyTextField(
                          controller: cityController,
                          hintText: 'المدينة',
                          prefixIcon: Icons.location_city_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  KasbyTextField(
                    controller: addressController,
                    hintText: 'العنوان',
                    prefixIcon: Icons.home_outlined,
                    maxLines: 2,
                  ),
                ], delay: 200),
                const SizedBox(height: 24),

                // Account Status & Finances
                _buildInfoSection('حالة الحساب والمالية', [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusBadge(
                          'نوع الحساب',
                          'VIP',
                          KasbyColors.primaryGold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusBadge(
                          'التوثيق',
                          'مـوثـق',
                          KasbyColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 20),
                  _buildFinancialRow(
                    'رصيد المحفظة',
                    '5,000.00\$',
                    Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialRow(
                    'إجمالي الاستثمار',
                    '15,000.00\$',
                    Icons.trending_up_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialRow(
                    'مبالغ معلقة',
                    '500.00\$',
                    Icons.hourglass_empty_rounded,
                  ),
                ], delay: 300),
                const SizedBox(height: 24),

                // Security Card
                _buildInfoSection('تغيير كلمة المرور', [
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
                          'تم حفظ المعلومات بنجاح',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: KasbyColors.success.withValues(
                            alpha: 0.8,
                          ),
                          colorText: Colors.white,
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 500))
                    .scale(),
                const SizedBox(height: 50),
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

  Widget _buildStatusBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: KasbyColors.primaryGold.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: KasbyColors.primaryGold),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: KasbyColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: KasbyColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
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
