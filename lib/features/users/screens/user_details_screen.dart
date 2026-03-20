import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_dialog.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../../../core/utils/validation_utils.dart';
import '../models/user_model.dart';
import '../controllers/user_controller.dart';
import '../../chat/models/chat_model.dart';
import '../../chat/screens/chat_details_screen.dart';
import 'edit_user_screen.dart';

/// User Details Screen
/// Show detailed user information and admin actions
class UserDetailsScreen extends StatefulWidget {
  final User user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late final UserController userController;

  @override
  void initState() {
    super.initState();
    userController = Get.find<UserController>();
    // Load extra details (Investments, Transactions, Activities)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userController.loadUserExtraDetails(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  widget.user.status == 'Active'
                      ? 'حظر المستخدم'
                      : 'تفعيل المستخدم',
                  style: TextStyle(
                    color: widget.user.status == 'Active'
                        ? KasbyColors.error
                        : KasbyColors.success,
                  ),
                ),
                onTap: () {
                  KasbyConfirmationDialog.show(
                    title: widget.user.status == 'Active'
                        ? 'حظر المستخدم'
                        : 'تفعيل المستخدم',
                    message: widget.user.status == 'Active'
                        ? 'هل أنت متأكد من حظر المستخدم "${widget.user.name}"؟'
                        : 'هل أنت متأكد من تفعيل المستخدم "${widget.user.name}"؟',
                    isDangerous: widget.user.status == 'Active',
                    onConfirm: () {
                      if (widget.user.status == 'Active') {
                        userController.blockUser(widget.user.id);
                      } else {
                        userController.activateUser(widget.user.id);
                      }
                    },
                  );
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
                      'تحديث بيانات المستخدم',
                      style: TextStyle(color: KasbyColors.textPrimary),
                    ),
                  ],
                ),
                onTap: () {
                  final ctx = context;
                  Future.delayed(Duration.zero, () {
                    if (ctx.mounted) {
                      Get.to(() => EditUserScreen(user: widget.user));
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
      body: RefreshIndicator(
        onRefresh: () async {
          await userController.loadUsers();
          await userController.loadUserExtraDetails(widget.user.id);
        },
        color: KasbyColors.primaryGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      child: ClipOval(
                        child: widget.user.avatarUrl.isNotEmpty
                            ? Image.network(
                                widget.user.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.account_circle_rounded,
                                      size: 56,
                                      color: Colors.black,
                                    ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.black,
                                        ),
                                      );
                                    },
                              )
                            : const Icon(
                                Icons.account_circle_rounded,
                                size: 56,
                                color: Colors.black,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name & Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: KasbyColors.textPrimary,
                          ),
                        ),
                        if (widget.user.accountType == 'VIP')
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.stars_rounded,
                              color: KasbyColors.primaryGold,
                              size: 24,
                            ),
                          )
                        else if (widget.user.accountType == 'Verified')
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.verified_rounded,
                              color: KasbyColors.info,
                              size: 24,
                            ),
                          ),
                      ],
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
                          widget.user.email,
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
                          widget.user.phone,
                          textDirection: ui.TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: KasbyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (widget.user.address.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: KasbyColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.user.address,
                              style: const TextStyle(
                                fontSize: 14,
                                color: KasbyColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Communication Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.user.whatsapp.isNotEmpty)
                          _buildCommunicationButton(
                            icon: FontAwesomeIcons.whatsapp,
                            color: const Color(0xFF25D366),
                            label: 'واتساب',
                            onTap: () => _launchUrl(
                              'https://wa.me/${widget.user.whatsapp.replaceAll('+', '')}',
                              fallbackMessage:
                                  'يرجى التأكد من تثبيت واتساب على جهازك',
                            ),
                          ),
                        if (widget.user.whatsapp.isNotEmpty)
                          const SizedBox(width: 20),
                        if (widget.user.telegram.isNotEmpty)
                          _buildCommunicationButton(
                            icon: FontAwesomeIcons.telegram,
                            color: const Color(0xFF24A1DE),
                            label: 'تيليجرام',
                            onTap: () => _launchUrl(
                              widget.user.telegram.startsWith('http')
                                  ? widget.user.telegram
                                  : 'https://t.me/${widget.user.telegram.replaceAll('@', '')}',
                              fallbackMessage:
                                  'يرجى التأكد من تثبيت تليجرام على جهازك',
                            ),
                          ),
                        if (widget.user.telegram.isNotEmpty)
                          const SizedBox(width: 20),
                        _buildCommunicationButton(
                          icon: Icons.phone_forwarded_rounded,
                          color: KasbyColors.info,
                          label: 'اتصال',
                          onTap: () => _launchUrl('tel:${widget.user.phone}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Badges Row
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Obx(() {
                          final currUser =
                              userController.getUserById(widget.user.id) ??
                              widget.user;
                          return _buildStatusBadge(
                            label: currUser.status == 'Active'
                                ? 'نشط'
                                : 'محظور',
                            color: currUser.status == 'Active'
                                ? KasbyColors.success
                                : KasbyColors.error,
                          );
                        }),
                        _buildStatusBadge(
                          label: widget.user.country,
                          color: KasbyColors.info,
                          icon: Icons.public,
                        ),
                        Obx(() {
                          final currUser =
                              userController.getUserById(widget.user.id) ??
                              widget.user;
                          return _buildStatusBadge(
                            label: 'KYC: ${currUser.kycStatus}',
                            color: currUser.kycStatus == 'Verified'
                                ? KasbyColors.success
                                : (currUser.kycStatus == 'Pending'
                                      ? KasbyColors.warning
                                      : KasbyColors.error),
                            icon: Icons.how_to_reg,
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Member Since
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text(
                        'عضو منذ ${DateFormat('dd/MM/yyyy', 'en').format(widget.user.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: KasbyColors.textSecondary,
                        ),
                      ),
                    ),

                    // KYC Actions (If Pending)
                    if (widget.user.kycStatus == 'Pending')
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('رفض'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KasbyColors.error,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                // Mock Action
                                Get.snackbar('تم', 'تم رفض وثائق التوثيق');
                              },
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('توثيق الحساب'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KasbyColors.success,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                // Mock Action
                                final updated = widget.user.copyWith(
                                  kycStatus: 'Verified',
                                  accountType: 'Verified',
                                );
                                userController.updateUser(updated);
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Communication & Chat Section
              KasbyGlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'قنوات التواصل المباشر',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCommunicationButton(
                          icon: FontAwesomeIcons.whatsapp,
                          color: const Color(0xFF25D366),
                          label: 'واتساب',
                          onTap: () => _launchUrl(
                            'https://wa.me/${widget.user.whatsapp.replaceAll('+', '')}',
                            fallbackMessage:
                                'يرجى التأكد من تثبيت واتساب على جهازك',
                          ),
                        ),
                        _buildCommunicationButton(
                          icon: FontAwesomeIcons.telegram,
                          color: const Color(0xFF24A1DE),
                          label: 'تليجرام',
                          onTap: () => _launchUrl(
                            widget.user.telegram.startsWith('http')
                                ? widget.user.telegram
                                : 'https://t.me/${widget.user.telegram.replaceAll('@', '')}',
                            fallbackMessage:
                                'يرجى التأكد من تثبيت تليجرام على جهازك',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              KasbyColors.primaryGold.withValues(alpha: 0.2),
                              KasbyColors.primaryGold.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: KasbyColors.primaryGold.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: KasbyColors.primaryGold.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            // Navigate to instant chat
                            Get.to(
                              () => const ChatDetailsScreen(),
                              arguments: ChatConversation(
                                id: '', // Empty ID signifies a potentially new conversation
                                userId: widget.user.id,
                                userName: widget.user.name,
                                lastMessage: 'بدء محادثة جديدة',
                                lastMessageTime: DateTime.now(),
                                isOnline: true,
                              ),
                            );
                          },
                          icon: const Icon(
                            FontAwesomeIcons.commentDots,
                            color: KasbyColors.primaryGold,
                          ),
                          label: const Text(
                            'بدء دردشة فورية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 24),
              // Quick Actions Section
              _buildQuickActions(context, userController),
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
              Obx(() {
                final currUser =
                    userController.getUserById(widget.user.id) ?? widget.user;
                return Row(
                  children: [
                    Expanded(
                      child: _buildWalletCard(
                        title: 'الرصيد المتاح',
                        amount: currUser.walletBalance,
                        icon: FontAwesomeIcons.wallet,
                        color: KasbyColors.primaryGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildWalletCard(
                        title: 'المستثمر',
                        amount: currUser.investedAmount,
                        icon: FontAwesomeIcons.chartLine,
                        color: KasbyColors.success,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              Obx(() {
                final currUser =
                    userController.getUserById(widget.user.id) ?? widget.user;
                return _buildWalletCard(
                  title: 'المعلق',
                  amount: currUser.pendingAmount,
                  icon: FontAwesomeIcons.clockRotateLeft,
                  color: KasbyColors.warning,
                );
              }),
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
              Obx(() {
                if (userController.isDetailsLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(
                        color: KasbyColors.primaryGold,
                      ),
                    ),
                  );
                }

                if (userController.selectedUserInvestments.isEmpty) {
                  return KasbyCard(
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'لا توجد استثمارات نشطة',
                          style: TextStyle(color: KasbyColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userController.selectedUserInvestments.length,
                  itemBuilder: (context, index) {
                    final inv = userController.selectedUserInvestments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: KasbyGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: KasbyColors.success.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                FontAwesomeIcons.chartPie,
                                color: KasbyColors.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.planName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'تاريخ الاستحقاق: ${DateFormat('yyyy/MM/dd').format(inv.endDate)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: KasbyColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${inv.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: KasbyColors.primaryGold,
                                  ),
                                ),
                                Text(
                                  '${inv.status}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: KasbyColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 24),

              // Documents Section
              if (widget.user.documents.isNotEmpty) ...[
                const Text(
                  'الوثائق المقدمة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.user.documents.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 300,
                        child: KasbyGlassCard(
                          padding: EdgeInsets.zero,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                widget
                                    .user
                                    .documents[index], // Assuming local assets for mock
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white54,
                                      size: 50,
                                    ),
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Text(
                                  'وثيقة ${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Verify/Reject Actions for Pending KYC
                if (widget.user.kycStatus == 'Pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('قبول وتوثيق'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KasbyColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _showVerifyConfirmation(
                              context,
                              userController,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('رفض الوثائق'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KasbyColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () =>
                                _showRejectDialog(context, userController),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Activity Log
              const Text(
                'سجل النشاط',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KasbyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (userController.isDetailsLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: KasbyColors.primaryGold,
                    ),
                  );
                }

                if (userController.selectedUserActivities.isEmpty) {
                  return KasbyCard(
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'لا يوجد نشاط مسجل',
                          style: TextStyle(color: KasbyColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userController.selectedUserActivities.length,
                  itemBuilder: (context, index) {
                    final activity =
                        userController.selectedUserActivities[index];
                    IconData icon;
                    Color iconColor;

                    switch (activity.type) {
                      case 'Security':
                        icon = Icons.security;
                        iconColor = KasbyColors.info;
                        break;
                      case 'Transaction':
                        icon = Icons.account_balance_wallet;
                        iconColor = KasbyColors.primaryGold;
                        break;
                      case 'System':
                        icon = Icons.settings;
                        iconColor = KasbyColors.textSecondary;
                        break;
                      default:
                        icon = Icons.info_outline;
                        iconColor = Colors.white70;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: KasbyGlassCard(
                        padding: const EdgeInsets.all(12),
                        opacity: 0.05,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: iconColor, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.action,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activity.details,
                                    style: const TextStyle(
                                      color: KasbyColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'MM/dd HH:mm',
                                'en',
                              ).format(activity.timestamp),
                              style: const TextStyle(
                                color: KasbyColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),

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
              Obx(() {
                if (userController.isDetailsLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: KasbyColors.primaryGold,
                    ),
                  );
                }

                if (userController.selectedUserTransactions.isEmpty) {
                  return KasbyCard(
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'لا توجد معاملات',
                          style: TextStyle(color: KasbyColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userController.selectedUserTransactions.length,
                  itemBuilder: (context, index) {
                    final txn = userController.selectedUserTransactions[index];
                    final isPositive =
                        txn.type == 'deposit' ||
                        txn.type == 'investment_profit';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: KasbyGlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    (isPositive
                                            ? KasbyColors.success
                                            : KasbyColors.error)
                                        .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPositive
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isPositive
                                    ? KasbyColors.success
                                    : KasbyColors.error,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    txn.type,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'yyyy/MM/dd HH:mm',
                                    ).format(txn.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: KasbyColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isPositive ? "+" : "-"}\$${txn.amount.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPositive
                                    ? KasbyColors.success
                                    : KasbyColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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

  void _showDeleteConfirmation(UserController controller) {
    KasbyConfirmationDialog.show(
      title: 'حذف المستخدم',
      message:
          'هل أنت متأكد من حذف المستخدم "${widget.user.name}" نهائياً؟ لا يمكن التراجع عن هذه العملية.',
      isDangerous: true,
      confirmText: 'حذف',
      onConfirm: () {
        controller.deleteUser(widget.user.id);
        Get.back(); // Back to list
      },
    );
  }

  void _showVerifyConfirmation(
    BuildContext context,
    UserController controller,
  ) {
    KasbyConfirmationDialog.show(
      title: 'توثيق الحساب',
      message:
          'هل أنت متأكد من قبول وثائق "${widget.user.name}" وتوثيق حسابه؟ سيتم ترقية الحساب إلى "Verification".',
      confirmText: 'توثيق',
      onConfirm: () {
        controller.verifyDocuments(widget.user.id);
      },
    );
  }

  void _showRejectDialog(BuildContext context, UserController controller) {
    final reasonController = TextEditingController();

    KasbyDialog.show(
      title: 'رفض الوثائق',
      content: Column(
        children: [
          const Text(
            'يرجى ذكر سبب رفض الوثائق لإشعار المستخدم.',
            style: TextStyle(color: KasbyColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          KasbyTextField(
            controller: reasonController,
            labelText: 'سبب الرفض',
            hintText: 'مثلاً: الصورة غير واضحة',
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (reasonController.text.isNotEmpty) {
              KasbyConfirmationDialog.show(
                message: 'هل أنت متأكد من رفض وثائق المستخدم؟',
                isDangerous: true,
                confirmText: 'رفض',
                onConfirm: () {
                  controller.rejectDocuments(
                    widget.user.id,
                    reasonController.text,
                  );
                },
              );
            } else {
              Get.snackbar('تنبيه', 'يرجى كتابة سبب الرفض');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: KasbyColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'رفض',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showAddBalanceDialog(BuildContext context, UserController controller) {
    final amountController = TextEditingController();
    KasbyDialog.show(
      title: 'إضافة رصيد',
      content: KasbyTextField(
        controller: amountController,
        labelText: 'المبلغ (\$)',
        keyboardType: TextInputType.number,
        prefixIcon: FontAwesomeIcons.dollarSign,
        validator: (v) => ValidationUtils.validateRequired(v, 'المبلغ'),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (amountController.text.isNotEmpty) {
              KasbyConfirmationDialog.show(
                message: 'إضافة \$${amountController.text} للمحفظة؟',
                onConfirm: () => controller.addBalance(
                  widget.user.id,
                  double.parse(amountController.text),
                  'إضافة رصيد من قبل الإدارة',
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: KasbyColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('تأكيد'),
        ),
      ],
    );
  }

  void _showDeductBalanceDialog(
    BuildContext context,
    UserController controller,
  ) {
    final amountController = TextEditingController();
    KasbyDialog.show(
      title: 'خصم رصيد',
      content: KasbyTextField(
        controller: amountController,
        labelText: 'المبلغ (\$)',
        keyboardType: TextInputType.number,
        prefixIcon: FontAwesomeIcons.dollarSign,
        validator: (v) => ValidationUtils.validateRequired(v, 'المبلغ'),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (amountController.text.isNotEmpty) {
              KasbyConfirmationDialog.show(
                message: 'خصم \$${amountController.text} من المحفظة؟',
                isDangerous: true,
                onConfirm: () => controller.deductBalance(
                  widget.user.id,
                  double.parse(amountController.text),
                  'خصم رصيد من قبل الإدارة',
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: KasbyColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('خصم'),
        ),
      ],
    );
  }

  Widget _buildCommunicationButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: KasbyColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, UserController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: KasbyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionItem(
                label: 'إضافة رصيد',
                icon: Icons.add_circle_outline,
                color: KasbyColors.success,
                onTap: () => _showAddBalanceDialog(context, controller),
              ),
              const SizedBox(width: 12),
              _buildActionItem(
                label: 'خصم رصيد',
                icon: Icons.remove_circle_outline,
                color: KasbyColors.error,
                onTap: () => _showDeductBalanceDialog(context, controller),
              ),
              const SizedBox(width: 12),
              Obx(() {
                final currUser =
                    controller.getUserById(widget.user.id) ?? widget.user;
                return _buildActionItem(
                  label: currUser.status == 'Active' ? 'حظر' : 'تفعيل',
                  icon: currUser.status == 'Active'
                      ? Icons.block
                      : Icons.check_circle_outline,
                  color: currUser.status == 'Active'
                      ? KasbyColors.error
                      : KasbyColors.success,
                  onTap: () {
                    KasbyConfirmationDialog.show(
                      title: currUser.status == 'Active'
                          ? 'حظر المستخدم'
                          : 'تفعيل المستخدم',
                      message: currUser.status == 'Active'
                          ? 'هل أنت متأكد من حظر المستخدم "${currUser.name}"؟'
                          : 'هل أنت متأكد من تفعيل المستخدم "${currUser.name}"؟',
                      isDangerous: currUser.status == 'Active',
                      onConfirm: () {
                        if (currUser.status == 'Active') {
                          controller.blockUser(widget.user.id);
                        } else {
                          controller.activateUser(widget.user.id);
                        }
                      },
                    );
                  },
                );
              }),
              const SizedBox(width: 12),
              _buildActionItem(
                label: 'تعديل',
                icon: Icons.edit_outlined,
                color: KasbyColors.info,
                onTap: () => Get.to(() => EditUserScreen(user: widget.user)),
              ),
              const SizedBox(width: 12),
              _buildActionItem(
                label: 'حظر / تفعيل',
                icon: Icons.security_rounded,
                color: KasbyColors.warning,
                onTap: () => controller.toggleBlockUser(widget.user.id),
              ),
              const SizedBox(width: 12),
              _buildActionItem(
                label: 'حذف',
                icon: Icons.delete_outline_rounded,
                color: KasbyColors.error,
                onTap: () => _showDeleteConfirmation(controller),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return KasbyGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url, {String? fallbackMessage}) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
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
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء محاولة فتح الرابط، تأكد من تثبيت التطبيق',
      );
    }
  }
}
