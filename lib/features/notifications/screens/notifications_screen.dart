import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import 'package:intl/intl.dart';
import '../controllers/notification_controller.dart';

/// Notifications Screen
/// Send push notifications to users
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final selectedTarget = 'all'.obs;
    final notificationTitle = ''.obs;
    final notificationMessage = ''.obs;

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
              onChanged: (value) => notificationTitle.value = value,
            ),
            const SizedBox(height: 12),
            KasbyTextField(
              controller: messageController,
              hintText: 'نص الإشعار',
              maxLines: 5,
              prefixIcon: Icons.message,
              onChanged: (value) => notificationMessage.value = value,
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
                      notificationTitle.value.isEmpty
                          ? 'عنوان الإشعار'
                          : notificationTitle.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificationMessage.value.isEmpty
                          ? 'نص الإشعار سيظهر هنا'
                          : notificationMessage.value,
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

            // Scheduling
            const Text(
              'وقت الإرسال',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  _buildScheduleChip('الآن', true, () {}),
                  const SizedBox(width: 8),
                  _buildScheduleChip(
                    'جدولة...',
                    false,
                    () => _showDateTimePicker(context),
                  ),
                ],
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
                          final nController = Get.put(NotificationController());
                          nController.sendNotification(
                            titleController.text,
                            messageController.text,
                            selectedTarget.value,
                          );
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
            const SizedBox(height: 40),

            // Notification History
            const Text(
              'الإشعارات الأخيرة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildNotificationHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? KasbyColors.primaryGold.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? KasbyColors.primaryGold
                : KasbyColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? KasbyColors.primaryGold
                : KasbyColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showDateTimePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    // Mock scheduling for UI demonstration
    if (date != null) {
      Get.snackbar('تمت الجدولة', 'سيتم إرسال الإشعار في التاريخ المحدد');
    }
  }

  Widget _buildNotificationHistory() {
    final nController = Get.put(NotificationController());
    return Obx(() {
      if (nController.sentNotifications.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'لا توجد إشعارات مرسلة',
              style: TextStyle(color: KasbyColors.textSecondary),
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: nController.sentNotifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final n = nController.sentNotifications[index];
          return KasbyCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  n['status'] == 'Sent' ? Icons.check_circle : Icons.schedule,
                  color: n['status'] == 'Sent'
                      ? KasbyColors.success
                      : KasbyColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        n['message'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: KasbyColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(n['sentAt']),
                  style: const TextStyle(
                    fontSize: 11,
                    color: KasbyColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
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
