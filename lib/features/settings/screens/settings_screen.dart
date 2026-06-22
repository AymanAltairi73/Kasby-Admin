import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/services/permission_service.dart';
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
    final permService = Get.find<PermissionService>();

    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final canManage = permService.canManageSettings;
          final isSuperAdmin = permService.isSuperAdmin;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Section
              _buildProfileHeader(context, authController),
              const SizedBox(height: 32),

              // Management Section
              Text(
                'management_section'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: FontAwesomeIcons.chartLine,
                title: 'investment_plans'.tr,
                subtitle: 'manage_investment_plans'.tr,
                onTap: () => Get.toNamed('/investment-plans'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: FontAwesomeIcons.moneyBillTrendUp,
                title: 'user_investments_title'.tr,
                subtitle: 'view_all_investments'.tr,
                onTap: () => Get.toNamed('/user-investments'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: FontAwesomeIcons.userTie,
                title: 'authorized_agents'.tr,
                subtitle: 'manage_agents_network'.tr,
                onTap: () => Get.toNamed('/agents'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: FontAwesomeIcons.handHoldingDollar,
                title: 'kasby_loans'.tr,
                subtitle: 'manage_loans'.tr,
                onTap: () => Get.toNamed('/loans'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: Icons.subscriptions_rounded,
                title: 'user_subscriptions'.tr,
                subtitle: 'manage_subscriptions'.tr,
                onTap: () => Get.toNamed('/subscriptions'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: Icons.storefront_rounded,
                title: 'marketplace_management'.tr,
                subtitle: 'manage_marketplace'.tr,
                onTap: () => Get.toNamed('/marketplace'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: FontAwesomeIcons.comments,
                title: 'support_chat'.tr,
                subtitle: 'user_agent_chats'.tr,
                onTap: () => Get.toNamed('/chat-list'),
              ),
              const SizedBox(height: 8),
              if (isSuperAdmin) ...[
                _buildSettingCard(
                  icon: FontAwesomeIcons.wallet,
                  title: 'wallet_management'.tr,
                  subtitle: 'view_user_balances'.tr,
                  onTap: () => Get.toNamed('/wallets'),
                ),
                const SizedBox(height: 8),
              ],
              _buildSettingCard(
                icon: FontAwesomeIcons.chartColumn,
                title: 'reports_revenue'.tr,
                subtitle: 'financial_summary'.tr,
                onTap: () => Get.toNamed('/reports'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: FontAwesomeIcons.userGroup,
                title: 'referral_program'.tr,
                subtitle: 'referral_codes_commissions'.tr,
                onTap: () => Get.toNamed('/referrals'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: FontAwesomeIcons.qrcode,
                title: 'qr_management'.tr,
                subtitle: 'qr_codes_description'.tr,
                onTap: () => Get.toNamed('/qr-management'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: FontAwesomeIcons.clipboardList,
                title: 'audit_log'.tr,
                subtitle: 'audit_log_subtitle'.tr,
                onTap: () => Get.toNamed('/audit-logs'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: FontAwesomeIcons.heartPulse,
                title: 'صحة النظام',
                subtitle: 'مراقبة حالة الخدمات والعمليات المعلقة',
                onTap: () => Get.toNamed('/system-health'),
              ),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: FontAwesomeIcons.idCard,
                title: 'إدارة KYC',
                subtitle: 'التحقق من هوية المستخدمين',
                onTap: () => Get.toNamed('/kyc'),
              ),
              const SizedBox(height: 8),
              if (isSuperAdmin) ...[
                _buildSettingCard(
                  icon: FontAwesomeIcons.userGear,
                  title: 'إدارة الموظفين',
                  subtitle: 'إدارة صلاحيات المسؤولين والأدوار',
                  onTap: () => Get.toNamed('/staff'),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 24),

              // Notifications Section (admin-only)
              if (canManage) ...[
                Text(
                  'notifications_section'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  icon: FontAwesomeIcons.bellConcierge,
                  title: 'send_notification'.tr,
                  subtitle: 'send_notification_all'.tr,
                  onTap: () => Get.toNamed('/add-notification'),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: FontAwesomeIcons.gift,
                  title: 'rewards_points'.tr,
                  subtitle: 'manage_rewards'.tr,
                  onTap: () => Get.toNamed('/rewards'),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: FontAwesomeIcons.fileLines,
                  title: 'قوالب الإشعارات',
                  subtitle: 'إنشاء وإدارة قوالب الإشعارات المحفوظة',
                  onTap: () => Get.toNamed('/notification-templates'),
                ),
                const SizedBox(height: 24),
              ],

              // App Configuration Section (admin-only)
              if (canManage) ...[
                Text(
                  'app_settings_section'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  icon: FontAwesomeIcons.rectangleAd,
                  title: 'ads_management'.tr,
                  subtitle: 'manage_ads'.tr,
                  onTap: () => Get.to(() => const AdsScreen()),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: FontAwesomeIcons.fileContract,
                  title: 'terms_conditions'.tr,
                  subtitle: 'update_terms'.tr,
                  onTap: () => Get.toNamed('/terms'),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: FontAwesomeIcons.circleQuestion,
                  title: 'faq_title'.tr,
                  subtitle: 'manage_faq'.tr,
                  onTap: () => Get.toNamed('/faq'),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: FontAwesomeIcons.wrench,
                  title: 'maintenance_mode'.tr,
                  subtitle: 'toggle_maintenance'.tr,
                  onTap: () => Get.toNamed('/maintenance'),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: FontAwesomeIcons.percent,
                  title: 'fees_commissions'.tr,
                  subtitle: 'manage_fees'.tr,
                  onTap: () => Get.to(() => const FeeSettingsScreen()),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: FontAwesomeIcons.coins,
                  title: 'currencies'.tr,
                  subtitle: 'manage_currencies'.tr,
                  onTap: () => Get.to(() => const CurrencySettingsScreen()),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: FontAwesomeIcons.sliders,
                  title: 'transaction_limits'.tr,
                  subtitle: 'set_limits'.tr,
                  onTap: () => Get.to(() => const TransactionLimitsScreen()),
                ),
                const SizedBox(height: 24),
              ],

              // Account Section
              Text(
                'account_section'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: FontAwesomeIcons.userPen,
                title: 'profile'.tr,
                subtitle: 'edit_profile'.tr,
                onTap: () => Get.toNamed('/profile'),
              ),
              const SizedBox(height: 8),
              Obx(
                () => _buildSettingCard(
                  icon: themeController.isDarkMode.value
                      ? FontAwesomeIcons.moon
                      : FontAwesomeIcons.sun,
                  title: 'appearance'.tr,
                  subtitle: themeController.isDarkMode.value
                      ? 'dark_mode'.tr
                      : 'light_mode'.tr,
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
                title: 'logout'.tr,
                subtitle: 'logout_from_account'.tr,
                onTap: () => _showLogoutDialog(context, authController),
                iconColor: KasbyColors.error,
              ),
            ],
          );
        }),
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
                      authController.userRole.value == 'Admin' ? 'system_admin'.tr : authController.userRole.value,
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
        title: Text('logout'.tr),
        content: Text('logout_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            child: Text(
              'logout'.tr,
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
