import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../users/models/user_model.dart';
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
  final profile = Rxn<User>();
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
          await _fetchFullProfile(session.user.id);
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
  /// Uses the professional `profiles.role` column as the Single Source of Truth.
  Future<bool> _checkIsAdmin() async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return false;

    debugPrint('[AuthController] _checkIsAdmin — userId: $userId');

    try {
      // 1. Direct query to profiles table for the 'role' column (Most reliable)
      final response = await SupabaseService.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = response['role'] as String?;
      debugPrint('[AuthController] _checkIsAdmin — DB role result: $role');

      if (role == 'admin') return true;
    } catch (e) {
      debugPrint(
        '[AuthController] _checkIsAdmin — DB query failed: $e. Using fallback...',
      );

      // 2. Fallback: Try RPC is_admin() (Checks role internally)
      try {
        final rpcResult = await SupabaseService.client.rpc('is_admin');
        if (rpcResult == true) return true;
      } catch (rpcErr) {
        debugPrint('[AuthController] _checkIsAdmin — RPC failed: $rpcErr');
      }

      // 3. Last resort: Check appMetadata (Legacy compatibility)
      final user = SupabaseService.auth.currentUser;
      final appAdmin = user?.appMetadata['is_admin'];
      if (appAdmin == true || appAdmin == 'true') return true;
    }

    return false;
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
    debugPrint('[AuthController] ▶ login() called — email: $email');
    isLoading.value = true;

    try {
      debugPrint('[AuthController] ℹ Step 1: signInWithPassword...');
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthController] ✓ signInWithPassword completed');
      debugPrint(
        '[AuthController] ℹ Session: ${response.session != null ? "EXISTS" : "NULL"}',
      );
      debugPrint('[AuthController] ℹ User ID: ${response.user?.id}');
      debugPrint(
        '[AuthController] ℹ User metadata: ${response.user?.userMetadata}',
      );
      debugPrint(
        '[AuthController] ℹ App metadata: ${response.user?.appMetadata}',
      );

      if (response.session == null) {
        throw AuthException('لم يتم إنشاء جلسة. حاول مرة أخرى.');
      }

      // 1. Verify admin status via RPC and Metadata
      debugPrint('[AuthController] ℹ Step 2: _checkIsAdmin()...');
      final isAdmin = await _checkIsAdmin();
      debugPrint('[AuthController] ℹ isAdmin result: $isAdmin');
      if (!isAdmin) {
        debugPrint('[AuthController] ✗ NOT an admin — signing out');
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
      if (response.user != null) {
        await _fetchFullProfile(response.user!.id);
      }

      debugPrint(
        '[AuthController] ✓ Login SUCCESS — userName: ${userName.value}',
      );
      isLoading.value = false;
      return true;
    } on AuthException catch (e) {
      debugPrint('[AuthController] ✗ AuthException: ${e.message}');
      debugPrint(
        '[AuthController] ✗ AuthException statusCode: ${e.statusCode}',
      );
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
      debugPrint('[AuthController] ✗ UNEXPECTED ERROR: $e');
      debugPrint('[AuthController] StackTrace: $stackTrace');
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

  /// Fetch complete profile from Supabase
  Future<void> _fetchFullProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select('*, wallets!wallets_user_id_fkey(*)')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        profile.value = User.fromSupabase(response);
        userName.value = profile.value?.name ?? userName.value;
        userRole.value = profile.value?.role ?? userRole.value;
        debugPrint('[AuthController] ✓ Full profile fetched: ${profile.value?.name}');
      }
    } catch (e) {
      debugPrint('[AuthController] ⚠ Error fetching full profile: $e');
    }
  }

  /// Public method to refresh profile
  Future<void> refreshProfile() async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId != null) {
      await _fetchFullProfile(userId);
    }
  }

  /// Update just the avatar URL in the profile
  Future<void> updateAvatar(String url) async {
    final p = profile.value;
    if (p != null) {
      profile.value = p.copyWith(avatarUrl: url);
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
