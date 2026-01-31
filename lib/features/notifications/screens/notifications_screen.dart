import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';

/// Notifications Screen
/// Send push notifications to users
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final selectedTarget = 'all'.obs;

    return Scaffold(
      appBar: AppBar(title: const Text('إرسال إشعار')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Selection
            const Text(
              'المستهدفون',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Column(
                children: [
                  _buildTargetOption(
                    'جميع المستخدمين',
                    'all',
                    selectedTarget,
                    FontAwesomeIcons.users,
                  ),
                  const SizedBox(height: 8),
                  _buildTargetOption(
                    'المستخدمون النشطون فقط',
                    'active',
                    selectedTarget,
                    FontAwesomeIcons.userCheck,
                  ),
                  const SizedBox(height: 8),
                  _buildTargetOption(
                    'المستثمرون',
                    'investors',
                    selectedTarget,
                    FontAwesomeIcons.chartLine,
                  ),
                  const SizedBox(height: 8),
                  _buildTargetOption(
                    'مستخدم محدد',
                    'specific',
                    selectedTarget,
                    FontAwesomeIcons.user,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notification Content
            const Text(
              'محتوى الإشعار',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            KasbyTextField(
              controller: titleController,
              hintText: 'عنوان الإشعار',
              prefixIcon: Icons.title,
            ),
            const SizedBox(height: 12),
            KasbyTextField(
              controller: messageController,
              hintText: 'نص الإشعار',
              maxLines: 5,
              prefixIcon: Icons.message,
            ),
            const SizedBox(height: 24),

            // Preview
            const Text(
              'معاينة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => KasbyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: KasbyColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            FontAwesomeIcons.bell,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kasby | كاسبي',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: KasbyColors.textPrimary,
                                ),
                              ),
                              Text(
                                'الآن',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: KasbyColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      titleController.text.isEmpty
                          ? 'عنوان الإشعار'
                          : titleController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      messageController.text.isEmpty
                          ? 'نص الإشعار سيظهر هنا'
                          : messageController.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: KasbyColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Send Button
            KasbyButton(
              text: 'إرسال الإشعار',
              onPressed: () {
                if (titleController.text.isEmpty ||
                    messageController.text.isEmpty) {
                  Get.snackbar('خطأ', 'الرجاء ملء جميع الحقول');
                  return;
                }

                Get.dialog(
                  AlertDialog(
                    backgroundColor: KasbyColors.surface,
                    title: const Text(
                      'تأكيد الإرسال',
                      style: TextStyle(color: KasbyColors.textPrimary),
                    ),
                    content: Text(
                      'هل أنت متأكد من إرسال الإشعار إلى ${_getTargetText(selectedTarget.value)}؟',
                      style: const TextStyle(color: KasbyColors.textBody),
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
                          Get.back();
                          Get.snackbar(
                            'نجح',
                            'تم إرسال الإشعار بنجاح',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          titleController.clear();
                          messageController.clear();
                        },
                        child: const Text(
                          'إرسال',
                          style: TextStyle(color: KasbyColors.primaryGold),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: FontAwesomeIcons.paperPlane,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetOption(
    String label,
    String value,
    RxString selectedTarget,
    IconData icon,
  ) {
    final isSelected = selectedTarget.value == value;
    return GestureDetector(
      onTap: () => selectedTarget.value = value,
      child: KasbyCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? KasbyColors.primaryGold.withValues(alpha: 0.2)
                    : KasbyColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? KasbyColors.primaryGold
                    : KasbyColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? KasbyColors.textPrimary
                      : KasbyColors.textBody,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: KasbyColors.primaryGold,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  String _getTargetText(String target) {
    switch (target) {
      case 'all':
        return 'جميع المستخدمين';
      case 'active':
        return 'المستخدمون النشطون فقط';
      case 'investors':
        return 'المستثمرون';
      case 'specific':
        return 'مستخدم محدد';
      default:
        return 'جميع المستخدمين';
    }
  }
}
