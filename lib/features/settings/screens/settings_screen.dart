import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../auth/controllers/auth_controller.dart';

/// Settings Screen
/// App configuration and admin settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
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
            const SizedBox(height: 24),

            // Notifications Section
            const Text(
              'الإشعارات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              icon: FontAwesomeIcons.fileContract,
              title: 'الشروط والأحكام',
              subtitle: 'تحديث الشروط والأحكام',
              onTap: () => Get.snackbar('قريباً', 'هذه الميزة قيد التطوير'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.circleQuestion,
              title: 'الأسئلة الشائعة',
              subtitle: 'إدارة الأسئلة الشائعة',
              onTap: () => Get.snackbar('قريباً', 'هذه الميزة قيد التطوير'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.wrench,
              title: 'وضع الصيانة',
              subtitle: 'تفعيل/تعطيل وضع الصيانة',
              onTap: () => _showMaintenanceModeDialog(context),
            ),
            const SizedBox(height: 24),

            // Account Section
            const Text(
              'الحساب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              icon: FontAwesomeIcons.rightFromBracket,
              title: 'تسجيل الخروج',
              subtitle: 'الخروج من الحساب',
              onTap: () {
                Get.dialog(
                  AlertDialog(
                    backgroundColor: KasbyColors.surface,
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: KasbyColors.textPrimary),
                    ),
                    content: const Text(
                      'هل أنت متأكد من تسجيل الخروج؟',
                      style: TextStyle(color: KasbyColors.textBody),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(color: KasbyColors.textSecondary),
                        ),
                      ),
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
              },
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
  }) {
    return KasbyCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (iconColor ?? KasbyColors.primaryGold).withOpacity(0.2),
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
                    color: KasbyColors.textPrimary,
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
          const Icon(
            Icons.arrow_forward_ios,
            color: KasbyColors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _showMaintenanceModeDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'وضع الصيانة',
          style: TextStyle(color: KasbyColors.textPrimary),
        ),
        content: const Text(
          'هذه الميزة ستسمح بتفعيل وضع الصيانة للتطبيق',
          style: TextStyle(color: KasbyColors.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'حسناً',
              style: TextStyle(color: KasbyColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }
}
