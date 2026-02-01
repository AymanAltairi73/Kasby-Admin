import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/controllers/theme_controller.dart';

/// Settings Screen
/// App configuration and admin settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Management Section
            const Text(
              'الإدارة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              icon: FontAwesomeIcons.chartLine,
              title: 'خطط الاستثمار',
              subtitle: 'إدارة خطط الاستثمار',
              onTap: () => Get.toNamed('/investment-plans'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.moneyBillTrendUp,
              title: 'استثمارات المستخدمين',
              subtitle: 'عرض جميع الاستثمارات',
              onTap: () => Get.toNamed('/user-investments'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.userTie,
              title: 'الوكلاء',
              subtitle: 'إدارة الوكلاء والممثلين',
              onTap: () => Get.toNamed('/agents'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.userShield,
              title: 'إدارة المشرفين',
              subtitle: 'إدارة حسابات المسؤولين والصلاحيات',
              onTap: () => Get.toNamed('/admin-management'),
            ),
            const SizedBox(height: 24),

            // Notifications Section
            const Text(
              'الإشعارات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              icon: FontAwesomeIcons.bellConcierge,
              title: 'إرسال إشعار',
              subtitle: 'إرسال إشعار لجميع المستخدمين',
              onTap: () => Get.toNamed('/notifications'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.gift,
              title: 'المكافآت والنقاط',
              subtitle: 'إدارة نظام المكافآت',
              onTap: () => Get.toNamed('/rewards'),
            ),
            const SizedBox(height: 24),

            // App Configuration Section
            const Text(
              'إعدادات التطبيق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              icon: FontAwesomeIcons.fileContract,
              title: 'الشروط والأحكام',
              subtitle: 'تحديث الشروط والأحكام',
              onTap: () => Get.toNamed('/terms'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.circleQuestion,
              title: 'الأسئلة الشائعة',
              subtitle: 'إدارة الأسئلة الشائعة',
              onTap: () => Get.toNamed('/faq'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.wrench,
              title: 'وضع الصيانة',
              subtitle: 'تفعيل/تعطيل وضع الصيانة',
              onTap: () => Get.toNamed('/maintenance'),
            ),
            const SizedBox(height: 24),

            // Account Section
            const Text(
              'الحساب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              icon: FontAwesomeIcons.userPen,
              title: 'الملف الشخصي',
              subtitle: 'تعديل البيانات الشخصية وكلمة المرور',
              onTap: () => Get.toNamed('/profile'),
            ),
            const SizedBox(height: 8),
            Obx(
              () => _buildSettingCard(
                icon: themeController.isDarkMode.value
                    ? FontAwesomeIcons.moon
                    : FontAwesomeIcons.sun,
                title: 'المظهر',
                subtitle: themeController.isDarkMode.value
                    ? 'الوضع الليلي'
                    : 'الوضع النهاري',
                onTap: () => themeController.toggleTheme(),
                trailing: Switch(
                  value: themeController.isDarkMode.value,
                  onChanged: (_) => themeController.toggleTheme(),
                  activeColor: KasbyColors.primaryGold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.rightFromBracket,
              title: 'تسجيل الخروج',
              subtitle: 'الخروج من الحساب',
              onTap: () => _showLogoutDialog(context, authController),
              iconColor: KasbyColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return KasbyCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (iconColor ?? KasbyColors.primaryGold).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? KasbyColors.primaryGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: KasbyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
