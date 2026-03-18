import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_dialog.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../../../core/utils/validation_utils.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';
import 'user_details_screen.dart';
import '../../../core/models/time_filter.dart';

/// User List Screen
/// Display all users with search and filter
class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إدارة المستخدمين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearchDialog(context, userController),
          ),
          PopupMenuButton<dynamic>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'تصفية المستخدمين',
            onSelected: (value) {
              if (value is TimeFilter) {
                userController.selectedTimeFilter.value = value;
              } else if (value is Map<String, String>) {
                final type = value['type'];
                final val = value['value']!;
                if (type == 'status') {
                  userController.filterByStatus(val);
                } else if (type == 'country') {
                  userController.filterByCountry(val);
                } else if (type == 'accountType') {
                  userController.filterByAccountType(val);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'التصفية حسب الوقت',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.primaryGold,
                  ),
                ),
              ),
              ...TimeFilter.values.map((filter) {
                String label = 'الكل';
                IconData icon = Icons.all_inclusive;
                if (filter == TimeFilter.daily) {
                  label = 'اليوم';
                  icon = Icons.today;
                } else if (filter == TimeFilter.weekly) {
                  label = 'هذا الأسبوع';
                  icon = Icons.date_range;
                } else if (filter == TimeFilter.monthly) {
                  label = 'هذا الشهر';
                  icon = Icons.calendar_month;
                }

                return PopupMenuItem(
                  value: filter,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: userController.selectedTimeFilter.value == filter
                            ? KasbyColors.primaryGold
                            : Colors.white60,
                      ),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'حالة المستخدم',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.primaryGold,
                  ),
                ),
              ),
              PopupMenuItem(
                value: {'type': 'status', 'value': 'all'},
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      size: 18,
                      color: userController.selectedStatus.value == 'all'
                          ? KasbyColors.info
                          : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    const Text('جميع الحالات'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: {'type': 'status', 'value': 'Active'},
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: userController.selectedStatus.value == 'Active'
                          ? KasbyColors.success
                          : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    const Text('النشطين'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: {'type': 'status', 'value': 'Blocked'},
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: 18,
                      color: userController.selectedStatus.value == 'Blocked'
                          ? KasbyColors.error
                          : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    const Text('المحظورين'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'الدولة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.primaryGold,
                  ),
                ),
              ),
              PopupMenuItem(
                value: {'type': 'country', 'value': 'all'},
                child: Text(
                  'كل الدول',
                  style: TextStyle(
                    color: userController.selectedCountry.value == 'all'
                        ? KasbyColors.primaryGold
                        : Colors.white,
                  ),
                ),
              ),
              ...['Saudi Arabia', 'UAE', 'Kuwait', 'Egypt', 'Oman'].map(
                (country) => PopupMenuItem(
                  value: {'type': 'country', 'value': country},
                  child: Text(
                    country,
                    style: TextStyle(
                      color: userController.selectedCountry.value == country
                          ? KasbyColors.primaryGold
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'نوع الحساب',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.primaryGold,
                  ),
                ),
              ),
              PopupMenuItem(
                value: {'type': 'accountType', 'value': 'all'},
                child: Text(
                  'كل الحسابات',
                  style: TextStyle(
                    color: userController.selectedAccountType.value == 'all'
                        ? KasbyColors.primaryGold
                        : Colors.white,
                  ),
                ),
              ),
              ...['Free', 'Verified', 'VIP'].map(
                (type) => PopupMenuItem(
                  value: {'type': 'accountType', 'value': type},
                  child: Text(
                    type,
                    style: TextStyle(
                      color: userController.selectedAccountType.value == type
                          ? KasbyColors.primaryGold
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _showAddUserDialog(context, userController),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KasbyColors.info.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 120, 24, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      KasbyColors.info.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        'إجمالي المسجلين: ${userController.filteredUsers.length} مستخدم',
                        style: const TextStyle(
                          fontSize: 14,
                          color: KasbyColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (userController.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: KasbyColors.primaryGold,
                      ),
                    );
                  }

                  if (userController.filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_rounded,
                            size: 64,
                            color: KasbyColors.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لم يتم العثور على نتائج',
                            style: TextStyle(
                              color: KasbyColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => userController.loadUsers(),
                    color: KasbyColors.primaryGold,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                      itemCount: userController.filteredUsers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = userController.filteredUsers[index];
                        return _buildDazzlingUserCard(user);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showSearchDialog(
    BuildContext context,
    UserController controller,
  ) {
    KasbyDialog.show(
      title: 'بحث عن مستخدم',
      content: KasbyTextField(
        hintText: 'بحث بالاسم، البريد، أو الهاتف...',
        prefixIcon: Icons.search_rounded,
        onChanged: (value) => controller.searchUsers(value),
      ),
    );
  }

  Widget _buildDazzlingUserCard(User user) {
    final statusColor = user.status == 'Active'
        ? KasbyColors.success
        : KasbyColors.error;

    Color accountColor = Colors.white;
    IconData accountIcon = Icons.person_outline;
    if (user.accountType == 'VIP') {
      accountColor = KasbyColors.primaryGold;
      accountIcon = Icons.stars_rounded;
    } else if (user.accountType == 'Verified') {
      accountColor = KasbyColors.info;
      accountIcon = Icons.verified_rounded;
    }

    return KasbyGlassCard(
      onTap: () => Get.to(() => UserDetailsScreen(user: user)),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.8),
                      statusColor.withValues(alpha: 0.4),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (user.accountType != 'Free')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: KasbyColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(accountIcon, size: 14, color: accountColor),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: user.accountType.toLowerCase() == 'vip'
                            ? KasbyColors.primaryGold.withValues(alpha: 0.2)
                            : user.accountType.toLowerCase() == 'verified'
                            ? KasbyColors.success.withValues(alpha: 0.2)
                            : KasbyColors.info.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: user.accountType.toLowerCase() == 'vip'
                              ? KasbyColors.primaryGold.withValues(alpha: 0.5)
                              : user.accountType.toLowerCase() == 'verified'
                              ? KasbyColors.success.withValues(alpha: 0.5)
                              : KasbyColors.info.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        user.accountType.toLowerCase() == 'vip'
                            ? 'VIP'
                            : user.accountType.toLowerCase() == 'verified'
                            ? 'موثق'
                            : 'مجاني',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: user.accountType.toLowerCase() == 'vip'
                              ? KasbyColors.primaryGold
                              : user.accountType.toLowerCase() == 'verified'
                              ? KasbyColors.success
                              : KasbyColors.info,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.country,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: KasbyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.wallet,
                      size: 10,
                      color: KasbyColors.primaryGold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '\$${user.walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: KasbyColors.primaryGold,
                      ),
                    ),
                    const Spacer(),
                    if (user.kycStatus == 'Verified')
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: KasbyColors.success,
                      ),
                    if (user.kycStatus == 'Pending')
                      const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: KasbyColors.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user.whatsapp.isNotEmpty)
                    _buildQuickAction(
                      icon: FontAwesomeIcons.whatsapp,
                      color: const Color(0xFF25D366),
                      onTap: () => _launchUrl(
                        'https://wa.me/${user.whatsapp.replaceAll('+', '')}',
                        fallbackMessage:
                            'يرجى التأكد من تثبيت واتساب على جهازك',
                      ),
                    ),
                  if (user.telegram.isNotEmpty)
                    _buildQuickAction(
                      icon: FontAwesomeIcons.telegram,
                      color: const Color(0xFF24A1DE),
                      onTap: () => _launchUrl(
                        user.telegram.startsWith('http')
                            ? user.telegram
                            : 'https://t.me/${user.telegram.replaceAll('@', '')}',
                        fallbackMessage:
                            'يرجى التأكد من تثبيت تليجرام على جهازك',
                      ),
                    ),
                  _buildQuickAction(
                    icon: Icons.phone_forwarded_rounded,
                    color: KasbyColors.info,
                    onTap: () => _launchUrl('tel:${user.phone}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: KasbyColors.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  static Future<void> _launchUrl(String url, {String? fallbackMessage}) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        Get.snackbar(
          'تنبيه',
          fallbackMessage ??
              'لا يمكن فتح الرابط، يرجى التأكد من تثبيت التطبيق المطلوب',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: KasbyColors.warning.withValues(alpha: 0.8),
          colorText: Colors.black,
        );
      }
    } catch (e) {
      debugPrint('Launch error: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء محاولة فتح الرابط، تأكد من تثبيت التطبيق');
    }
  }

  void _showAddUserDialog(BuildContext context, UserController controller) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final countryController = TextEditingController();
    final cityController = TextEditingController();
    final phoneController = TextEditingController();
    final whatsappController = TextEditingController();
    final telegramController = TextEditingController();
    final emailController = TextEditingController();

    final isFormValid = false.obs;

    void validate() {
      isFormValid.value = formKey.currentState?.validate() ?? false;
    }

    Get.dialog(
      BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: KasbyGlassCard(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                onChanged: validate,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إضافة مستخدم جديد',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    KasbyTextField(
                      controller: nameController,
                      hintText: 'الاسم الكامل للمستخدم',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          ValidationUtils.validateRequired(v, 'الاسم'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: KasbyTextField(
                            controller: countryController,
                            hintText: 'الدولة',
                            prefixIcon: Icons.public_rounded,
                            validator: (v) =>
                                ValidationUtils.validateRequired(v, 'الدولة'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KasbyTextField(
                            controller: cityController,
                            hintText: 'المدينة',
                            prefixIcon: Icons.location_city_rounded,
                            validator: (v) =>
                                ValidationUtils.validateRequired(v, 'المدينة'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    KasbyTextField(
                      controller: phoneController,
                      hintText: 'رقم الهاتف (إلزامي)',
                      prefixIcon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                      validator: ValidationUtils.validatePhone,
                    ),
                    const SizedBox(height: 12),
                    KasbyTextField(
                      controller: whatsappController,
                      hintText: 'رقم واتساب (اختياري)',
                      prefixIcon: FontAwesomeIcons.whatsapp,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    KasbyTextField(
                      controller: telegramController,
                      hintText: 'معرف تيليجرام (اختياري)',
                      prefixIcon: FontAwesomeIcons.telegram,
                    ),
                    const SizedBox(height: 12),
                    KasbyTextField(
                      controller: emailController,
                      hintText: 'البريد الإلكتروني (اختياري)',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v != null && v.isNotEmpty
                          ? ValidationUtils.validateEmail(v)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(color: KasbyColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(
                          () => ElevatedButton(
                            onPressed: isFormValid.value
                                ? () {
                                    KasbyConfirmationDialog.show(
                                      title: 'تأكيد العملية',
                                      message:
                                          'هل أنت متأكد من إضافة هذا المستخدم؟',
                                      confirmText: 'تأكيد',
                                      onConfirm: () async {
                                        await controller.addUser(
                                          name: nameController.text,
                                          country: countryController.text,
                                          city: cityController.text,
                                          phone: phoneController.text,
                                          whatsapp: whatsappController.text,
                                          telegram: telegramController.text,
                                          email: emailController.text,
                                        );
                                        Get.back(); // Close dialog
                                      },
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KasbyColors.primaryGold,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('إضافة'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
