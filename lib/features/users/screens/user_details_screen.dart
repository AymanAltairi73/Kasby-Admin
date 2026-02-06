import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_glass_card.dart';
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
          PopupMenuButton<void>(
            icon: const Icon(Icons.more_vert),
            color: KasbyColors.surface,
            itemBuilder: (context) => <PopupMenuEntry<void>>[
              PopupMenuItem(
                child: const Text(
                  'إضافة رصيد',
                  style: TextStyle(color: KasbyColors.textPrimary),
                ),
                onTap: () {
                  final ctx = context;
                  Future.delayed(Duration.zero, () {
                    if (ctx.mounted) {
                      _showAddBalanceDialog(ctx, userController);
                    }
                  });
                },
              ),
              PopupMenuItem(
                child: const Text(
                  'خصم رصيد',
                  style: TextStyle(color: KasbyColors.textPrimary),
                ),
                onTap: () {
                  final ctx = context;
                  Future.delayed(Duration.zero, () {
                    if (ctx.mounted) {
                      _showDeductBalanceDialog(ctx, userController);
                    }
                  });
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
                    if (Get.isOverlaysOpen) {
                      Get.back();
                    }
                  });
                },
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: KasbyColors.textPrimary,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'تعديل البيانات',
                      style: TextStyle(color: KasbyColors.textPrimary),
                    ),
                  ],
                ),
                onTap: () {
                  final ctx = context;
                  Future.delayed(Duration.zero, () {
                    if (ctx.mounted) {
                      _showEditUserDialog(ctx, userController);
                    }
                  });
                },
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: KasbyColors.error,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'حذف المستخدم',
                      style: TextStyle(color: KasbyColors.error),
                    ),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    _showDeleteConfirmation(userController);
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
                        textDirection: ui.TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: KasbyColors.textSecondary,
                        ),
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
                          ? KasbyColors.success.withValues(alpha: 0.2)
                          : KasbyColors.error.withValues(alpha: 0.2),
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
                    textDirection: ui.TextDirection.ltr,
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
            textDirection: ui.TextDirection.ltr,
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

  void _showEditUserDialog(BuildContext context, UserController controller) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);

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
                'تعديل بيانات المستخدم',
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
                        final updatedUser = user.copyWith(
                          name: nameController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                        );
                        controller.updateUser(updatedUser);
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
                      'حفظ التعديلات',
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

  void _showDeleteConfirmation(UserController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف المستخدم "${user.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(color: KasbyColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: KasbyColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteUser(user.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KasbyColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
