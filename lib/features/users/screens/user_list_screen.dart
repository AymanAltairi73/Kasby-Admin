import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
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
    final userController = Get.put(UserController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إدارة المستخدمين'),
        actions: [
          // Search Icon
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearchDialog(context, userController),
          ),
          // Time Filter Dropdown
          PopupMenuButton<TimeFilter>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'تصفية حسب الوقت',
            onSelected: (TimeFilter filter) {
              userController.selectedTimeFilter.value = filter;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: TimeFilter.all,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      size: 18,
                      color:
                          userController.selectedTimeFilter.value ==
                              TimeFilter.all
                          ? KasbyColors.primaryGold
                          : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    Text('الكل'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TimeFilter.daily,
                child: Row(
                  children: [
                    Icon(
                      Icons.today,
                      size: 18,
                      color:
                          userController.selectedTimeFilter.value ==
                              TimeFilter.daily
                          ? KasbyColors.primaryGold
                          : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    Text('اليوم'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TimeFilter.weekly,
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 18,
                      color:
                          userController.selectedTimeFilter.value ==
                              TimeFilter.weekly
                          ? KasbyColors.primaryGold
                          : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    Text('هذا الأسبوع'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TimeFilter.monthly,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 18,
                      color:
                          userController.selectedTimeFilter.value ==
                              TimeFilter.monthly
                          ? KasbyColors.primaryGold
                          : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    Text('هذا الشهر'),
                  ],
                ),
              ),
            ],
          ),
          // Status Filter Dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'تصفية حسب الحالة',
            onSelected: (String status) {
              userController.filterByStatus(status);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'All',
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      size: 18,
                      color: userController.selectedStatus.value == 'All'
                          ? KasbyColors.info
                          : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    Text('جميع الحالات'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Active',
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
                    Text('النشطين'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Blocked',
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
                    Text('المحظورين'),
                  ],
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
          // Background Glow
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
          ).animate().fadeIn(duration: const Duration(seconds: 1)),

          Column(
            children: [
              // Radiant Header
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
                    // const Text(
                    //   'دليل المعاملات والمستخدمين',
                    //   style: TextStyle(
                    //     fontSize: 28,
                    //     fontWeight: FontWeight.w900,
                    //     letterSpacing: -0.5,
                    //   ),
                    // ).animate().fadeIn().slideX(begin: -0.2),
                    // const SizedBox(height: 8),
                    Obx(
                      () => Text(
                        'إجمالي المسجلين: ${userController.filteredUsers.length} مستخدم',
                        style: const TextStyle(
                          fontSize: 14,
                          color: KasbyColors.textSecondary,
                        ),
                      ),
                    ).animate().fadeIn(
                      delay: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ),

              // Removed - Filters now in AppBar

              // User List
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

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    itemCount: userController.filteredUsers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = userController.filteredUsers[index];
                      return _buildDazzlingUserCard(user)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 50 * index))
                          .slideX(begin: index % 2 == 0 ? -0.05 : 0.05);
                    },
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search Dialog
  static void _showSearchDialog(
    BuildContext context,
    UserController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('بحث عن مستخدم'),
        content: KasbyTextField(
          hintText: 'بحث بالاسم، البريد، أو الهاتف...',
          prefixIcon: Icons.search_rounded,
          onChanged: (value) => controller.searchUsers(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDazzlingUserCard(User user) {
    final statusColor = user.status == 'Active'
        ? KasbyColors.success
        : KasbyColors.error;

    return KasbyGlassCard(
      onTap: () => Get.to(() => UserDetailsScreen(user: user)),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar with Aura
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
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: const Duration(seconds: 2),
                    color: statusColor.withValues(alpha: 0.1),
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
                    user.name[0],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // User Info
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
                  ],
                ),
              ],
            ),
          ),

          // Action Indicator
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: KasbyColors.textSecondary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, UserController controller) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: KasbyGlassCard(
          padding: const EdgeInsets.all(24),
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
                hintText: 'الاسم الكامل',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: emailController,
                hintText: 'البريد الإلكتروني',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: phoneController,
                hintText: 'رقم الهاتف',
                prefixIcon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
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
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty &&
                          emailController.text.isNotEmpty &&
                          phoneController.text.isNotEmpty) {
                        controller.addUser(
                          name: nameController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                        );
                        Get.back();
                      } else {
                        Get.snackbar('خطأ', 'يرجى ملء جميع الحقول');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KasbyColors.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إضافة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
