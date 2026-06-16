import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/agent_applications_controller.dart';

class AgentApplicationsScreen extends StatefulWidget {
  const AgentApplicationsScreen({super.key});

  @override
  State<AgentApplicationsScreen> createState() =>
      _AgentApplicationsScreenState();
}

class _AgentApplicationsScreenState extends State<AgentApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    AppLoggerService.debugTrace(
      className: 'AgentApplicationsScreen',
      method: 'initState',
      feature: 'Agents',
      status: 'INFO',
      message: 'Screen mounted',
    );
  }

  @override
  void dispose() {
    AppLoggerService.debugTrace(
      className: 'AgentApplicationsScreen',
      method: 'dispose',
      feature: 'Agents',
      status: 'INFO',
      message: 'Screen unmounted',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AgentApplicationsController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('طلبات الانضمام كوكيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.loadApplications(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Celestial Background
          RepaintBoundary(
            child: Container(
              color: const Color(0xFF0F172A),
              child: Stack(
                children: [
                   Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: KasbyColors.primaryGold.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 100),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.applications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: KasbyColors.primaryGold),
                    );
                  }

                  if (controller.applications.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => controller.loadApplications(),
                      color: KasbyColors.primaryGold,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 150),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.drafts_outlined,
                                  size: 64,
                                  color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'لا توجد طلبات انضمام حالياً',
                                  style: TextStyle(
                                    color: KasbyColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.loadApplications(),
                    color: KasbyColors.primaryGold,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: controller.applications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final app = controller.applications[index];
                        return _buildApplicationCard(context, app, controller);
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

  Widget _buildApplicationCard(BuildContext context, dynamic app, AgentApplicationsController controller) {
    Color statusColor;
    String statusText;
    switch (app.status) {
      case 'approved':
        statusColor = KasbyColors.success;
        statusText = 'تمت الموافقة';
        break;
      case 'rejected':
        statusColor = KasbyColors.error;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = KasbyColors.warning;
        statusText = 'قيد المراجعة';
    }

    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                DateFormat('yyyy/MM/dd HH:mm').format(app.createdAt.toLocal()),
                style: const TextStyle(
                  color: KasbyColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: KasbyColors.primaryGold.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: KasbyColors.primaryGold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المعرف: ${app.userId.substring(0, 8)}...',
                      style: const TextStyle(
                        fontSize: 12,
                        color: KasbyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.phone, 'رقم الهاتف', app.phone),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_city, 'المدينة', app.city),
                if (app.experienceDesc != null && app.experienceDesc!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  const Text(
                    'الخبرة / الموقع الفعلي:',
                    style: TextStyle(
                      color: KasbyColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.experienceDesc!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (app.status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      KasbyConfirmationDialog.show(
                        title: 'رفض الطلب',
                        message: 'هل أنت متأكد من رفض هذا الطلب؟',
                        isDangerous: true,
                        confirmText: 'رفض',
                        onConfirm: () {
                          Get.back();
                          controller.rejectApplication(app.id);
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KasbyColors.error,
                      side: const BorderSide(color: KasbyColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      KasbyConfirmationDialog.show(
                        title: 'قبول كوكيل',
                        message: 'هل أنت متأكد من قبول "${app.fullName}" كوكيل؟ سيتم منحه صلاحيات إدارة المبالغ.',
                        confirmText: 'موافقة وتعيين',
                        onConfirm: () {
                          Get.back();
                          controller.approveApplication(app.id);
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KasbyColors.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('موافقة', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KasbyColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: KasbyColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
