import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';

/// Authentication Controller
/// Manages login via Supabase Auth and session state
class AuthController extends GetxController {
  // Observable state
  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final isCheckingAuth = true.obs;
  final userRole = ''.obs;
  final userName = ''.obs;
  final isBiometricAvailable = false.obs;
  final rememberMe = false.obs;
  final savedEmail = ''.obs;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
    _loadRememberedCredentials();
  }

  /// Check if user is already logged in via Supabase session
  Future<void> _checkLoginStatus() async {
    try {
      final session = SupabaseService.auth.currentSession;
      if (session != null) {
        // Verify admin status
        final isAdmin = await _checkIsAdmin();
        if (isAdmin) {
          isLoggedIn.value = true;
          userRole.value = 'Admin';
          userName.value = session.user.userMetadata?['full_name'] ?? 'المدير';
        } else {
          // Not an admin — sign out
          await SupabaseService.auth.signOut();
        }
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuthController',
        method: '_checkLoginStatus',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      isCheckingAuth.value = false;
    }

    // Check biometric availability
    try {
      isBiometricAvailable.value =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {}
  }

  /// Check if current user is an admin
  Future<bool> _checkIsAdmin() async {
    try {
      final response = await SupabaseService.client.rpc('is_admin');
      return response == true;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuthController',
        method: '_checkIsAdmin',
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback: check user metadata
      final user = SupabaseService.auth.currentUser;
      if (user != null) {
        final isAdmin = user.appMetadata['is_admin'];
        return isAdmin == true || isAdmin == 'true';
      }
      return false;
    }
  }

  /// Load remembered credentials from SharedPreferences
  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    rememberMe.value = prefs.getBool('remember_me') ?? false;
    if (rememberMe.value) {
      savedEmail.value = prefs.getString('saved_email') ?? '';
    }
  }

  /// Update remember me state
  Future<void> toggleRememberMe(bool value) async {
    rememberMe.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
    if (!value) {
      await prefs.remove('saved_email');
    }
  }

  /// Authenticate with Biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'يرجى المصادقة للدخول إلى لوحة التحكم',
      );

      if (authenticated) {
        final session = SupabaseService.auth.currentSession;
        if (session != null) {
          isLoggedIn.value = true;
          return true;
        }
      }
      return false;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuthController',
        method: 'authenticateWithBiometrics',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Login with email and password via Supabase Auth
  Future<bool> login(String email, String password) async {
    isLoading.value = true;

    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw AuthException('لم يتم إنشاء جلسة. حاول مرة أخرى.');
      }

      // 1. Verify admin status via RPC and Metadata
      final isAdmin = await _checkIsAdmin();
      if (!isAdmin) {
        await SupabaseService.auth.signOut();
        throw AuthException(
          'هذا الحساب ليس حساب مدير. لا يمكنك الوصول إلى لوحة التحكم.',
        );
      }

      // 2. Clear sensitive state and set local status
      if (rememberMe.value) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', email);
        savedEmail.value = email;
      }

      isLoggedIn.value = true;
      userRole.value = 'Admin';
      userName.value = response.user?.userMetadata?['full_name'] ?? 'المدير';

      isLoading.value = false;
      return true;
    } on AuthException catch (e) {
      isLoading.value = false;
      String message = e.message;
      if (message.contains('Invalid login credentials')) {
        message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
      Get.snackbar(
        'خطأ في الدخول',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuthController',
        method: 'login',
        error: e,
        stackTrace: stackTrace,
      );
      isLoading.value = false;
      Get.snackbar(
        'خطأ غير متوقع',
        'حدث خطأ أثناء الاتصال بالخادم',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await SupabaseService.auth.signOut();
    } catch (_) {}

    isLoggedIn.value = false;
    userRole.value = '';
    Get.offAllNamed('/login');
  }

  /// Signup with email, password, and additional metadata
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    isLoading.value = true;
    try {
      // We set is_admin: true in user metadata.
      // The database trigger 'handle_new_user' in kasby.sql will pick this up.
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'is_admin': true, // This app is only for admins
        },
      );

      if (response.user == null) {
        throw AuthException('فشل إنشاء المستخدم');
      }

      isLoading.value = false;
      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء حساب المدير. يرجى تسجيل الدخول الآن.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.success,
        colorText: Colors.white,
      );
      return true;
    } on AuthApiException catch (e) {
      isLoading.value = false;
      String message = e.message;
      if (e.code == 'user_already_exists') {
        message = 'هذا البريد الإلكتروني مسجل بالفعل. حاول تسجيل الدخول.';
      }
      Get.snackbar(
        'خطأ في التسجيل',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuthController',
        method: 'signUp',
        error: e,
        stackTrace: stackTrace,
      );
      isLoading.value = false;
      Get.snackbar(
        'خطأ',
        'حدث خطأ غير متوقع أثناء التسجيل',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Forgot password — sends reset email via Supabase
  Future<void> forgotPassword(String email) async {
    isLoading.value = true;
    try {
      await SupabaseService.auth.resetPasswordForEmail(email);
      Get.snackbar(
        'تم الإرسال',
        'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuthController',
        method: 'forgotPassword',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إرسال رابط إعادة التعيين',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }
}
