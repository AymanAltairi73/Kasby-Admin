import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../../../core/utils/validation_utils.dart';
import '../controllers/agent_controller.dart';
import '../models/agent_model.dart';

class EditAgentScreen extends StatefulWidget {
  const EditAgentScreen({super.key});

  @override
  State<EditAgentScreen> createState() => _EditAgentScreenState();
}

class _EditAgentScreenState extends State<EditAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final Agent? agent = Get.arguments;
  late final AgentController controller;

  late final TextEditingController nameController;
  late final TextEditingController countryController;
  late final TextEditingController provinceController;
  late final TextEditingController cityController;
  late final TextEditingController addressController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController telegramController;
  late final TextEditingController whatsappController;

  final isFormValid = false.obs;
  final isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AgentController>();

    nameController = TextEditingController(text: agent?.name ?? '');
    countryController = TextEditingController(text: agent?.country ?? 'العراق');
    provinceController = TextEditingController(text: agent?.province ?? '');
    cityController = TextEditingController(text: agent?.city ?? '');
    addressController = TextEditingController(text: agent?.address ?? '');
    phoneController = TextEditingController(text: agent?.phone ?? '+964');
    emailController = TextEditingController(text: agent?.email ?? '');
    telegramController = TextEditingController(text: agent?.telegram ?? '');
    whatsappController = TextEditingController(text: agent?.whatsapp ?? '');

    // Initial validation check
    WidgetsBinding.instance.addPostFrameCallback((_) => _validate());
  }

  void _validate() {
    isFormValid.value = _formKey.currentState?.validate() ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    countryController.dispose();
    provinceController.dispose();
    cityController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    telegramController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) return;

    final isEdit = agent != null;
    final message = isEdit
        ? 'هل أنت متأكد من تعديل بيانات الوكيل؟'
        : 'هل أنت متأكد من إضافة هذا الوكيل؟';

    KasbyConfirmationDialog.show(
      message: message,
      onConfirm: () async {
        isLoading.value = true;
        try {
          if (isEdit) {
            await controller.updateAgent(agent!.id, {
              'name': nameController.text,
              'phone': phoneController.text,
              'country': countryController.text,
              'city': cityController.text,
              'province': provinceController.text,
              'address': addressController.text,
              'whatsapp': whatsappController.text,
              'telegram': telegramController.text,
              'email': emailController.text,
            });
          } else {
            await controller.createAgent(
              name: nameController.text,
              country: countryController.text,
              province: provinceController.text,
              city: cityController.text,
              address: addressController.text,
              phone: phoneController.text,
              whatsapp: whatsappController.text,
              telegram: telegramController.text,
              email: emailController.text,
            );
          }
          
          Get.snackbar(
            'نجاح',
            isEdit ? 'تم تحديث بيانات الوكيل بنجاح' : 'تم إضافة الوكيل بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: KasbyColors.success.withValues(alpha: 0.8),
            colorText: Colors.white,
          );

          // Return specifically to the agents list screen
          Get.until((route) => Get.currentRoute == '/agents');
        } finally {
          isLoading.value = false;
        }
      },
    );
  }

  bool _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = agent != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEdit ? 'تعديل بيانات الوكيل' : 'إضافة وكيل جديد',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          _buildCelestialBackground(),
          SafeArea(
            child: Form(
              key: _formKey,
              onChanged: _validate,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    KasbyGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المعلومات الأساسية',
                            style: TextStyle(
                              color: KasbyColors.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          KasbyTextField(
                            controller: nameController,
                            labelText: 'الاسم الكامل للوكيل',
                            prefixIcon: Icons.person_rounded,
                            validator: (v) => ValidationUtils.validateRequired(v, 'الاسم'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: KasbyTextField(
                                  controller: countryController,
                                  labelText: 'الدولة',
                                  prefixIcon: Icons.public_rounded,
                                  validator: (v) => ValidationUtils.validateRequired(v, 'الدولة'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: KasbyTextField(
                                  controller: cityController,
                                  labelText: 'المدينة',
                                  prefixIcon: Icons.location_city_rounded,
                                  validator: (v) => ValidationUtils.validateRequired(v, 'المدينة'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: provinceController,
                            labelText: 'المحافظة',
                            prefixIcon: Icons.map_rounded,
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: addressController,
                            labelText: 'العنوان بالتفصيل',
                            prefixIcon: Icons.location_on_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    KasbyGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'معلومات التواصل',
                            style: TextStyle(
                              color: KasbyColors.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          KasbyTextField(
                            controller: phoneController,
                            labelText: 'رقم الهاتف (مع كود الدولة)',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_android_rounded,
                            validator: ValidationUtils.validatePhone,
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: whatsappController,
                            labelText: 'رقم واتساب (اختياري)',
                            keyboardType: TextInputType.phone,
                            prefixIcon: FontAwesomeIcons.whatsapp,
                            validator: ValidationUtils.validateWhatsApp,
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: telegramController,
                            labelText: 'معرف تيليجرام (اختياري)',
                            prefixIcon: FontAwesomeIcons.telegram,
                            validator: ValidationUtils.validateTelegram,
                          ),
                          const SizedBox(height: 16),
                          KasbyTextField(
                            controller: emailController,
                            labelText: 'البريد الإلكتروني (اختياري)',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.alternate_email_rounded,
                            validator: ValidationUtils.validateEmail,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Obx(() => SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: (isFormValid.value && !isLoading.value) ? _handleSave : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KasbyColors.primaryGold,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.white12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading.value
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'تحديث البيانات' : 'إضافة الوكيل',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelestialBackground() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: _buildOrb(400, KasbyColors.primaryGold.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: _buildOrb(500, KasbyColors.info.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
        ],
      ),
    );
  }
}
