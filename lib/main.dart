import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'core/services/admin_notification_navigation_service.dart';
import 'core/localization/admin_translations.dart';
import 'core/services/presence_service.dart';
import 'core/services/network_service.dart';
import 'core/widgets/connectivity_banner.dart';
import 'features/ksp_analytics/controllers/ksp_analytics_controller.dart';
import 'features/ksp_analytics/screens/ksp_analytics_screen.dart';
import 'features/referrals/screens/referral_management_screen.dart';
import 'features/wallets/screens/wallet_management_screen.dart';
import 'features/reports/screens/revenue_dashboard_screen.dart';
// import 'features/staff/screens/role_management_screen.dart';
import 'features/staff/controllers/staff_controller.dart';
import 'features/notifications/controllers/notification_template_controller.dart';
import 'features/notifications/screens/notification_templates_screen.dart';
import 'features/qr/screens/qr_management_screen.dart';
import 'features/monitoring/screens/system_health_screen.dart';
import 'features/search/screens/admin_search_screen.dart';
import 'features/approvals/screens/approval_queue_screen.dart';
import 'core/services/permission_service.dart';
import 'core/services/app_logger_service.dart';
import 'core/services/crash_reporting_service.dart';
import 'features/audit/screens/audit_log_screen.dart';
import 'features/marketplace/screens/marketplace_dashboard_screen.dart';
import 'features/marketplace/controllers/marketplace_admin_controller.dart';


Future<void> main() async {
  CrashReportingService.runAppWithCrashGuards(_bootstrap);
}

Future<void> _bootstrap() async {
  final startupStopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  AppLoggerService.debugTrace(
    className: 'main',
    method: 'startup',
    feature: 'Startup',
    status: 'INFO',
    message: 'Admin app startup initiated',
  );

  await dotenv.load(fileName: '.env');
  await AppLoggerService.init();
  AppLoggerService.debugTrace(
    className: 'main',
    method: 'loadEnv',
    feature: 'Startup',
    status: 'SUCCESS',
  );

  // Initialize Services
  await SupabaseService.init();

  // Initialize Date Formatting
  await initializeDateFormatting('ar', null);
  AppLoggerService.debugTrace(
    className: 'main',
    method: 'initDateFormatting',
    feature: 'Startup',
    status: 'SUCCESS',
  );

  // --- BEGIN GENIUS NOTIFICATION SYSTEM ---
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    await CrashReportingService.initialize(firebaseReady: true);
    AppLoggerService.debugTrace(
      className: 'main',
      method: 'initFirebase',
      feature: 'Startup',
      status: 'SUCCESS',
      durationMs: startupStopwatch.elapsedMilliseconds,
    );

    // Request high importance for Firebase (active state)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await AdminNotificationNavigationService.navigateFromPayload(
        initialMessage.data,
        fromUserTap: true,
      );
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AdminNotificationNavigationService.navigateFromPayload(
        message.data,
        fromUserTap: true,
      );
    });
  } catch (e, st) {
    AppLoggerService.debugTrace(
      className: 'main',
      method: 'initFirebase',
      feature: 'Startup',
      status: 'FAILED',
      error: e,
      stackTrace: st,
      message: 'App will still function using Supabase Realtime listeners',
    );
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

  // Local notification tap routing is initialized in AdminListenerService.
  // --- END GENIUS NOTIFICATION SYSTEM ---

  AppLoggerService.debugTrace(
    className: 'main',
    method: 'initDependencyInjection',
    feature: 'Startup',
    status: 'INFO',
    message: 'Registering GetX services and controllers',
  );

  // 1. Core Services & Auth (Dependencies for most things)
  Get.put(AuthController());
  Get.put(AudioService());
  Get.put(ThemeController());
  Get.put(SettingsController());

  // 2. Real-time Infrastructure (Async init)
  await Get.putAsync(() => NetworkService().init());
  await Get.putAsync(() => PresenceService().init());
  await Get.putAsync(() => AdminListenerService().init());
  await Get.putAsync(() => PermissionService().init());

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
  Get.lazyPut(() => StaffController(), fenix: true);
  Get.lazyPut(() => NotificationTemplateController(), fenix: true);
  Get.lazyPut(() => MarketplaceAdminController(), fenix: true);

  AppLoggerService.debugTrace(
    className: 'main',
    method: 'runApp',
    feature: 'Startup',
    status: 'SUCCESS',
    durationMs: startupStopwatch.elapsedMilliseconds,
  );

  runApp(const KasbyAdminApp());
}

Widget _loggedAdminScreen(String screenName, Widget child) {
  return AdminTrackedScreen(screenName: screenName, child: child);
}

