import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

/// Authentication Controller
/// Manages login, OTP verification, and session state
class AuthController extends GetxController {
  // Observable state
  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final userRole = ''.obs; // Admin
  final generatedOtp = ''.obs;
  final isBiometricAvailable = false.obs;
  final rememberMe = false.obs;
  final savedUsername = ''.obs;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
    _loadRememberedCredentials();
  }

  /// Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final role = prefs.getString('user_role');

    if (token != null && token.isNotEmpty) {
      isLoggedIn.value = true;
      userRole.value = role ?? 'Admin';
    }

    // Check biometric availability
    isBiometricAvailable.value =
        await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();
  }

  /// Load remembered credentials from SharedPreferences
  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    rememberMe.value = prefs.getBool('remember_me') ?? false;
    if (rememberMe.value) {
      savedUsername.value = prefs.getString('saved_username') ?? '';
    }
  }

  /// Update remember me state
  Future<void> toggleRememberMe(bool value) async {
    rememberMe.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
    if (!value) {
      await prefs.remove('saved_username');
    }
  }

  /// Authenticate with Biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'يرجى المصادقة للدخول إلى لوحة التحكم',
      );

      if (authenticated) {
        // Auto-login if previously logged in (simplified for demo)
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          isLoggedIn.value = true;
          return true;
        }
      }
      return false;
    } catch (e) {
      // debugPrint('Biometric Error: $e');
      return false;
    }
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    isLoading.value = true;

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock authentication
    if (username == 'admin' && password == 'admin123') {
      // Save credentials if remember me is on
      if (rememberMe.value) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_username', username);
        savedUsername.value = username;
      }

      // Generate OTP
      generatedOtp.value = _generateOtp();
      isLoading.value = false;
      return true;
    } else {
      isLoading.value = false;
      Get.snackbar(
        'خطأ في تسجيل الدخول',
        'اسم المستخدم أو كلمة المرور غير صحيحة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp(String enteredOtp) async {
    isLoading.value = true;

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (enteredOtp == generatedOtp.value) {
      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'auth_token',
        'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      await prefs.setString('user_role', 'Admin');

      isLoggedIn.value = true;
      userRole.value = 'Admin';
      isLoading.value = false;
      return true;
    } else {
      isLoading.value = false;
      Get.snackbar(
        'خطأ في التحقق',
        'رمز التحقق غير صحيح',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Generate random 6-digit OTP
  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return random.toString();
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isLoggedIn.value = false;
    userRole.value = '';
    Get.offAllNamed('/login');
  }

  /// Forgot password (mock)
  Future<void> forgotPassword(String email) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2));
    isLoading.value = false;

    Get.snackbar(
      'تم الإرسال',
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
