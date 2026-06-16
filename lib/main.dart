import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'features/notifications/screens/notifications_list_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/terms_screen.dart';
import 'features/settings/screens/faq_screen.dart';
import 'features/settings/screens/maintenance_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'core/controllers/theme_controller.dart';
import 'core/controllers/settings_controller.dart';
import 'features/users/controllers/user_controller.dart';
import 'features/transactions/controllers/transaction_controller.dart';
import 'features/investments/controllers/investment_controller.dart';
import 'features/agents/controllers/agent_controller.dart';
import 'features/dashboard/controllers/main_controller.dart';
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
import 'features/subscriptions/controllers/subscription_controller.dart';
import 'features/subscriptions/screens/subscriptions_screen.dart';
import 'features/kyc/screens/kyc_management_screen.dart';
import 'features/notifications/controllers/notification_controller.dart';
import 'core/services/admin_listener_service.dart';
import 'core/localization/admin_translations.dart';
import 'core/services/presence_service.dart';
import 'core/services/network_service.dart';
import 'core/widgets/connectivity_banner.dart';
import 'features/ksp_analytics/controllers/ksp_analytics_controller.dart';
import 'features/ksp_analytics/screens/ksp_analytics_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // Initialize Services
  await SupabaseService.init();

  // Initialize Date Formatting
  await initializeDateFormatting('ar', null);

  // --- BEGIN GENIUS NOTIFICATION SYSTEM ---
  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Request high importance for Firebase (active state)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint('[GENIUS] Firebase not initialized or configured: $e');
    // App will still function using Supabase Realtime listeners
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('notification'),
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // --- END GENIUS NOTIFICATION SYSTEM ---

  // 1. Core Services & Auth (Dependencies for most things)
  Get.put(AuthController());
  Get.put(AudioService());
  Get.put(ThemeController());
  Get.put(SettingsController());

  // 2. Real-time Infrastructure (Async init)
  await Get.putAsync(() => NetworkService().init());
  await Get.putAsync(() => PresenceService().init());
  await Get.putAsync(() => AdminListenerService().init());

  // 3. Subject-Matter Controllers (Lazy Load on Demand)
  Get.lazyPut(() => SettingsManagementController(), fenix: true);
  Get.lazyPut(() => UserController(), fenix: true);
  Get.lazyPut(() => TransactionController(), fenix: true);
  Get.lazyPut(() => InvestmentController(), fenix: true);
  Get.lazyPut(() => AgentController(), fenix: true);
  Get.lazyPut(() => LoanController(), fenix: true);
  Get.lazyPut(() => MainController(), fenix: true);
  Get.lazyPut(() => ChatController(), fenix: true);
  Get.lazyPut(() => RewardsController(), fenix: true);
  Get.lazyPut(() => SubscriptionController(), fenix: true);
  Get.lazyPut(() => NotificationController(), fenix: true);
  Get.lazyPut(() => KspAnalyticsController(), fenix: true);

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
        GetPage(name: '/main', page: () => const MainWrapper()),
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
          name: '/add-notification',
          page: () => const NotificationsScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => NotificationController());
          }),
        ),
        GetPage(
          name: '/notifications-list',
          page: () => const NotificationsListScreen(),
        ),
        GetPage(name: '/rewards', page: () => const RewardsScreen()),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
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
        GetPage(
          name: '/kyc',
          page: () => const KycManagementScreen(),
        ),
        GetPage(
          name: '/ksp-analytics',
          page: () => const KspAnalyticsScreen(),
        ),
      ],

      // Check if user is already logged in
      builder: (context, child) {
        return ConnectivityBanner(child: child ?? const SizedBox.shrink());
      },
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
