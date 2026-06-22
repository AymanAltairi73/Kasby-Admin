import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/admin_metric_chip.dart';
import '../controllers/wallet_controller.dart';
import '../../users/screens/user_details_screen.dart';
import '../../users/controllers/user_controller.dart';

class WalletManagementScreen extends StatelessWidget {
  const WalletManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WalletController());
    final fmt = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المحافظ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadWallets,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AdminSearchField(
              hint: 'بحث بالاسم أو البريد...',
              onChanged: controller.updateSearch,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.wallets.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: KasbyColors.primaryGold),
                );
              }

              if (controller.hasError.value && controller.wallets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: KasbyColors.error, size: 48),
                      const SizedBox(height: 12),
                      const Text('تعذّر تحميل المحافظ'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: controller.loadWallets,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              final list = controller.filteredWallets;

              return RefreshIndicator(
                onRefresh: controller.loadWallets,
                color: KasbyColors.primaryGold,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        AdminMetricChip(
                          label: 'متاح',
                          value: fmt.format(controller.totalAvailable),
                          color: KasbyColors.success,
                          icon: FontAwesomeIcons.wallet,
                        ),
                        const SizedBox(width: 10),
                        AdminMetricChip(
                          label: 'مستثمر',
                          value: fmt.format(controller.totalInvested),
                          color: KasbyColors.info,
                          icon: FontAwesomeIcons.chartLine,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        AdminMetricChip(
                          label: 'أرباح',
                          value: fmt.format(controller.totalProfit),
                          color: KasbyColors.primaryGold,
                          icon: FontAwesomeIcons.coins,
                        ),
                        const SizedBox(width: 10),
                        AdminMetricChip(
                          label: 'معلّق',
                          value: fmt.format(controller.totalPending),
                          color: KasbyColors.warning,
                          icon: FontAwesomeIcons.clock,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${list.length} محفظة',
                      style: const TextStyle(
                        color: KasbyColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (list.isEmpty)
                      const KasbyGlassCard(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('لا توجد محافظ مطابقة')),
                        ),
                      )
                    else
                      ...list.map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: KasbyGlassCard(
                              onTap: () {
                                final userController = Get.find<UserController>();
                                final user = userController.getUserById(w.userId);
                                if (user != null) {
                                  Get.to(() => UserDetailsScreen(user: user));
                                } else {
                                  Get.snackbar(
                                    'خطأ',
                                    'لم يتم العثور على بيانات المستخدم',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        KasbyColors.primaryGold.withValues(alpha: 0.15),
                                    child: Text(
                                      w.userName.isNotEmpty
                                          ? w.userName.characters.first
                                          : '?',
                                      style: const TextStyle(
                                        color: KasbyColors.primaryGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          w.userName.isNotEmpty ? w.userName : 'مستخدم',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          w.email,
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
                                        fmt.format(w.available),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: KasbyColors.success,
                                        ),
                                      ),
                                      Text(
                                        'استثمار ${fmt.format(w.invested)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: KasbyColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
