import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_button.dart';
import '../controllers/notification_template_controller.dart';
import '../controllers/notification_controller.dart';

class NotificationTemplatesScreen extends StatelessWidget {
  const NotificationTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationTemplateController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('قوالب الإشعارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTemplates,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateDialog(context, controller),
        backgroundColor: KasbyColors.primaryGold,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'قالب جديد',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.templates.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: KasbyColors.primaryGold),
          );
        }

        if (controller.templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.fileLines,
                  size: 56,
                  color: KasbyColors.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد قوالب',
                  style: TextStyle(
                    color: KasbyColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أنشئ قوالب لتسريع إرسال الإشعارات',
                  style: TextStyle(
                    color: KasbyColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadTemplates,
          color: KasbyColors.primaryGold,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: controller.templates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final template = controller.templates[index];
              return _buildTemplateCard(context, template, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    NotificationTemplate template,
    NotificationTemplateController controller,
  ) {
    final catLabel =
        NotificationTemplateController.categoryLabels[template.category] ??
            template.category;
    final catColor = _categoryColor(template.category);

    return KasbyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: catColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  catLabel,
                  style: TextStyle(
                    color: catColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  template.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: KasbyColors.textSecondary),
                onSelected: (value) {
                  switch (value) {
                    case 'use':
                      _useTemplate(template);
                    case 'edit':
                      _showTemplateDialog(context, controller, existing: template);
                    case 'delete':
                      _confirmDelete(template, controller);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'use',
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.paperPlane, size: 14, color: KasbyColors.primaryGold),
                        SizedBox(width: 10),
                        Text('استخدام القالب'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.penToSquare, size: 14, color: KasbyColors.info),
                        SizedBox(width: 10),
                        Text('تعديل'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.trash, size: 14, color: KasbyColors.error),
                        SizedBox(width: 10),
                        Text('حذف', style: TextStyle(color: KasbyColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          Text(
            template.titleTemplate,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: KasbyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            template.messageTemplate,
            style: const TextStyle(
              color: KasbyColors.textSecondary,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (template.variables.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: template.variables.map((v) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: KasbyColors.primaryGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: KasbyColors.primaryGold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '{{$v}}',
                    style: const TextStyle(
                      color: KasbyColors.primaryGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _useTemplate(NotificationTemplate template) {
    try {
      Get.find<NotificationController>();
    } catch (_) {
      Get.lazyPut(() => NotificationController(), fenix: true);
    }
    Get.toNamed(
      '/add-notification',
      arguments: {
        'title': template.titleTemplate,
        'message': template.messageTemplate,
      },
    );
  }

  void _confirmDelete(
    NotificationTemplate template,
    NotificationTemplateController controller,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(color: KasbyColors.textPrimary),
        ),
        content: Text(
          'هل تريد حذف قالب "${template.name}"؟',
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
              controller.deleteTemplate(template.id);
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

  void _showTemplateDialog(
    BuildContext context,
    NotificationTemplateController controller, {
    NotificationTemplate? existing,
  }) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final titleCtrl = TextEditingController(text: existing?.titleTemplate ?? '');
    final messageCtrl = TextEditingController(text: existing?.messageTemplate ?? '');
    final selectedCategory = (existing?.category ?? 'general').obs;

    Get.dialog(
      Dialog(
        backgroundColor: KasbyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'تعديل القالب' : 'إنشاء قالب جديد',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KasbyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              KasbyTextField(
                controller: nameCtrl,
                hintText: 'اسم القالب',
                prefixIcon: FontAwesomeIcons.tag,
              ),
              const SizedBox(height: 12),
              const Text(
                'التصنيف',
                style: TextStyle(
                  color: KasbyColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: NotificationTemplateController.categories.map((cat) {
                    final label =
                        NotificationTemplateController.categoryLabels[cat] ?? cat;
                    final isSelected = selectedCategory.value == cat;
                    final color = _categoryColor(cat);
                    return GestureDetector(
                      onTap: () => selectedCategory.value = cat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : KasbyColors.textSecondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? color : KasbyColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              KasbyTextField(
                controller: titleCtrl,
                hintText: 'عنوان الإشعار (مثال: مرحباً {{user_name}})',
                prefixIcon: FontAwesomeIcons.heading,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: messageCtrl,
                hintText: 'نص الإشعار (استخدم {{variable}} للمتغيرات)',
                prefixIcon: FontAwesomeIcons.alignRight,
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              Text(
                'المتغيرات المتاحة: {{user_name}}, {{amount}}, {{currency}}, {{plan_name}}, {{date}}',
                style: TextStyle(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: KasbyButton(
                      text: 'إلغاء',
                      isOutlined: true,
                      onPressed: () => Get.back(),
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KasbyButton(
                      text: isEditing ? 'حفظ التعديل' : 'إنشاء',
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty ||
                            titleCtrl.text.trim().isEmpty ||
                            messageCtrl.text.trim().isEmpty) {
                          Get.snackbar('خطأ', 'الرجاء ملء جميع الحقول');
                          return;
                        }

                        final allText =
                            '${titleCtrl.text} ${messageCtrl.text}';
                        final variables = controller.extractVariables(allText);

                        final template = NotificationTemplate(
                          id: existing?.id ?? '',
                          name: nameCtrl.text.trim(),
                          titleTemplate: titleCtrl.text.trim(),
                          messageTemplate: messageCtrl.text.trim(),
                          category: selectedCategory.value,
                          variables: variables,
                        );

                        Get.back();
                        if (isEditing) {
                          controller.updateTemplate(existing.id, template);
                        } else {
                          controller.addTemplate(template);
                        }
                      },
                      height: 44,
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'financial':
        return KasbyColors.success;
      case 'investment':
        return KasbyColors.primaryGold;
      case 'promotion':
        return KasbyColors.glowOrange;
      case 'system':
        return KasbyColors.error;
      default:
        return KasbyColors.info;
    }
  }
}
