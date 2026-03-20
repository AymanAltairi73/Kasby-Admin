import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../models/ad_model.dart';
import '../controllers/ad_controller.dart';

class AddEditAdScreen extends StatefulWidget {
  final Ad? ad;

  const AddEditAdScreen({super.key, this.ad});

  @override
  State<AddEditAdScreen> createState() => _AddEditAdScreenState();
}

class _AddEditAdScreenState extends State<AddEditAdScreen> {
  final controller = Get.find<AdController>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController titleArController;
  late TextEditingController titleEnController;
  late TextEditingController descArController;
  late TextEditingController descEnController;
  
  File? _selectedImageFile;
  String? _currentImageUrl;
  final isActive = true.obs;
  final isUploading = false.obs;

  @override
  void initState() {
    super.initState();
    titleArController = TextEditingController(text: widget.ad?.titleAr);
    titleEnController = TextEditingController(text: widget.ad?.titleEn);
    descArController = TextEditingController(text: widget.ad?.descriptionAr);
    descEnController = TextEditingController(text: widget.ad?.descriptionEn);
    _currentImageUrl = widget.ad?.imageUrl;
    isActive.value = widget.ad?.isActive ?? true;
  }

  @override
  void dispose() {
    titleArController.dispose();
    titleEnController.dispose();
    descArController.dispose();
    descEnController.dispose();
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(widget.ad == null ? 'إضافة إعلان جديد' : 'تعديل الإعلان'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('صورة الإعلان'),
            const SizedBox(height: 16),
            _buildImagePickerSection(),
            const SizedBox(height: 32),
            
            _buildSectionHeader('المعلومات الأساسية'),
            const SizedBox(height: 16),
            KasbyTextField(
              controller: titleArController,
              labelText: 'العنوان (بالعربية)',
              hintText: 'مثال: عرض الاستثمار الذهبي',
            ),
            const SizedBox(height: 16),
            KasbyTextField(
              controller: titleEnController,
              labelText: 'العنوان (بالإنجليزي) - اختياري',
              hintText: 'Example: Golden Investment Offer',
            ),
            const SizedBox(height: 32),
            
            _buildSectionHeader('وصف الإعلان'),
            const SizedBox(height: 16),
            KasbyTextField(
              controller: descArController,
              labelText: 'الوصف (بالعربية)',
              hintText: 'وصف قصير للإعلان',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            KasbyTextField(
              controller: descEnController,
              labelText: 'الوصف (بالإنجليزي) - اختياري',
              hintText: 'Short description',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            
            _buildSectionHeader('الحالة'),
            const SizedBox(height: 16),
            Obx(
              () => Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: CheckboxListTile(
                  title: const Text(
                    'نشط ومفعل للعرض',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  value: isActive.value,
                  onChanged: (val) => isActive.value = val ?? true,
                  activeColor: KasbyColors.primaryGold,
                  checkColor: Colors.black,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Obx(() => KasbyButton(
              text: widget.ad == null ? 'إضافة الإعلان' : 'حفظ التغييرات',
              isLoading: controller.isLoading.value || isUploading.value,
              onPressed: _saveAd,
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10, width: 1),
          image: _selectedImageFile != null
              ? DecorationImage(image: FileImage(_selectedImageFile!), fit: BoxFit.cover)
              : (_currentImageUrl != null
                  ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                  : null),
        ),
        child: _selectedImageFile == null && _currentImageUrl == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded, color: KasbyColors.primaryGold, size: 50),
                  SizedBox(height: 8),
                  Text('اضغط لإضافة صورة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              )
            : Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, color: KasbyColors.primaryGold, size: 16),
                      SizedBox(width: 4),
                      Text('تغيير الصورة', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: KasbyColors.primaryGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 2,
          color: KasbyColors.primaryGold.withOpacity(0.3),
        ),
      ],
    );
  }

  Future<void> _saveAd() async {
    if (titleArController.text.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال العنوان بالعربية',
          backgroundColor: KasbyColors.error.withOpacity(0.8), colorText: Colors.white);
      return;
    }

    if (_selectedImageFile == null && _currentImageUrl == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار صورة للإعلان',
          backgroundColor: KasbyColors.error.withOpacity(0.8), colorText: Colors.white);
      return;
    }

    isUploading.value = true;
    String? imageUrl = _currentImageUrl;

    if (_selectedImageFile != null) {
      imageUrl = await controller.uploadAdImage(_selectedImageFile!);
      if (imageUrl == null) {
        isUploading.value = false;
        Get.snackbar('خطأ', 'فشل في رفع الصورة، يرجى المحاولة مرة أخرى',
            backgroundColor: KasbyColors.error.withOpacity(0.8), colorText: Colors.white);
        return;
      }
      // Cleanup old image if it was a Supabase one
      if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
        await controller.deleteAdImage(_currentImageUrl!);
      }
    }

    final newAd = Ad(
      id: widget.ad?.id ?? '',
      titleAr: titleArController.text,
      titleEn: titleEnController.text,
      descriptionAr: descArController.text,
      descriptionEn: descEnController.text,
      imageUrl: imageUrl!,
      isActive: isActive.value,
      createdAt: widget.ad?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (widget.ad == null) {
      success = await controller.addAd(newAd);
    } else {
      success = await controller.updateAd(newAd);
    }

    isUploading.value = false;

    if (success) {
      Get.back();
      Get.snackbar('نجاح', widget.ad == null ? 'تم إضافة الإعلان بنجاح' : 'تم تحديث الإعلان بنجاح');
    }
  }
}
