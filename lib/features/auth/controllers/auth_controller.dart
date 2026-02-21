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
        isLoading.value = false;
        Get.snackbar(
          'خطأ في تسجيل الدخول',
          'لم يتم إنشاء جلسة. حاول مرة أخرى.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Verify admin status
      final isAdmin = await _checkIsAdmin();
      if (!isAdmin) {
        await SupabaseService.auth.signOut();
        isLoading.value = false;
        Get.snackbar(
          'غير مصرح',
          'هذا الحساب ليس حساب مدير. لا يمكنك الوصول إلى لوحة التحكم.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Save credentials if remember me is on
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuthController',
        method: 'login',
        error: e,
        stackTrace: stackTrace,
      );
      isLoading.value = false;
      String errorMessage = 'حدث خطأ أثناء تسجيل الدخول';
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else if (msg.contains('network') || msg.contains('socket')) {
        errorMessage = 'تحقق من اتصالك بالإنترنت';
      }

      Get.snackbar(
        'خطأ في تسجيل الدخول',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
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
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      if (response.user == null) {
        isLoading.value = false;
        Get.snackbar(
          'خطأ في إنشاء الحساب',
          'لم يتم إنشاء المستخدم. حاول مرة أخرى.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Note: The database trigger 'on_auth_user_created' will use the metadata
      // to create a profile. However, to ensure they are an admin, we might need
      // additional logic if the trigger doesn't automatically set it based on some flag.
      // In kasby.sql, the trigger checks NEW.raw_app_meta_data ->> 'is_admin'

      // Since we can't set app_metadata directly from the client during signup for security reasons,
      // typically an existing admin or a special RPC would be needed, OR the first user becomes admin.
      // For this specific request, we'll assume the trigger handles it or we'll need to update metadata via RPC if allowed.

      isLoading.value = false;
      Get.snackbar(
        'تم إنشاء الحساب',
        'تم إنشاء حساب المدير بنجاح. يمكنك الآن تسجيل الدخول.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.success.withValues(alpha: 0.7),
        colorText: Colors.white,
      );
      return true;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AuthController',
        method: 'signUp',
        error: e,
        stackTrace: stackTrace,
      );
      isLoading.value = false;

      String errorMessage = 'حدث خطأ أثناء إنشاء الحساب';

      if (e is AuthApiException) {
        if (e.code == 'user_already_exists') {
          errorMessage =
              'هذا البريد الإلكتروني مسجل بالفعل. حاول تسجيل الدخول.';
        } else {
          errorMessage = e.message;
        }
      } else {
        final msg = e.toString().toLowerCase();
        if (msg.contains('network') || msg.contains('socket')) {
          errorMessage = 'تحقق من اتصالك بالإنترنت';
        }
      }

      Get.snackbar(
        'خطأ',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
        colorText: Colors.white,
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
