import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/investment_controller.dart';
import '../models/investment_model.dart';

class EditInvestmentPlanScreen extends StatefulWidget {
  final InvestmentPlan plan;
  const EditInvestmentPlanScreen({super.key, required this.plan});

  @override
  State<EditInvestmentPlanScreen> createState() =>
      _EditInvestmentPlanScreenState();
}

class _EditInvestmentPlanScreenState extends State<EditInvestmentPlanScreen> {
  final controller = Get.find<InvestmentController>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController nameArController;
  late TextEditingController nameEnController;
  late TextEditingController descriptionArController;
  late TextEditingController profitPercentageController;
  late TextEditingController minAmountController;
  late TextEditingController maxAmountController;
  late TextEditingController availableAmountsController;

  String? selectedRiskLevel;
  File? _selectedImageFile;
  String? _currentImageUrl;
  bool isActive = true;

  final List<String> riskLevels = ['منخفض', 'متوسط', 'عالي'];
  final Map<String, String> riskLevelMap = {
    'منخفض': 'Low',
    'متوسط': 'Medium',
    'عالي': 'High',
  };
  final Map<String, String> riskLevelReverseMap = {
    'Low': 'منخفض',
    'Medium': 'متوسط',
    'High': 'عالي',
  };

  @override
  void initState() {
    super.initState();
    nameArController = TextEditingController(text: widget.plan.nameAr);
    nameEnController = TextEditingController(text: widget.plan.nameEn ?? '');
    descriptionArController = TextEditingController(
      text: widget.plan.descriptionAr,
    );
    profitPercentageController = TextEditingController(
      text: widget.plan.profitPercentage.toString(),
    );
    minAmountController = TextEditingController(
      text: widget.plan.minAmount.toString(),
    );
    maxAmountController = TextEditingController(
      text: widget.plan.maxAmount.toString(),
    );
    availableAmountsController = TextEditingController(
      text: widget.plan.availableAmounts?.join(', ') ?? '',
    );
    selectedRiskLevel = riskLevelReverseMap[widget.plan.riskLevel] ?? 'متوسط';
    _currentImageUrl = widget.plan.imagePath;
    isActive = widget.plan.isActive;
  }

