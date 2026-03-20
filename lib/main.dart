import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/kasby_colors.dart';
import 'core/theme/kasby_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/dashboard/screens/main_wrapper.dart';
import 'features/gamification/screens/rewards_screen.dart';
import 'features/users/screens/user_list_screen.dart';
import 'features/investments/screens/investment_plans_screen.dart';
import 'features/investments/screens/user_investments_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/agents/screens/agents_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/terms_screen.dart';
import 'features/settings/screens/faq_screen.dart';
import 'features/settings/screens/maintenance_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'features/dashboard/screens/audit_logs_screen.dart';
import 'features/dashboard/screens/error_log_screen.dart';
import 'core/controllers/theme_controller.dart';
import 'core/controllers/settings_controller.dart';
import 'features/users/controllers/user_controller.dart';
import 'features/transactions/controllers/transaction_controller.dart';
import 'features/investments/controllers/investment_controller.dart';
import 'features/agents/controllers/agent_controller.dart';
import 'features/dashboard/controllers/main_controller.dart';
import 'features/dashboard/controllers/audit_controller.dart';
import 'features/dashboard/controllers/error_log_controller.dart';
import 'features/chat/controllers/chat_controller.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/chat_details_screen.dart';
import 'features/agents/screens/agent_details_screen.dart';
import 'features/agents/screens/edit_agent_screen.dart';
import 'core/services/audio_service.dart';
import 'features/loans/controllers/loan_controller.dart';
import 'features/loans/screens/loans_screen.dart';
import 'features/settings/controllers/settings_management_controller.dart';
import 'features/gamification/controllers/rewards_controller.dart';
import 'core/services/supabase_service.dart';
import 'core/services/app_logger_service.dart';
import 'features/subscriptions/controllers/subscription_controller.dart';
import 'features/subscriptions/screens/subscriptions_screen.dart';
import 'core/localization/admin_translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // Initialize Services
  await SupabaseService.init();
  await AppLoggerService.init();

  // Initialize Date Formatting
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en', null);

  // Initialize GetX Controllers (Global)
  Get.put(AuthController());
  Get.put(ThemeController());
  Get.put(SettingsController());
  Get.put(SettingsManagementController());
  Get.put(UserController());
  Get.put(TransactionController());
  Get.put(InvestmentController());
  Get.put(AgentController());
  Get.put(LoanController());
  Get.put(MainController());
  Get.put(AuditController());
  Get.put(ErrorLogController());
  Get.put(AudioService());
  Get.put(ChatController());
  Get.put(RewardsController());
  Get.put(SubscriptionController());

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

      // Smooth Navigation
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),

      // RTL Support
      translations: AdminTranslations(),
      locale: const Locale('ar', 'SA'),
      fallbackLocale: const Locale('en', 'US'),

      // Routes (Home handles entry logic)
      home: const AuthWrapper(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/otp', page: () => const OtpScreen()),
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(name: '/dashboard', page: () => const MainWrapper()),
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
        GetPage(name: '/loans', page: () => const LoansScreen()),
        GetPage(
          name: '/notifications',
          page: () => const NotificationsScreen(),
        ),
        GetPage(name: '/rewards', page: () => const RewardsScreen()),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/audit-logs', page: () => const AuditLogsScreen()),
        GetPage(name: '/error-logs', page: () => const ErrorLogScreen()),
        GetPage(name: '/terms', page: () => const TermsScreen()),
        GetPage(name: '/faq', page: () => const FaqScreen()),
        GetPage(name: '/maintenance', page: () => const MaintenanceScreen()),
        GetPage(name: '/chat-list', page: () => const ChatListScreen()),
        GetPage(name: '/chat-details', page: () => const ChatDetailsScreen()),
        GetPage(name: '/agent-details', page: () => const AgentDetailsScreen()),
        GetPage(name: '/edit-agent', page: () => const EditAgentScreen()),
        GetPage(
          name: '/subscriptions',
          page: () => const SubscriptionsScreen(),
        ),
      ],

      // Check if user is already logged in
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
      if (authController.isCheckingAuth.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: KasbyColors.primaryGold),
          ),
        );
      }

      if (authController.isLoggedIn.value) {
        return const MainWrapper(); // Use MainWrapper for proper navigation setup
      } else {
        return const LoginScreen();
      }
    });
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
