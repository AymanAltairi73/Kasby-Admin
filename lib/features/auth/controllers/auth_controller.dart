import 'dart:async';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../users/models/user_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/crash_reporting/crash_breadcrumb.dart';
import '../../../core/services/crash_reporting_service.dart';

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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: 'onInit',
      feature: 'Auth',
      status: 'INFO',
    );
    super.onInit();
    _checkLoginStatus();
    _listenToAuthChanges();
    _loadRememberedCredentials();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: 'onClose',
      feature: 'Auth',
      status: 'INFO',
    );
    _authSubscription?.cancel();
    super.onClose();
  }

  /// Check if user is already logged in via Supabase session
  Future<void> _checkLoginStatus() async {
    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: '_checkLoginStatus',
      feature: 'Auth',
      status: 'INFO',
    );
    try {
      final session = SupabaseService.auth.currentSession;
      if (session != null) {
        final isAdmin = await _checkIsAdmin();
        if (isAdmin) {
          isLoggedIn.value = true;
          userRole.value = 'Admin';
          userName.value = session.user.userMetadata?['full_name'] ?? 'المدير';
          await _fetchFullProfile(session.user.id);
          await _refreshAdminPermissions();
          await CrashReportingService.syncAdminContextFromSession();
        } else {
          await SupabaseService.auth.signOut();
        }
      }
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: '_checkLoginStatus',
        feature: 'Auth',
        status: 'FAILED',
        error: e,
      );
    } finally {
      isCheckingAuth.value = false;
    }

    try {
      isBiometricAvailable.value =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {}
  }

  /// Listen to Supabase auth state changes for real-time session management
  void _listenToAuthChanges() {
    _authSubscription = SupabaseService.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: '_listenToAuthChanges',
        feature: 'Auth',
        status: 'INFO',
        params: {'event': event.name},
      );

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          if (session != null) {
            final isAdmin = await _checkIsAdmin();
            if (isAdmin) {
              isLoggedIn.value = true;
              userRole.value = 'Admin';
              userName.value = session.user.userMetadata?['full_name'] ?? 'المدير';
              await _fetchFullProfile(session.user.id);
              await _refreshAdminPermissions();
              await CrashReportingService.log(CrashBreadcrumb.loginCompleted);
              await CrashReportingService.syncAdminContextFromSession();
            } else {
              AppLoggerService.debugTrace(
                className: 'AuthController',
                method: '_listenToAuthChanges',
                feature: 'Auth',
                status: 'WARNING',
                message: 'Non-admin signed in — enforcing logout',
              );
              await SupabaseService.auth.signOut();
            }
          }
          break;

        case AuthChangeEvent.signedOut:
          isLoggedIn.value = false;
          userRole.value = '';
          userName.value = '';
          profile.value = null;
          unawaited(CrashReportingService.log(CrashBreadcrumb.logout));
          unawaited(CrashReportingService.clearUser());
          break;

        case AuthChangeEvent.userUpdated:
          if (session != null) {
            await _fetchFullProfile(session.user.id);
          }
          break;

        default:
          break;
      }
    });
  }

  /// Check if current user is an admin
  Future<bool> _checkIsAdmin() async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return false;

    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: '_checkIsAdmin',
      feature: 'Auth',
      status: 'INFO',
      params: {'userId': userId},
    );

    int retryCount = 0;
    while (retryCount < 2) {
      try {
        final response = await SupabaseService.client
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();

        final role = response['role'] as String?;
        AppLoggerService.debugTrace(
          className: 'AuthController',
          method: '_checkIsAdmin',
          feature: 'Auth',
          status: 'SUCCESS',
          params: {'role': role ?? 'unknown'},
        );

        if (role == 'admin') return true;
        break;
      } catch (e) {
        retryCount++;
        AppLoggerService.debugTrace(
          className: 'AuthController',
          method: '_checkIsAdmin',
          feature: 'Auth',
          status: 'WARNING',
          params: {'attempt': retryCount},
          error: e,
        );

        if (retryCount < 2) {
          await Future.delayed(const Duration(milliseconds: 1500));
        } else {
          AppLoggerService.debugTrace(
            className: 'AuthController',
            method: '_checkIsAdmin',
            feature: 'Auth',
            status: 'WARNING',
            message: 'DB query failed — using metadata fallback',
          );

          final user = SupabaseService.auth.currentUser;
          final appAdmin = user?.appMetadata['is_admin'];
          if (appAdmin == true || appAdmin == 'true') return true;
        }
      }
    }

    return false;
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    rememberMe.value = prefs.getBool('remember_me') ?? false;
    if (rememberMe.value) {
      savedEmail.value = prefs.getString('saved_email') ?? '';
    }
  }

  Future<void> toggleRememberMe(bool value) async {
    rememberMe.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
    if (!value) {
      await prefs.remove('saved_email');
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: 'authenticateWithBiometrics',
      feature: 'Auth',
      status: 'INFO',
    );
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'يرجى المصادقة للدخول إلى لوحة التحكم',
      );

      if (authenticated) {
        final session = SupabaseService.auth.currentSession;
        if (session != null) {
          final isAdmin = await _checkIsAdmin();
          if (isAdmin) {
            isLoggedIn.value = true;
            await _refreshAdminPermissions();
            return true;
          }
          await SupabaseService.auth.signOut();
        }
      }
      return false;
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: 'authenticateWithBiometrics',
        feature: 'Auth',
        status: 'FAILED',
        error: e,
      );
      return false;
    }
  }

  /// Login with email and password via Supabase Auth
  Future<bool> login(String email, String password) async {
    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: 'login',
      feature: 'Auth',
      status: 'INFO',
      params: {'email': email},
    );
    isLoading.value = true;

    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: 'login',
        feature: 'Auth',
        status: 'INFO',
        message: 'signInWithPassword completed',
        params: {
          'hasSession': response.session != null,
          'userId': response.user?.id ?? '',
        },
      );

      if (response.session == null) {
        throw AuthException('لم يتم إنشاء جلسة. حاول مرة أخرى.');
      }

      final isAdmin = await _checkIsAdmin();
      if (!isAdmin) {
        AppLoggerService.debugTrace(
          className: 'AuthController',
          method: 'login',
          feature: 'Auth',
          status: 'FAILED',
          message: 'NOT an admin — signing out',
        );
        await SupabaseService.auth.signOut();
        throw AuthException(
          'هذا الحساب ليس حساب مدير. لا يمكنك الوصول إلى لوحة التحكم.',
        );
      }

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

      await _refreshAdminPermissions();

      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: 'login',
        feature: 'Auth',
        status: 'SUCCESS',
        params: {'userName': userName.value},
      );
      isLoading.value = false;
      return true;
    } on AuthException catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: 'login',
        feature: 'Auth',
        status: 'FAILED',
        params: {'statusCode': e.statusCode ?? 0},
        error: e.message,
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
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: 'login',
        feature: 'Auth',
        status: 'FAILED',
        error: e,
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
        AppLoggerService.debugTrace(
          className: 'AuthController',
          method: '_fetchFullProfile',
          feature: 'Auth',
          status: 'SUCCESS',
          params: {'name': profile.value?.name ?? ''},
        );
      }
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: '_fetchFullProfile',
        feature: 'Auth',
        status: 'FAILED',
        error: e,
      );
    }
  }

  Future<void> refreshProfile() async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId != null) {
      await _fetchFullProfile(userId);
    }
  }

  Future<void> updateAvatar(String url) async {
    final p = profile.value;
    if (p != null) {
      profile.value = p.copyWith(avatarUrl: url);
    }
  }

  Future<void> _refreshAdminPermissions() async {
    try {
      if (Get.isRegistered<PermissionService>()) {
        await PermissionService.to.refreshPrivileges();
      }
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: '_refreshAdminPermissions',
        feature: 'Auth',
        status: 'FAILED',
        error: e,
      );
    }
  }

  Future<void> logout() async {
    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: 'logout',
      feature: 'Auth',
      status: 'INFO',
    );
    try {
      await SupabaseService.auth.signOut();
    } catch (_) {}

    isLoggedIn.value = false;
    userRole.value = '';
    Get.offAllNamed('/login');
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: 'signUp',
      feature: 'Auth',
      status: 'WARNING',
      message: 'Admin self-registration disabled',
    );
    Get.snackbar(
      'غير متاح',
      'إنشاء حساب المدير معطل. يرجى التواصل مع مسؤول النظام.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  /// Verify OTP code against Supabase Auth
  Future<bool> verifyOtp(String otpCode, {String? email}) async {
    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: 'verifyOtp',
      feature: 'Auth',
      status: 'INFO',
    );
    isLoading.value = true;

    try {
      final userEmail = email ?? SupabaseService.auth.currentUser?.email;
      if (userEmail == null || userEmail.isEmpty) {
        throw AuthException('لا يوجد بريد إلكتروني مرتبط بالجلسة.');
      }

      final response = await SupabaseService.auth.verifyOTP(
        email: userEmail,
        token: otpCode,
        type: OtpType.email,
      );

      if (response.session != null) {
        final isAdmin = await _checkIsAdmin();
        if (!isAdmin) {
          await SupabaseService.auth.signOut();
          throw AuthException('هذا الحساب ليس حساب مدير.');
        }

        isLoggedIn.value = true;
        userRole.value = 'Admin';
        userName.value =
            response.user?.userMetadata?['full_name'] ?? 'المدير';
        if (response.user != null) {
          await _fetchFullProfile(response.user!.id);
        }
        await _refreshAdminPermissions();

        AppLoggerService.debugTrace(
          className: 'AuthController',
          method: 'verifyOtp',
          feature: 'Auth',
          status: 'SUCCESS',
        );
        isLoading.value = false;
        return true;
      }

      throw AuthException('رمز التحقق غير صالح أو منتهي الصلاحية.');
    } on AuthException catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: 'verifyOtp',
        feature: 'Auth',
        status: 'FAILED',
        error: e.message,
      );
      isLoading.value = false;
      Get.snackbar(
        'خطأ في التحقق',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: 'verifyOtp',
        feature: 'Auth',
        status: 'FAILED',
        error: e,
      );
      isLoading.value = false;
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء التحقق من الرمز',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> forgotPassword(String email) async {
    AppLoggerService.debugTrace(
      className: 'AuthController',
      method: 'forgotPassword',
      feature: 'Auth',
      status: 'INFO',
      params: {'email': email},
    );
    isLoading.value = true;
    try {
      await SupabaseService.auth.resetPasswordForEmail(email);
      Get.snackbar(
        'تم الإرسال',
        'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AuthController',
        method: 'forgotPassword',
        feature: 'Auth',
        status: 'FAILED',
        error: e,
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
