import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/kasby_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/users/screens/user_list_screen.dart';
import 'features/investments/screens/investment_plans_screen.dart';
import 'features/investments/screens/user_investments_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/agents/screens/agents_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/gamification/screens/rewards_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/admin_management_screen.dart';
import 'features/settings/screens/terms_screen.dart';
import 'features/settings/screens/faq_screen.dart';
import 'features/settings/screens/maintenance_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'features/dashboard/screens/audit_logs_screen.dart';
import 'core/controllers/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Date Formatting
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en', null);

  // Initialize GetX Controllers
  Get.put(AuthController());
  Get.put(ThemeController());

  runApp(const KasbyAdminApp());
}

class KasbyAdminApp extends StatelessWidget {
  const KasbyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kasby Panel',
      debugShowCheckedModeBanner: false,
      theme: KasbyTheme.lightTheme,
      darkTheme: KasbyTheme.darkTheme,
      themeMode: Get.find<ThemeController>().isDarkMode.value
          ? ThemeMode.dark
          : ThemeMode.light,

      // RTL Support
      locale: const Locale('ar', 'SA'),
      fallbackLocale: const Locale('en', 'US'),

      // Routes
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/otp', page: () => const OtpScreen()),
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        GetPage(name: '/users', page: () => const UserListScreen()),
        GetPage(
          name: '/investment-plans',
          page: () => const InvestmentPlansScreen(),
        ),
        GetPage(
          name: '/user-investments',
          page: () => const UserInvestmentsScreen(),
        ),
        GetPage(name: '/transactions', page: () => const TransactionsScreen()),
        GetPage(name: '/agents', page: () => const AgentsScreen()),
        GetPage(
          name: '/notifications',
          page: () => const NotificationsScreen(),
        ),
        GetPage(name: '/rewards', page: () => const RewardsScreen()),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
        GetPage(
          name: '/admin-management',
          page: () => const AdminManagementScreen(),
        ),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/audit-logs', page: () => const AuditLogsScreen()),
        GetPage(name: '/terms', page: () => const TermsScreen()),
        GetPage(name: '/faq', page: () => const FaqScreen()),
        GetPage(name: '/maintenance', page: () => const MaintenanceScreen()),
      ],

      // Check if user is already logged in
      home: const AuthWrapper(),
    );
  }
}

/// Auth Wrapper to check login status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      if (authController.isLoggedIn.value) {
        return const DashboardScreen();
      } else {
        return const LoginScreen();
      }
    });
  }
}
