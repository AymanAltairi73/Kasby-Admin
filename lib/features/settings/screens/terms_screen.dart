import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/settings_management_controller.dart';
import '../models/settings_models.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsManagementController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'إدارة الشروط والأحكام',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, controller),
        backgroundColor: KasbyColors.primaryGold,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: const Text(
          'إضافة بند جديد',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          _buildCelestialBackground(),
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: KasbyColors.primaryGold,
                  ),
                );
              }

              if (controller.terms.isEmpty) {
                return _buildEmptyState(context, controller);
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadSettings(),
                color: KasbyColors.primaryGold,
                child: ReorderableListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                  itemCount: controller.terms.length + 1,
                  proxyDecorator: (widget, index, animation) {
                    return Material(color: Colors.transparent, child: widget);
                  },
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < 1 || newIndex < 1) {
                      return; // Header cannot be reordered
                    }
                    controller.reorderTerms(oldIndex - 1, newIndex - 1);
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        key: const ValueKey('header'),
                        child: _buildHeader(),
                      );
                    }

                    final term = controller.terms[index - 1];
                    return Padding(
                      key: ValueKey(term.id),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTermCard(
                        context,
                        controller,
                        term,
                        index: index,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    SettingsManagementController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeader(),
          Icon(
            FontAwesomeIcons.fileSignature,
            size: 80,
            color: KasbyColors.primaryGold.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد بنود حالياً',
            style: TextStyle(color: KasbyColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            'ابدأ بإضافة أول بند لاتفاقية الاستخدام',
            style: TextStyle(
              color: KasbyColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 14,
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                KasbyColors.primaryGold.withValues(alpha: 0.2),
                KasbyColors.primaryGold.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: KasbyColors.primaryGold.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            FontAwesomeIcons.gavel,
            size: 40,
            color: KasbyColors.primaryGold,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ميثاق السياسات والضوابط',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: KasbyColors.primaryGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTermCard(
    BuildContext context,
    SettingsManagementController controller,
    TermSection term, {
    required int index,
  }) {
    return KasbyGlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: KasbyColors.primaryGold.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$index',
                        style: const TextStyle(
                          color: KasbyColors.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        term.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_indicator_rounded,
                        color: KasbyColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  term.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: KasbyColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_note_rounded,
                      color: KasbyColors.info,
                      label: 'تعديل',
                      onTap: () =>
                          _showEditDialog(context, controller, term: term),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_sweep_rounded,
                      color: KasbyColors.error,
                      label: 'حذف',
                      onTap: () =>
                          _showDeleteConfirmation(context, controller, term.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
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

  void _showEditDialog(
    BuildContext context,
    SettingsManagementController controller, {
    TermSection? term,
  }) {
    final titleController = TextEditingController(text: term?.title);
    final contentController = TextEditingController(text: term?.content);
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 40, spreadRadius: 10),
          ],
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: KasbyColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        term == null
                            ? Icons.add_rounded
                            : Icons.edit_note_rounded,
                        color: KasbyColors.primaryGold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      term == null ? 'إضافة بند جديد' : 'تعديل بند الاتفاقية',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                KasbyTextField(
                  controller: titleController,
                  labelText: 'عنوان البند',
                  hintText: 'مثال: سياسة الخصوصية وحماية البيانات',
                  prefixIcon: Icons.title_rounded,
                  validator: (v) => v!.isEmpty ? 'يرجى إدخال العنوان' : null,
                ),
                const SizedBox(height: 20),
                KasbyTextField(
                  controller: contentController,
                  labelText: 'نص الاتفاقية المطور',
                  hintText: 'اكتب الشروط التفصيلية هنا...',
                  maxLines: 8,
                  prefixIcon: Icons.subject_rounded,
                  validator: (v) => v!.isEmpty ? 'يرجى إدخال المحتوى' : null,
                ),
                const SizedBox(height: 32),
                Obx(() => KasbyButton(
                  text: term == null
                      ? 'إضافة البند الآن'
                      : 'حفظ التعديلات النهائية',
                  icon: term == null
                      ? Icons.check_circle_rounded
                      : Icons.save_rounded,
                  isLoading: controller.isSaving.value,
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      bool success;
                      if (term == null) {
                        success = await controller.addTerm(
                          titleController.text,
                          contentController.text,
                        );
                      } else {
                        success = await controller.updateTerm(
                          term.id,
                          titleController.text,
                          contentController.text,
                        );
                      }
                      
                      if (success) {
                        Get.back();
                        Get.snackbar(
                          'نجاح',
                          term == null ? 'تم إضافة البند بنجاح' : 'تم تحديث البند بنجاح',
                          backgroundColor: KasbyColors.success.withOpacity(0.9),
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } else {
                        Get.snackbar(
                          'خطأ',
                          'فشل في العملية، يرجى المحاولة مرة أخرى',
                          backgroundColor: KasbyColors.error.withOpacity(0.9),
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    }
                  },
                )),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'تجاهل التغييرات',
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
      Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: KasbyColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: KasbyColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'هل أنت متأكد؟',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'سيتم حذف هذا البند نهائياً من اتفاقية الاستخدام ولن تتمكن من استعادته.',
                textAlign: TextAlign.center,
                style: TextStyle(color: KasbyColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: KasbyButton(
                      text: 'إلغاء',
                      isOutlined: true,
                      backgroundColor: KasbyColors.textSecondary,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KasbyButton(
                      text: 'حذف نهائي',
                      backgroundColor: KasbyColors.error,
                      onPressed: () async {
                        final success = await controller.deleteTerm(id);
                        if (success) {
                          Get.back();
                          Get.snackbar(
                            'تم الحذف',
                            'تم حذف البند بنجاح',
                            backgroundColor: KasbyColors.error.withOpacity(0.9),
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
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

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF0F172A)),
        _buildOrb(
          top: -100,
          left: -100,
          size: 400,
          color: KasbyColors.info.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -150,
          right: -150,
          size: 500,
          color: KasbyColors.primaryGold.withValues(alpha: 0.05),
        ),
        _buildOrb(
          top: 200,
          right: -50,
          size: 300,
          color: KasbyColors.primaryGoldLight.withValues(alpha: 0.03),
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
