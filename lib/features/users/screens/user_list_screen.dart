import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
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
      appBar: AppBar(title: const Text('إدارة المستخدمين')),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: KasbyColors.surface,
            child: Column(
              children: [
                // Search Field
                KasbyTextField(
                  hintText: 'بحث بالاسم، البريد، أو الهاتف',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    userController.searchUsers(value);
                  },
                ),
                const SizedBox(height: 12),

                // Status Filter
                Obx(
                  () => Row(
                    children: [
                      _buildFilterChip(
                        label: 'الكل',
                        isSelected:
                            userController.selectedStatus.value == 'All',
                        onTap: () => userController.filterByStatus('All'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'نشط',
                        isSelected:
                            userController.selectedStatus.value == 'Active',
                        onTap: () => userController.filterByStatus('Active'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'محظور',
                        isSelected:
                            userController.selectedStatus.value == 'Blocked',
                        onTap: () => userController.filterByStatus('Blocked'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                return const Center(
                  child: Text(
                    'لا يوجد مستخدمين',
                    style: TextStyle(
                      color: KasbyColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: userController.filteredUsers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = userController.filteredUsers[index];
                  return _buildUserCard(user);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KasbyColors.primaryGold : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? KasbyColors.primaryGold
                : KasbyColors.textSecondary,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : KasbyColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return KasbyCard(
      onTap: () {
        Get.to(() => UserDetailsScreen(user: user));
      },
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: KasbyColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name[0],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
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
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: KasbyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.wallet,
                      size: 12,
                      color: KasbyColors.primaryGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${user.walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: KasbyColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user.status == 'Active'
                  ? KasbyColors.success.withValues(alpha: 0.2)
                  : KasbyColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.status == 'Active' ? 'نشط' : 'محظور',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: user.status == 'Active'
                    ? KasbyColors.success
                    : KasbyColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
