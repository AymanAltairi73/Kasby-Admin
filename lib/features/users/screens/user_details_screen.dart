import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../models/user_model.dart';
import '../controllers/user_controller.dart';

/// User Details Screen
/// Show detailed user information and admin actions
class UserDetailsScreen extends StatelessWidget {
  final User user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المستخدم'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            color: KasbyColors.surface,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text(
                  'إضافة رصيد',
                  style: TextStyle(color: KasbyColors.textPrimary),
                ),
                onTap: () {
                  Future.delayed(
                    Duration.zero,
                    () => _showAddBalanceDialog(context, userController),
                  );
                },
              ),
              PopupMenuItem(
                child: const Text(
                  'خصم رصيد',
                  style: TextStyle(color: KasbyColors.textPrimary),
                ),
                onTap: () {
                  Future.delayed(
                    Duration.zero,
                    () => _showDeductBalanceDialog(context, userController),
                  );
                },
              ),
              PopupMenuItem(
                child: Text(
                  user.status == 'Active' ? 'حظر المستخدم' : 'تفعيل المستخدم',
                  style: TextStyle(
                    color: user.status == 'Active'
                        ? KasbyColors.error
                        : KasbyColors.success,
                  ),
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    if (user.status == 'Active') {
                      userController.blockUser(user.id);
                    } else {
                      userController.activateUser(user.id);
                    }
                    Get.back();
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            KasbyCard(
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: KasbyColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.name[0],
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: KasbyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email & Phone
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.email,
                        size: 16,
                        color: KasbyColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: KasbyColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: KasbyColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: KasbyColors.textSecondary,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: user.status == 'Active'
                          ? KasbyColors.success.withOpacity(0.2)
                          : KasbyColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.status == 'Active' ? 'نشط' : 'محظور',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: user.status == 'Active'
                            ? KasbyColors.success
                            : KasbyColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Member Since
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      'عضو منذ ${DateFormat('dd/MM/yyyy', 'en').format(user.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: KasbyColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Wallet Section
            const Text(
              'المحفظة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildWalletCard(
                    title: 'الرصيد المتاح',
                    amount: user.walletBalance,
                    icon: FontAwesomeIcons.wallet,
                    color: KasbyColors.primaryGold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWalletCard(
                    title: 'المستثمر',
                    amount: user.investedAmount,
                    icon: FontAwesomeIcons.chartLine,
                    color: KasbyColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildWalletCard(
              title: 'المعلق',
              amount: user.pendingAmount,
              icon: FontAwesomeIcons.clockRotateLeft,
              color: KasbyColors.warning,
            ),
            const SizedBox(height: 24),

            // Investments Section
            const Text(
              'الاستثمارات النشطة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            KasbyCard(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'لا توجد استثمارات نشطة',
                    style: TextStyle(color: KasbyColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transaction History
            const Text(
              'سجل المعاملات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            KasbyCard(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'لا توجد معاملات',
                    style: TextStyle(color: KasbyColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return KasbyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: KasbyColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBalanceDialog(BuildContext context, UserController controller) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'إضافة رصيد',
          style: TextStyle(color: KasbyColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KasbyTextField(
              controller: amountController,
              hintText: 'المبلغ',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: 12),
            KasbyTextField(
              controller: reasonController,
              hintText: 'السبب',
              maxLines: 3,
              prefixIcon: Icons.note,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: KasbyColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0 && reasonController.text.isNotEmpty) {
                controller.addBalance(user.id, amount, reasonController.text);
                Get.back();
              } else {
                Get.snackbar('خطأ', 'الرجاء إدخال مبلغ وسبب صحيحين');
              }
            },
            child: const Text(
              'إضافة',
              style: TextStyle(color: KasbyColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeductBalanceDialog(
    BuildContext context,
    UserController controller,
  ) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'خصم رصيد',
          style: TextStyle(color: KasbyColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KasbyTextField(
              controller: amountController,
              hintText: 'المبلغ',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: 12),
            KasbyTextField(
              controller: reasonController,
              hintText: 'السبب',
              maxLines: 3,
              prefixIcon: Icons.note,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: KasbyColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0 && reasonController.text.isNotEmpty) {
                controller.deductBalance(
                  user.id,
                  amount,
                  reasonController.text,
                );
                Get.back();
              } else {
                Get.snackbar('خطأ', 'الرجاء إدخال مبلغ وسبب صحيحين');
              }
            },
            child: const Text(
              'خصم',
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
