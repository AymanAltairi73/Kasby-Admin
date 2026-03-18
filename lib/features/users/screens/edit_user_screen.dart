import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../../../core/utils/validation_utils.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';

class EditUserScreen extends StatefulWidget {
  final User user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _telegramController;
  late final TextEditingController _emailController;

  final _isFormValid = true.obs;
  final _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _countryController = TextEditingController(text: widget.user.country);
    _cityController = TextEditingController(text: widget.user.city);
    _addressController = TextEditingController(text: widget.user.address);
    _phoneController = TextEditingController(text: widget.user.phone);
    _whatsappController = TextEditingController(text: widget.user.whatsapp);
    _telegramController = TextEditingController(text: widget.user.telegram);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _telegramController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _validate() {
    _isFormValid.value = _formKey.currentState?.validate() ?? false;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<UserController>();
    
    KasbyConfirmationDialog.show(
      title: 'تأكيد التعديل',
      message: 'هل أنت متأكد من حفظ التغييرات على بيانات المستخدم؟',
      confirmText: 'حفظ التغييرات',
      onConfirm: () async {
        _isLoading.value = true;
        try {
          final updatedUser = widget.user.copyWith(
            name: _nameController.text.trim(),
            country: _countryController.text.trim(),
            city: _cityController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
            whatsapp: _whatsappController.text.trim(),
            telegram: _telegramController.text.trim(),
            email: _emailController.text.trim(),
          );
          
          await controller.updateUser(updatedUser);
          Get.back(); // Return to details screen
          Get.snackbar(
            'تم التحديث',
            'تم تحديث بيانات المستخدم بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: KasbyColors.success.withOpacity(0.7),
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            'خطأ',
            'فشل تحديث البيانات: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: KasbyColors.error.withOpacity(0.7),
            colorText: Colors.white,
          );
        } finally {
          _isLoading.value = false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('تعديل بيانات المستخدم'),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  KasbyColors.background,
                  KasbyColors.surface,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                onChanged: _validate,
                child: Column(
                  children: [
                    KasbyGlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المعلومات الأساسية',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: KasbyColors.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 20),
                           KasbyTextField(
                            controller: _nameController,
                            hintText: 'الاسم الكامل',
                            prefixIcon: Icons.person_outline,
                            validator: (v) => ValidationUtils.validateRequired(v, 'الاسم'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: KasbyTextField(
                                  controller: _countryController,
                                  hintText: 'الدولة',
                                  prefixIcon: Icons.public_rounded,
                                  validator: (v) => ValidationUtils.validateRequired(v, 'الدولة'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: KasbyTextField(
                                  controller: _cityController,
                                  hintText: 'المدينة',
                                  prefixIcon: Icons.location_city_rounded,
                                  validator: (v) => ValidationUtils.validateRequired(v, 'المدينة'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: _addressController,
                            hintText: 'العنوان',
                            prefixIcon: Icons.home_work_outlined,
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: _emailController,
                            hintText: 'البريد الإلكتروني',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v != null && v.isNotEmpty ? ValidationUtils.validateEmail(v) : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    KasbyGlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'بيانات التواصل',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: KasbyColors.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          KasbyTextField(
                            controller: _phoneController,
                            hintText: 'رقم الهاتف',
                            prefixIcon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            validator: ValidationUtils.validatePhone,
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: _whatsappController,
                            hintText: 'رقم واتساب (اختياري)',
                            prefixIcon: FontAwesomeIcons.whatsapp,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: _telegramController,
                            hintText: 'معرف تيليجرام (اختياري)',
                            prefixIcon: FontAwesomeIcons.telegram,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Obx(() => SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isFormValid.value && !_isLoading.value ? _handleSave : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KasbyColors.primaryGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: KasbyColors.primaryGold.withOpacity(0.4),
                        ),
                        child: _isLoading.value
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                'حفظ التغييرات',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
