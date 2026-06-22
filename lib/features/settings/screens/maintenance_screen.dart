import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/settings_management_controller.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  late final SettingsManagementController controller;
  late final TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SettingsManagementController>();
    messageController = TextEditingController(
      text: controller.maintenanceMessage.value,
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'وضع الصيانة',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          RepaintBoundary(child: _buildCelestialBackground()),
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: KasbyColors.primaryGold,
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildControlHeader(controller.isMaintenanceMode.value),
                    const SizedBox(height: 32),

                    // Main Toggle Card
                    KasbyGlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تفعيل وضع الصيانة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'سيتم حظر وصول المستخدمين للتطبيق',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: KasbyColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                               Switch(
                                value: controller.isMaintenanceMode.value,
                                onChanged: (value) async {
                                  final success =
                                      await controller.toggleMaintenance(value);
                                  if (success) {
                                    Get.snackbar(
                                      'وضع الصيانة',
                                      'تم ${value ? 'تفعيل' : 'تعطيل'} وضع الصيانة بنجاح',
                                      backgroundColor:
                                          KasbyColors.warning.withValues(alpha: 0.9),
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                },
                                activeThumbColor: KasbyColors.primaryGold,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Message Card
                    KasbyGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'رسالة التنبيه للمستخدمين',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: KasbyColors.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: messageController,
                            hintText: 'اكتب رسالة الصيانة هنا...',
                            maxLines: 4,
                            onChanged: (val) =>
                                controller.maintenanceMessage.value = val,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'معاينة الرسالة:',
                            style: TextStyle(
                              fontSize: 12,
                              color: KasbyColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Obx(
                              () => Text(
                                controller.maintenanceMessage.value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Action Buttons
                    KasbyButton(
                      text: 'حفظ و تحديث الحالة',
                      onPressed: () async {
                        final success =
                            await controller.updateMaintenanceMessage(
                              messageController.text,
                            );
                        if (success) {
                          Get.snackbar(
                            'تم الحفظ',
                            'تم تحديث إعدادات وضع الصيانة بنجاح',
                            backgroundColor: KasbyColors.success.withValues(
                              alpha: 0.8,
                            ),
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildControlHeader(bool isMaintenanceActive) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (isMaintenanceActive
                            ? KasbyColors.error
                            : KasbyColors.primaryGold)
                        .withValues(alpha: 0.1),
              ),
            ),

            Icon(
              isMaintenanceActive
                  ? Icons.engineering_rounded
                  : Icons.lock_open_rounded,
              size: 50,
              color: isMaintenanceActive
                  ? KasbyColors.error
                  : KasbyColors.primaryGold,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isMaintenanceActive
              ? 'وضع الصيانة نشط حالياً'
              : 'النظام يعمل بشكل طبيعي',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isMaintenanceActive
                ? KasbyColors.error
                : KasbyColors.primaryGold,
          ),
        ),
      ],
    );
  }

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        Container(color: Theme.of(context).scaffoldBackgroundColor),
        _buildOrb(
          top: -50,
          right: -100,
          size: 300,
          color: KasbyColors.error.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -100,
          left: -100,
          size: 400,
          color: KasbyColors.primaryGold.withValues(alpha: 0.05),
        ),
      ],
    );
  }

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
            ],
          ),
        ),
      ),
    );
  }
}
