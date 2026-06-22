import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/marketplace_admin_controller.dart';

class MarketplaceOrdersScreen extends StatelessWidget {
  const MarketplaceOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceAdminController>();
    controller.loadOrders();
    final dateFmt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلبات')),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.orders.length,
            itemBuilder: (_, i) {
              final o = controller.orders[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KasbyGlassCard(
                  child: ExpansionTile(
                    title: Text('#${o.id}'),
                    subtitle: Text('${o.productName} • ${dateFmt.format(o.createdAt)}'),
                    trailing: Text(
                      '\$${o.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الحالة: ${o.status}'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: ['pending', 'processing', 'completed', 'cancelled', 'refunded']
                                  .map((s) => ActionChip(
                                        label: Text(s),
                                        backgroundColor: o.status == s
                                            ? KasbyColors.primaryGold.withValues(alpha: 0.2)
                                            : null,
                                        onPressed: () =>
                                            controller.updateOrderStatus(o.id, s),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )),
    );
  }
}
