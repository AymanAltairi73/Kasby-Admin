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
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () {
              // TODO: Implement add user
            },
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
                    const Text(
                      'دليل المعاملات والمستخدمين',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2),
                    const SizedBox(height: 8),
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

              // Floating Glass Search and Filter Section
              Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: KasbyGlassCard(
                      padding: const EdgeInsets.all(12),
                      opacity: 0.08,
                      child: Column(
                        children: [
                          // Search Field
                          KasbyTextField(
                            hintText: 'بحث بالاسم، البريد، أو الهاتف...',
                            prefixIcon: Icons.search_rounded,
                            onChanged: (value) =>
                                userController.searchUsers(value),
                          ),
                          const SizedBox(height: 12),

                          // Status Filter
                          Obx(
                            () => SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildDazzlingFilterChip(
                                    label: 'الكل',
                                    isSelected:
                                        userController.selectedStatus.value ==
                                        'All',
                                    onTap: () =>
                                        userController.filterByStatus('All'),
                                    color: KasbyColors.info,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildDazzlingFilterChip(
                                    label: 'المستخدمين النشطين',
                                    isSelected:
                                        userController.selectedStatus.value ==
                                        'Active',
                                    onTap: () =>
                                        userController.filterByStatus('Active'),
                                    color: KasbyColors.success,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildDazzlingFilterChip(
                                    label: 'الحسابات المحظورة',
                                    isSelected:
                                        userController.selectedStatus.value ==
                                        'Blocked',
                                    onTap: () => userController.filterByStatus(
                                      'Blocked',
                                    ),
                                    color: KasbyColors.error,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 400))
                  .slideY(begin: 0.2),

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

  Widget _buildDazzlingFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? color
                : KasbyColors.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : KasbyColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
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
}
