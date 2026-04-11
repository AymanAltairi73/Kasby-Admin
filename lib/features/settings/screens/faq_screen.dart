import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/settings_management_controller.dart';
import '../models/settings_models.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsManagementController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الأسئلة الشائعة',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_comment_outlined,
              color: KasbyColors.primaryGold,
            ),
            onPressed: () => _showEditDialog(context, controller),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildCelestialBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => controller.loadSettings(),
              color: KasbyColors.primaryGold,
              child: Obx(
                () {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: KasbyColors.primaryGold,
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    itemCount: controller.faqs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildHeader();
                      final faq = controller.faqs[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildFaqItem(
                          context,
                          controller,
                          faq,
                          index: index,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: KasbyColors.primaryGold.withValues(alpha: 0.1),
            border: Border.all(
              color: KasbyColors.primaryGold.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.help_outline_rounded,
            size: 48,
            color: KasbyColors.primaryGold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'هل لديك أي استفسار؟',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    SettingsManagementController controller,
    FAQItem faq, {
    required int index,
  }) {
    return KasbyGlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          iconColor: KasbyColors.primaryGold,
          collapsedIconColor: KasbyColors.textSecondary,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: KasbyColors.info),
                onPressed: () => _showEditDialog(context, controller, faq: faq),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: KasbyColors.error,
                ),
                onPressed: () =>
                    _showDeleteConfirmation(context, controller, faq.id),
              ),
              const Icon(Icons.expand_more, color: KasbyColors.textSecondary),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                faq.answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: KasbyColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    SettingsManagementController controller, {
    FAQItem? faq,
  }) {
    final questionController = TextEditingController(text: faq?.question);
    final answerController = TextEditingController(text: faq?.answer);

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  faq == null ? 'إضافة سؤال جديد' : 'تعديل السؤال',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                KasbyTextField(
                  controller: questionController,
                  labelText: 'السؤال',
                  hintText: 'مثال: كيف يمكنني إضافة مشرف؟',
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: answerController,
                  labelText: 'الإجابة',
                  hintText: 'اكتب الإجابة هنا...',
                  maxLines: 5,
                ),
                const SizedBox(height: 32),
                Obx(() => KasbyButton(
                  text: faq == null ? 'إضافة' : 'حفظ التعديلات',
                  isLoading: controller.isSaving.value,
                  onPressed: () async {
                    bool success;
                    if (faq == null) {
                      success = await controller.addFAQ(
                        questionController.text,
                        answerController.text,
                      );
                    } else {
                      success = await controller.updateFAQ(
                        faq.id,
                        questionController.text,
                        answerController.text,
                      );
                    }
                    
                    if (success) {
                      Get.back();
                      Get.snackbar(
                        'نجاح',
                        faq == null ? 'تم إضافة السؤال الشائع بنجاح' : 'تم تحديث السؤال الشائع بنجاح',
                        backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
                      Get.snackbar(
                        'خطأ',
                        'فشل في العملية، يرجى المحاولة مرة أخرى',
                        backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                )),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: KasbyColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    SettingsManagementController controller,
    String id,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف هذا السؤال؟',
          style: TextStyle(color: KasbyColors.textSecondary),
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
            onPressed: () async {
              final success = await controller.deleteFAQ(id);
              if (success) {
                Get.back();
                Get.snackbar(
                  'نجاح',
                  'تم حذف السؤال الشائع بنجاح',
                  backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF0F172A)),
        _buildOrb(
          top: 100,
          right: -100,
          size: 350,
          color: KasbyColors.info.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -100,
          left: -100,
          size: 450,
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
    );
  }
}
