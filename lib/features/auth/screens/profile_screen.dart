import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  late TextEditingController whatsappController;
  late TextEditingController telegramController;
  late TextEditingController provinceController;
  late TextEditingController cityController;
  late TextEditingController addressController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  // Admin profile data (read-only display)
  String _role = '';
  DateTime? _lastLoginAt;
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
    whatsappController = TextEditingController();
    telegramController = TextEditingController();
    provinceController = TextEditingController();
    cityController = TextEditingController();
    addressController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    _loadAdminProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    telegramController.dispose();
    provinceController.dispose();
    cityController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Load admin profile from Supabase
  Future<void> _loadAdminProfile() async {
    debugPrint('[ProfileScreen] ▶ Loading admin profile...');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Refresh profile data from AuthController
      await _authController.refreshProfile();
      final p = _authController.profile.value;

      if (p == null) {
        debugPrint('[ProfileScreen] ✗ No profile data found in AuthController');
        // Fallback to basic session info
        final user = SupabaseService.auth.currentUser;
        if (user != null) {
          emailController.text = user.email ?? '';
          nameController.text = user.userMetadata?['full_name'] ?? '';
        }
      } else {
        debugPrint('[ProfileScreen] ✓ Profile data loaded from AuthController');
        nameController.text = p.name;
        emailController.text = p.email;
        phoneController.text = p.phone;
        whatsappController.text = p.whatsapp;
        telegramController.text = p.telegram;
        provinceController.text = p.province;
        cityController.text = p.city;
        addressController.text = p.address;
        
        _role = p.role;
        _isActive = p.status == 'active';
        _lastLoginAt = p.lastLoginAt;
      }
    } catch (e, stackTrace) {
      debugPrint('[ProfileScreen] ✗ PROFILE LOAD ERROR: $e');
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

  /// Pick and upload avatar to Supabase Storage
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.auth.currentUser;
      if (user == null) return;

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      debugPrint('[ProfileScreen] ▶ Uploading avatar: $filePath');

      // 1. Upload to Supabase Storage
      await SupabaseService.client.storage
          .from('avatars')
          .upload(filePath, file);

      // 2. Get Public URL
      final String publicUrl = SupabaseService.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      debugPrint('[ProfileScreen] ✓ Avatar uploaded: $publicUrl');

      // 3. Update profiles table
      await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);

      // 4. Update AuthController state
      _authController.updateAvatar(publicUrl);

      Get.snackbar(
        'تم التحديث',
        'تمت تحديث الصورة الشخصية بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.success.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('[ProfileScreen] ✗ AVATAR UPLOAD ERROR: $e');
      Get.snackbar(
        'خطأ',
        'فشل رفع الصورة. تأكد من وجود صلاحية الوصول للملفات.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: KasbyColors.error.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
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

      // 2. Update profiles table (SSOT)
      await SupabaseService.client
          .from('profiles')
          .update({
            'full_name': nameController.text.trim(),
            'whatsapp': whatsappController.text.trim(),
            'telegram': telegramController.text.trim(),
            'province': provinceController.text.trim(),
            'city': cityController.text.trim(),
            'address': addressController.text.trim(),
          })
          .eq('id', user.id);
      debugPrint('[ProfileScreen] ✓ profiles updated');

      // 3. Update admin_profiles table if it exists
      try {
        await SupabaseService.client
            .from('admin_profiles')
            .update({'full_name': nameController.text.trim()})
            .eq('id', user.id);
        debugPrint('[ProfileScreen] ✓ admin_profiles updated');
      } catch (e) {
        debugPrint('[ProfileScreen] ℹ admin_profiles update skipped or failed');
      }

      // 4. Update password if provided
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

        try {
          await SupabaseService.auth.updateUser(
            UserAttributes(password: passwordController.text),
          );
          debugPrint('[ProfileScreen] ✓ Password updated');
          passwordController.clear();
          confirmPasswordController.clear();
        } on AuthApiException catch (authKey) {
          if (authKey.code == 'same_password') {
            Get.snackbar(
              'تنبيه',
              'كلمة المرور الجديدة يجب أن تكون مختلفة عن الحالية',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: KasbyColors.warning.withValues(alpha: 0.8),
              colorText: Colors.black,
            );
          } else {
            rethrow;
          }
        }
      }

      // Update AuthController state
      await _authController.refreshProfile();

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
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Avatar ─────────────────────────────────
                      Center(child: _buildMajesticAvatar()),
                      const SizedBox(height: 12),

                      // Name under avatar
                      Obx(() => Center(
                        child: Text(
                          _authController.profile.value?.name.isNotEmpty == true
                              ? _authController.profile.value!.name
                              : nameController.text,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )),
                      const SizedBox(height: 4),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: KasbyColors.primaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: KasbyColors.primaryGold.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _getRoleLabel(_role),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: KasbyColors.primaryGold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─── Account Status Banner ───────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: (_isActive ? KasbyColors.success : KasbyColors.error)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (_isActive ? KasbyColors.success : KasbyColors.error)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isActive ? Icons.verified_rounded : Icons.block_rounded,
                              color: _isActive ? KasbyColors.success : KasbyColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isActive ? 'الحساب نشط ' : 'الحساب موقوف',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _isActive ? KasbyColors.success : KasbyColors.error,
                              ),
                            ),
                            const Spacer(),
                            if (_lastLoginAt != null)
                              Text(
                                _formatDate(_lastLoginAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (_isActive ? KasbyColors.success : KasbyColors.error)
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ─── Personal Info ────────────────────────────
                      _buildInfoSection('المعلومات الشخصية', [
                        _buildLabeledField(
                          label: 'الاسم الكامل',
                          icon: Icons.person_outline_rounded,
                          child: KasbyTextField(
                            controller: nameController,
                            hintText: 'أدخل اسمك الكامل',
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildReadOnlyTile(
                          label: 'البريد الإلكتروني',
                          value: emailController.text,
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildReadOnlyTile(
                          label: 'رقم الهاتف',
                          value: phoneController.text.isNotEmpty
                              ? phoneController.text
                              : 'غير محدد',
                          icon: Icons.phone_android_outlined,
                        ),
                      ], delay: 100),
                      const SizedBox(height: 20),

                      // ─── Social ────────────────────────────────
                      _buildInfoSection('التواصل الاجتماعي', [
                        _buildLabeledField(
                          label: 'واتساب',
                          icon: Icons.chat_bubble_outline_rounded,
                          child: KasbyTextField(
                            controller: whatsappController,
                            hintText: '+967 7XX XXX XXX',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabeledField(
                          label: 'تليجرام',
                          icon: Icons.send_outlined,
                          child: KasbyTextField(
                            controller: telegramController,
                            hintText: '@username',
                          ),
                        ),
                      ], delay: 150),
                      const SizedBox(height: 20),

                      // ─── Address ──────────────────────────────
                      _buildInfoSection('العنوان والموقع', [
                        Row(
                          children: [
                            Expanded(
                              child: _buildLabeledField(
                                label: 'المحافظة',
                                icon: Icons.map_outlined,
                                child: KasbyTextField(
                                  controller: provinceController,
                                  hintText: 'اسم المحافظة',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildLabeledField(
                                label: 'المدينة',
                                icon: Icons.location_city_outlined,
                                child: KasbyTextField(
                                  controller: cityController,
                                  hintText: 'اسم المدينة',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildLabeledField(
                          label: 'العنوان التفصيلي',
                          icon: Icons.home_outlined,
                          child: KasbyTextField(
                            controller: addressController,
                            hintText: 'الشارع، الحي...',
                            maxLines: 2,
                          ),
                        ),
                      ], delay: 200),
                      const SizedBox(height: 20),

                      // ─── Security ─────────────────────────────
                      _buildInfoSection('الأمان وكلمة المرور', [
                        _buildLabeledField(
                          label: 'كلمة المرور الجديدة',
                          icon: Icons.lock_outline_rounded,
                          child: KasbyTextField(
                            controller: passwordController,
                            hintText: '8 أحرف أو أكثر',
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabeledField(
                          label: 'تأكيد كلمة المرور',
                          icon: Icons.lock_reset_rounded,
                          child: KasbyTextField(
                            controller: confirmPasswordController,
                            hintText: 'أعد كتابة كلمة المرور',
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '⚠ اترك كلمة المرور فارغة إذا لم ترد تغييرها',
                            style: TextStyle(
                              fontSize: 11,
                              color: KasbyColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ], delay: 300),
                      const SizedBox(height: 36),

                      // ─── Save Button ─────────────────────────
                      KasbyButton(
                        text: 'حفظ التغييرات',
                        onPressed: _saveProfile,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: KasbyColors.primaryGold),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KasbyColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildReadOnlyTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KasbyColors.primaryGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: KasbyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KasbyColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'للقراءة فقط',
              style: TextStyle(
                fontSize: 10,
                color: KasbyColors.textSecondary,
              ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير متوفر';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMajesticAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing background orbs
        _buildOrb(size: 180, color: KasbyColors.primaryGold.withValues(alpha: 0.05)),
        
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: KasbyColors.primaryGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        
        // Main Avatar Container
        GestureDetector(
          onTap: _pickAndUploadAvatar,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: KasbyColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: KasbyColors.primaryGold, width: 2),
                  ),
                  child: Obx(() {
                    final avatarUrl = _authController.profile.value?.avatarUrl;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (_, __, ___) => _buildInitial(),
                            )
                          : _buildInitial(),
                    );
                  }),
                ),
              ),
              
              // Edit Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: KasbyColors.primaryGold, width: 1.5),
                ),
                child: const Icon(
                  Icons.camera_enhance_rounded,
                  size: 18,
                  color: KasbyColors.primaryGold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitial() {
    return Text(
      nameController.text.isNotEmpty ? nameController.text[0].toUpperCase() : '?',
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: Colors.black,
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