  @override
  void dispose() {
    nameArController.dispose();
    nameEnController.dispose();
    descriptionArController.dispose();
    profitPercentageController.dispose();
    minAmountController.dispose();
    maxAmountController.dispose();
    availableAmountsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImageFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديث إعدادات الباقة'),
        actions: [
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.trashCan,
              color: KasbyColors.error,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context, controller, widget.plan),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 32),
            _buildFormSection(),
            const SizedBox(height: 24),
            _buildRiskExplanation(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: KasbyColors.primaryGold,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRiskExplanation() {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: KasbyColors.primaryGold,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'ما هو مستوى المخاطرة؟',
                style: TextStyle(
                  color: KasbyColors.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRiskInfo(
            'منخفض',
            'يركز على الأمان وحماية رأس المال، أرباح بسيطة ومستقرة.',
          ),
          _buildRiskInfo(
            'متوسط',
            'توازن بين الربح والأمان، مع تذبذب بسيط في النتائج.',
          ),
          _buildRiskInfo(
            'عالي',
            'يستهدف أرباحاً كبيرة جداً، لكنه يحمل مخاطرة عالية بخسارة جزء من المال.',
          ),
        ],
      ),
    );
  }

  Widget _buildRiskInfo(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: KasbyColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: desc),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('صورة الباقة المميزة'),
        GestureDetector(
          onTap: _pickImage,
          child: Hero(
            tag: 'plan_image_${widget.plan.id}',
            child: Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: KasbyColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: KasbyColors.primaryGold.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The Image itself
                    _selectedImageFile != null
                        ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                        : (_currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
                            ? (_currentImageUrl!
                                    .trim()
                                    .toLowerCase()
                                    .startsWith('http')
                                ? Image.network(
                                    _currentImageUrl!.trim(),
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    _currentImageUrl!,
                                    fit: BoxFit.cover,
                                  ))
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      KasbyColors.primaryGold
                                          .withValues(alpha: 0.1),
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: KasbyColors.primaryGold,
                                ),
                              )),

                    // Dark Overlay Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Change Photo Badge
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                size: 16, color: KasbyColors.primaryGold),
                            SizedBox(width: 8),
                            Text(
                              'تغيير الصورة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('اسم الباقة (بالعربي)'),
        KasbyTextField(
          controller: nameArController,
          hintText: 'مثال: الباقة الفضية',
          prefixIcon: Icons.title,
        ),
        const SizedBox(height: 16),
        _buildLabel('اسم الباقة (English)'),
        KasbyTextField(
          controller: nameEnController,
          hintText: 'Example: Silver Package',
          prefixIcon: Icons.language,
        ),
        const SizedBox(height: 16),
        _buildLabel('وصف الباقة (بالعربي)'),
        KasbyTextField(
          controller: descriptionArController,
          hintText: 'اشرح تفاصيل الباقة...',
          prefixIcon: Icons.description,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('نسبة الربح (%)'),
                  KasbyTextField(
                    controller: profitPercentageController,
                    hintText: '0.0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.percent,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('الحد الأدنى'),
                  KasbyTextField(
                    controller: minAmountController,
                    hintText: '0.0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('الحد الأقصى'),
                  KasbyTextField(
                    controller: maxAmountController,
                    hintText: '0.0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('المبالغ المتاحة (مفصولة بفاصلة)'),
        KasbyTextField(
          controller: availableAmountsController,
          hintText: '100, 500, 1000',
          prefixIcon: Icons.list,
        ),
        const SizedBox(height: 16),
        _buildLabel('مستوى المخاطرة'),
        _buildRiskLevelSelector(),
        const SizedBox(height: 16),
        _buildLabel('حالة النشاط'),
        _buildStatusSwitch(),
        const SizedBox(height: 40),
        Obx(
          () => KasbyButton(
            text: 'حفظ التغييرات',
            isLoading: controller.isLoading.value,
            onPressed: _saveChanges,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskLevelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: KasbyColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: KasbyColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'مستوى المخاطرة:',
            style: TextStyle(color: KasbyColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRiskLevel,
                dropdownColor: KasbyColors.surface,
                isExpanded: true,
                items: riskLevels
                    .map(
                      (lvl) => DropdownMenuItem(
                        value: lvl,
                        child: Text(
                          lvl,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedRiskLevel = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'حالة الخطة (نشط/متوقف)',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        Switch(
          value: isActive,
          onChanged: (val) => setState(() => isActive = val),
          activeColor: KasbyColors.primaryGold,
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    String? imageUrl = _currentImageUrl;

    if (_selectedImageFile != null) {
      imageUrl = await controller.uploadPlanImage(_selectedImageFile!);
      if (imageUrl == null) {
        Get.snackbar('خطأ', 'فشل في رفع الصورة');
        return;
      }
    }

    final List<double> availableAmounts =
        availableAmountsController.text.isNotEmpty
        ? availableAmountsController.text
              .split(',')
              .map((e) => double.tryParse(e.trim()) ?? 0)
              .where((e) => e > 0)
              .toList()
        : [];

    final updates = {
      'nameAr': nameArController.text,
      'nameEn': nameEnController.text,
      'descriptionAr': descriptionArController.text,
      'profitPercentage': double.tryParse(profitPercentageController.text) ?? 0,
      'minAmount': double.tryParse(minAmountController.text) ?? 0,
      'maxAmount': double.tryParse(maxAmountController.text) ?? 0,
      'availableAmounts': availableAmounts,
      'riskLevel': riskLevelMap[selectedRiskLevel] ?? 'Medium',
      'imagePath': imageUrl,
      'isActive': isActive,
    };

    try {
      await controller.updatePlan(widget.plan.id, updates);
      
      // Show success dialog
      Get.dialog(
        AlertDialog(
          backgroundColor: KasbyColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: KasbyColors.success),
              SizedBox(width: 10),
              Text('نجاح', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'تم تحديث الباقة بنجاح',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                Get.back(); // Go back to plans screen
              },
              child: const Text('حسناً', style: TextStyle(color: KasbyColors.primaryGold)),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      // Error is already logged and snackbar shown by controller,
      // but we can add secondary handling here if needed.
    }
  }

  void _confirmDelete(
    BuildContext context,
    InvestmentController controller,
    InvestmentPlan plan,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'حذف الخطة',
          style: TextStyle(color: KasbyColors.error),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${plan.nameAr}" نهائياً؟ سيتم إلغاء تفعيلها.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              controller.deletePlan(plan.id);
              Get.back();
              Get.back();
            },
            child: const Text(
              'تأكيد',
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
