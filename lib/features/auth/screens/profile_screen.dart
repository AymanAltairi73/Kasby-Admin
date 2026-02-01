import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: 'أحمد علي');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Photo
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: KasbyColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 64, color: Colors.black),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: KasbyColors.primaryGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Basic Info section
            _buildSectionTitle('المعلومات الأساسية'),
            const SizedBox(height: 16),
            KasbyTextField(
              controller: nameController,
              hintText: 'الاسم الكامل',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            const KasbyTextField(
              hintText: 'ahmed@kasby.com',
              prefixIcon: Icons.email_outlined,
              enabled: false,
            ),
            const SizedBox(height: 32),

            // Security Section
            _buildSectionTitle('تغيير كلمة المرور'),
            const SizedBox(height: 16),
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
            const SizedBox(height: 48),

            // Save Button
            KasbyButton(
              text: 'حفظ التغييرات',
              onPressed: () {
                Get.snackbar(
                  'نجاح',
                  'تم تحديث البيانات الشخصية بنجاح',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: KasbyColors.success.withValues(alpha: 0.8),
                  colorText: Colors.white,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: KasbyColors.primaryGold,
        ),
      ),
    );
  }
}
