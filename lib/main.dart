import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/kasby_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/users/screens/user_list_screen.dart';

void main() {
  // Initialize GetX Controllers
  Get.put(AuthController());

  runApp(const KasbyAdminApp());
}

class KasbyAdminApp extends StatelessWidget {
  const KasbyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kasby Admin',
      debugShowCheckedModeBanner: false,
      theme: KasbyTheme.darkTheme,

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