GetPage _adminRoute(
  String name,
  String screen,
  Widget Function() builder, {
  Bindings? binding,
}) {
  return GetPage(
    name: name,
    page: () => _loggedAdminScreen(screen, builder()),
    binding: binding,
  );
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
      routingCallback: AppLoggerService.logRoute,

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
        _adminRoute('/login', 'LoginScreen', () => const LoginScreen()),
        _adminRoute('/otp', 'OtpScreen', () => const OtpScreen()),
        _adminRoute(
          '/forgot-password',
          'ForgotPasswordScreen',
          () => const ForgotPasswordScreen(),
        ),
        _adminRoute('/main', 'MainWrapper', () => const MainWrapper()),
        _adminRoute('/users', 'UserListScreen', () => const UserListScreen()),
        _adminRoute(
          '/investment-plans',
          'InvestmentPlansScreen',
          () => const InvestmentPlansScreen(),
        ),
        _adminRoute(
          '/user-investments',
          'UserInvestmentsScreen',
          () => const UserInvestmentsScreen(),
        ),
        _adminRoute(
          '/transactions',
          'TransactionsScreen',
          () => TransactionsScreen(
            initialIndex: Get.arguments is int ? Get.arguments as int : 0,
          ),
        ),
        _adminRoute('/agents', 'AgentsScreen', () => const AgentsScreen()),
        _adminRoute('/loans', 'LoansScreen', () => const LoansScreen()),
        _adminRoute(
          '/add-notification',
          'NotificationsScreen',
          () => const NotificationsScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => NotificationController());
          }),
        ),
        _adminRoute(
          '/notifications-list',
          'NotificationsListScreen',
          () => const NotificationsListScreen(),
        ),
        _adminRoute('/rewards', 'RewardsScreen', () => const RewardsScreen()),
        _adminRoute('/settings', 'SettingsScreen', () => const SettingsScreen()),
        _adminRoute('/profile', 'ProfileScreen', () => const ProfileScreen()),
        _adminRoute('/terms', 'TermsScreen', () => const TermsScreen()),
        _adminRoute('/faq', 'FaqScreen', () => const FaqScreen()),
        _adminRoute(
          '/maintenance',
          'MaintenanceScreen',
          () => const MaintenanceScreen(),
        ),
        _adminRoute('/chat-list', 'ChatListScreen', () => const ChatListScreen()),
        _adminRoute(
          '/chat-details',
          'ChatDetailsScreen',
          () => const ChatDetailsScreen(),
        ),
        _adminRoute(
          '/agent-details',
          'AgentDetailsScreen',
          () => const AgentDetailsScreen(),
        ),
        _adminRoute(
          '/edit-agent',
          'EditAgentScreen',
          () => const EditAgentScreen(),
        ),
        _adminRoute(
          '/subscriptions',
          'SubscriptionsScreen',
          () => const SubscriptionsScreen(),
        ),
        _adminRoute(
          '/kyc',
          'KycManagementScreen',
          () => const KycManagementScreen(),
        ),
        _adminRoute(
          '/ksp-analytics',
          'KspAnalyticsScreen',
          () => const KspAnalyticsScreen(),
        ),
        _adminRoute(
          '/referrals',
          'ReferralManagementScreen',
          () => const ReferralManagementScreen(),
        ),
        _adminRoute(
          '/wallets',
          'WalletManagementScreen',
          () => const WalletManagementScreen(),
        ),
        _adminRoute(
          '/reports',
          'RevenueDashboardScreen',
          () => const RevenueDashboardScreen(),
        ),
        _adminRoute(
          '/qr-management',
          'QrManagementScreen',
          () => const QrManagementScreen(),
        ),
        _adminRoute(
          '/audit-logs',
          'AuditLogScreen',
          () => const AuditLogScreen(),
        ),
        _adminRoute(
          '/marketplace',
          'MarketplaceDashboardScreen',
          () => const MarketplaceDashboardScreen(),
        ),
        _adminRoute(
          '/admin-search',
          'AdminSearchScreen',
          () => const AdminSearchScreen(),
        ),
        _adminRoute(
          '/approvals',
          'ApprovalQueueScreen',
          () => const ApprovalQueueScreen(),
        ),
        _adminRoute(
          '/system-health',
          'SystemHealthScreen',
          () => const SystemHealthScreen(),
        ),
        // _adminRoute(
        //   '/staff',
        //   'RoleManagementScreen',
        //   () => const RoleManagementScreen(),
        // ),
        _adminRoute(
          '/notification-templates',
          'NotificationTemplatesScreen',
          () => const NotificationTemplatesScreen(),
        ),
      ],

      // Check if user is already logged in
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
        );
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
        AppLoggerService.debugTrace(
          className: 'AuthWrapper',
          method: 'build',
          feature: 'Authentication',
          status: 'INFO',
          message: 'Checking auth session',
        );
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: KasbyColors.primaryGold),
          ),
        );
      }

      if (authController.isLoggedIn.value) {
        AppLoggerService.debugTrace(
          className: 'AuthWrapper',
          method: 'build',
          feature: 'Authentication',
          status: 'SUCCESS',
          message: 'Session restored — navigating to MainWrapper',
        );
        return const MainWrapper(); // Use MainWrapper for proper navigation setup
      } else {
        AppLoggerService.debugTrace(
          className: 'AuthWrapper',
          method: 'build',
          feature: 'Authentication',
          status: 'INFO',
          message: 'No session — showing LoginScreen',
        );
        return const LoginScreen();
      }
    });
  }
}
