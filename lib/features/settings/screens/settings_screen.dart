import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import 'fee_settings_screen.dart';
import 'currency_settings_screen.dart';
import 'transaction_limits_screen.dart';
import 'ads_screen.dart';
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
            // Profile Header Section
            Obx(() => _buildProfileHeader(context, authController)),
            const SizedBox(height: 32),

            // Management Section
            const Text(
              'الإدارة المركزية والامتثال',
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
              title: 'الوكلاء المعتمدون',
              subtitle: 'إدارة شبكة الموزعين والامتثال',
              onTap: () => Get.toNamed('/agents'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.handHoldingDollar,
              title: 'سلفات كاسبي',
              subtitle: 'إدارة السلف والقروض',
              onTap: () => Get.toNamed('/loans'),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: Icons.subscriptions_rounded,
              title: 'اشتراكات المستخدمين',
              subtitle: 'إدارة خطط الاشتراك (شهري / سنوي)',
              onTap: () => Get.toNamed('/subscriptions'),
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
              onTap: () => Get.toNamed('/add-notification'),
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
              icon: FontAwesomeIcons.rectangleAd,
              title: 'إدارة الإعلانات',
              subtitle: 'إدارة الإعلانات المعروضة في تطبيق المستخدم',
              onTap: () => Get.to(() => const AdsScreen()),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.percent,
              title: 'الرسوم والعمولات',
              subtitle: 'إدارة رسوم السحب والإيداع والاستثمار',
              onTap: () => Get.to(() => const FeeSettingsScreen()),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.coins,
              title: 'العملات',
              subtitle: 'إدارة العملات المدعومة وأسعار الصرف',
              onTap: () => Get.to(() => const CurrencySettingsScreen()),
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              icon: FontAwesomeIcons.sliders,
              title: 'حدود المعاملات',
              subtitle: 'ضبط الحدود الدنيا والقصوى للعمليات',
              onTap: () => Get.to(() => const TransactionLimitsScreen()),
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
                  activeThumbColor: KasbyColors.primaryGold,
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

  Widget _buildProfileHeader(BuildContext context, AuthController authController) {
    final user = authController.profile.value;
    final avatarUrl = user?.avatarUrl;

    return GestureDetector(
      onTap: () => Get.toNamed('/profile'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              KasbyColors.primaryGold.withValues(alpha: 0.15),
              KasbyColors.primaryGold.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: KasbyColors.primaryGold.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KasbyColors.primaryGold.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.black26,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: KasbyColors.primaryGold,
                            size: 40,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: KasbyColors.primaryGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? authController.userName.value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '---',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      authController.userRole.value == 'Admin' ? 'مدير النظام' : authController.userRole.value,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
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
