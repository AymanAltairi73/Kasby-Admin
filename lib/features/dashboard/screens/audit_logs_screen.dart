import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../controllers/audit_controller.dart';
import '../models/audit_log_model.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuditController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل النشاطات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchLogs(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.logs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: KasbyColors.primaryGold),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.logs.length,
          itemBuilder: (context, index) {
            final log = controller.logs[index];
            final isLast = index == controller.logs.length - 1;

            return IntrinsicHeight(
              child: Row(
                children: [
                  // Timeline line and dot
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getTypeColor(log.type),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getTypeColor(
                                log.type,
                              ).withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: KasbyColors.surface,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Log content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: KasbyCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    log.action,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: KasbyColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  log.icon,
                                  size: 16,
                                  color: _getTypeColor(log.type),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              log.details,
                              style: const TextStyle(
                                fontSize: 14,
                                color: KasbyColors.textBody,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: KasbyColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      log.adminName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: KasbyColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Directionality(
                                  textDirection: ui.TextDirection.ltr,
                                  child: Text(
                                    DateFormat(
                                      'HH:mm - dd/MM',
                                      'en',
                                    ).format(log.timestamp),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: KasbyColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Color _getTypeColor(AuditLogType type) {
    switch (type) {
      case AuditLogType.security:
        return KasbyColors.error;
      case AuditLogType.financial:
        return KasbyColors.success;
      case AuditLogType.userManagement:
        return KasbyColors.info;
      case AuditLogType.investment:
        return KasbyColors.primaryGold;
      case AuditLogType.system:
        return KasbyColors.warning;
    }
  }
}
