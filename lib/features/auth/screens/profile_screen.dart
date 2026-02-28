import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../controllers/auth_controller.dart';

/// Profile Screen — fetches admin data from Supabase (admin_profiles + auth.users)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authController = Get.find<AuthController>();

  // Controllers for editable fields
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  // Admin profile data (read-only display)
  String _role = '';
  String _lastLoginAt = '';
  bool _isActive = true;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    debugPrint('[ProfileScreen] ▶ Screen initialized');
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    _loadAdminProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Load admin profile from Supabase
  Future<void> _loadAdminProfile() async {
    debugPrint('[ProfileScreen] ▶ Loading admin profile from Supabase...');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = SupabaseService.auth.currentUser;
      if (user == null) {
        debugPrint('[ProfileScreen] ✗ No authenticated user found');
        setState(() {
          _errorMessage = 'لا يوجد مستخدم مسجل الدخول';
          _isLoading = false;
        });
        return;
      }

      debugPrint('[ProfileScreen] ℹ User ID: ${user.id}');
      debugPrint('[ProfileScreen] ℹ User email: ${user.email}');

      // 1. Get data from auth.users metadata
      emailController.text = user.email ?? '';
      phoneController.text = user.phone ?? user.userMetadata?['phone'] ?? '';
      nameController.text = user.userMetadata?['full_name'] ?? '';

      // 2. Try to get admin profile from admin_profiles table
      try {
        final adminProfile = await SupabaseService.client
            .from('admin_profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (adminProfile != null) {
          debugPrint('[ProfileScreen] ✓ Admin profile found');
          debugPrint('[ProfileScreen] ℹ Admin data: $adminProfile');
          setState(() {
            nameController.text =
                adminProfile['full_name'] ?? nameController.text;
            _role = adminProfile['role'] ?? 'viewer';
            _isActive = adminProfile['is_active'] ?? true;
            _lastLoginAt = adminProfile['last_login_at'] ?? '';
          });
        } else {
          debugPrint(
            '[ProfileScreen] ⚠ No admin_profiles row found — using auth metadata',
          );
          setState(() {
            _role = 'admin';
          });
        }
      } catch (e, stackTrace) {
        debugPrint('[ProfileScreen] ⚠ Error fetching admin_profiles: $e');
        AppLoggerService.logError(
          controller: 'ProfileScreen',
          method: '_loadAdminProfile.adminProfiles',
          error: e,
          stackTrace: stackTrace,
        );
        // Use auth metadata as fallback
        setState(() {
          _role = 'admin';
        });
      }

      debugPrint('[ProfileScreen] ✓ Profile loaded successfully');
      debugPrint('[ProfileScreen] ℹ Name: ${nameController.text}');
      debugPrint('[ProfileScreen] ℹ Email: ${emailController.text}');
      debugPrint('[ProfileScreen] ℹ Role: $_role');
    } catch (e, stackTrace) {
      debugPrint('[ProfileScreen] ✗ PROFILE LOAD ERROR: $e');
      debugPrint('[ProfileScreen] StackTrace: $stackTrace');
      AppLoggerService.logError(
        controller: 'ProfileScreen',
        method: '_loadAdminProfile',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _errorMessage = 'فشل في تحميل البيانات: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Update admin profile in Supabase
  Future<void> _saveProfile() async {
    debugPrint('[ProfileScreen] ▶ Save profile pressed');
    debugPrint('[ProfileScreen] ℹ Name: ${nameController.text}');
    debugPrint('[ProfileScreen] ℹ Email: ${emailController.text}');

    try {
      final user = SupabaseService.auth.currentUser;
      if (user == null) {
        debugPrint('[ProfileScreen] ✗ No user to update');
        return;
      }

      setState(() => _isLoading = true);

      // 1. Update auth.users metadata (name)
      await SupabaseService.auth.updateUser(
        UserAttributes(data: {'full_name': nameController.text.trim()}),
      );
      debugPrint('[ProfileScreen] ✓ Auth metadata updated');

      // 2. Update admin_profiles table
      try {
        await SupabaseService.client
            .from('admin_profiles')
            .update({'full_name': nameController.text.trim()})
            .eq('id', user.id);
        debugPrint('[ProfileScreen] ✓ admin_profiles updated');
      } catch (e) {
        debugPrint(
          '[ProfileScreen] ⚠ admin_profiles update failed (may not exist): $e',
        );
      }

      // 3. Update password if provided
      if (passwordController.text.isNotEmpty) {
        if (passwordController.text != confirmPasswordController.text) {
          debugPrint('[ProfileScreen] ✗ Password mismatch');
          Get.snackbar(
            'خطأ',
            'كلمات المرور غير متطابقة',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: KasbyColors.error.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
          setState(() => _isLoading = false);
          return;
        }

        await SupabaseService.auth.updateUser(
          UserAttributes(password: passwordController.text),
        );
        debugPrint('[ProfileScreen] ✓ Password updated');
        passwordController.clear();
        confirmPasswordController.clear();
      }

      // Update AuthController state
      _authController.userName.value = nameController.text.trim();

      Get.snackbar(
        'تم التحديث',
        'تم حفظ المعلومات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.success.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      debugPrint('[ProfileScreen] ✓ Profile save completed');
    } catch (e, stackTrace) {
      debugPrint('[ProfileScreen] ✗ SAVE ERROR: $e');
      debugPrint('[ProfileScreen] StackTrace: $stackTrace');
      AppLoggerService.logError(
        controller: 'ProfileScreen',
        method: '_saveProfile',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في حفظ البيانات: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.error.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              debugPrint('[ProfileScreen] ▶ Logout pressed');
              _authController.logout();
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(color: const Color(0xFF0F172A)),
          _buildOrb(
            top: -50,
            right: -50,
            size: 300,
            color: KasbyColors.primaryGold.withValues(alpha: 0.05),
          ),

          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: KasbyColors.primaryGold,
                  ),
                )
              : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: KasbyColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      KasbyButton(
                        text: 'إعادة المحاولة',
                        onPressed: _loadAdminProfile,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 100,
                  ),
                  child: Column(
                    children: [
                      // Majestic Avatar
                      _buildMajesticAvatar(),
                      const SizedBox(height: 48),

                      // Personal Info
                      _buildInfoSection('المعلومات الشخصية', [
                        KasbyTextField(
                          controller: nameController,
                          hintText: 'الاسم الكامل',
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        KasbyTextField(
                          controller: emailController,
                          hintText: 'البريد الإلكتروني',
                          prefixIcon: Icons.email_outlined,
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        KasbyTextField(
                          controller: phoneController,
                          hintText: 'رقم الهاتف',
                          prefixIcon: Icons.phone_android_outlined,
                          enabled: false,
                        ),
                      ], delay: 100),
                      const SizedBox(height: 24),

                      // Account Status
                      _buildInfoSection('حالة الحساب', [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusBadge(
                                'الدور',
                                _getRoleLabel(_role),
                                KasbyColors.primaryGold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatusBadge(
                                'الحالة',
                                _isActive ? 'نشط' : 'معطل',
                                _isActive
                                    ? KasbyColors.success
                                    : KasbyColors.error,
                              ),
                            ),
                          ],
                        ),
                        if (_lastLoginAt.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: KasbyColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'آخر تسجيل دخول: ${_formatDate(_lastLoginAt)}',
                                style: const TextStyle(
                                  color: KasbyColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ], delay: 200),
                      const SizedBox(height: 24),

                      // Security Card
                      _buildInfoSection('تغيير كلمة المرور', [
                        KasbyTextField(
                          controller: passwordController,
                          hintText: 'كلمة المرور الجديدة',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        KasbyTextField(
                          controller: confirmPasswordController,
                          hintText: 'تأكيد كلمة المرور',
                          prefixIcon: Icons.lock_reset,
                          obscureText: true,
                        ),
                      ], delay: 300),
                      const SizedBox(height: 48),

                      // Save Button
                      KasbyButton(
                        text: 'تحديث الهوية الرقمية',
                        onPressed: _saveProfile,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'superadmin':
        return 'مشرف عام';
      case 'admin':
        return 'مدير';
      case 'viewer':
        return 'مشاهد';
      default:
        return role;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildMajesticAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: KasbyColors.primaryGold.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
        ),
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: KasbyColors.primaryGold.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: KasbyColors.primaryGradient,
            shape: BoxShape.circle,
            border: Border.all(color: KasbyColors.primaryGold, width: 3),
          ),
          child: Center(
            child: Text(
              nameController.text.isNotEmpty
                  ? nameController.text[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<Widget> children, {
    required int delay,
  }) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: KasbyColors.primaryGold,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
          ],
        ),
      ),
    );
  }
}
