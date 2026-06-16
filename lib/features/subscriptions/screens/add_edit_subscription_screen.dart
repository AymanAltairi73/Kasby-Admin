import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../models/subscription_model.dart';
import '../controllers/subscription_controller.dart';

class AddEditSubscriptionScreen extends StatefulWidget {
  final SubscriptionPlan? plan;

  const AddEditSubscriptionScreen({super.key, this.plan});

  @override
  State<AddEditSubscriptionScreen> createState() => _AddEditSubscriptionScreenState();
}

class _AddEditSubscriptionScreenState extends State<AddEditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool isEdit;

  late TextEditingController nameArController;
  late TextEditingController nameEnController;
  late TextEditingController priceController;
  late TextEditingController durationController;
  late TextEditingController maxInvestmentsController;
  late TextEditingController withdrawalTimeController;
  late TextEditingController featureController;

  final RxString tier = 'premium'.obs;
  final RxString status = 'Active'.obs;
  final RxList<String> features = <String>[].obs;

  @override
  void initState() {
    super.initState();
    isEdit = widget.plan != null;
    AppLoggerService.debugTrace(
      className: 'AddEditSubscriptionScreen',
      method: 'initState',
      feature: 'Subscriptions',
      status: 'INFO',
      message: 'Screen mounted',
      params: {'mode': isEdit ? 'edit' : 'create'},
    );

    nameArController = TextEditingController(text: widget.plan?.displayNameAr ?? '');
    nameEnController = TextEditingController(text: widget.plan?.displayNameEn ?? '');
    priceController = TextEditingController(text: widget.plan?.price.toString() ?? '');
    durationController = TextEditingController(text: widget.plan?.duration ?? '1 Month');
    maxInvestmentsController = TextEditingController(text: widget.plan?.maxActiveInvestments.toString() ?? '999');
    withdrawalTimeController = TextEditingController(text: widget.plan?.withdrawalProcessTime.toString() ?? '2');
    featureController = TextEditingController();

    if (isEdit) {
      tier.value = widget.plan!.tier;
      status.value = widget.plan!.status;
      features.assignAll(widget.plan!.features);
    }
  }

  @override
  void dispose() {
    AppLoggerService.debugTrace(
      className: 'AddEditSubscriptionScreen',
      method: 'dispose',
      feature: 'Subscriptions',
      status: 'INFO',
      message: 'Screen unmounted',
    );
    nameArController.dispose();
    nameEnController.dispose();
    priceController.dispose();
    durationController.dispose();
    maxInvestmentsController.dispose();
    withdrawalTimeController.dispose();
    featureController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<SubscriptionController>();
    final newPlan = SubscriptionPlan(
      id: isEdit ? widget.plan!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      tier: tier.value,
      technicalName: nameEnController.text.toLowerCase().replaceAll(' ', '_'),
      displayNameAr: nameArController.text,
      displayNameEn: nameEnController.text,
      price: double.tryParse(priceController.text) ?? 0.0,
      duration: durationController.text,
      maxActiveInvestments: int.tryParse(maxInvestmentsController.text) ?? 0,
      withdrawalProcessTime: int.tryParse(withdrawalTimeController.text) ?? 0,
      status: status.value,
      icon: 'stars_rounded',
      features: features.toList(),
      keywords: [],
    );

    final ok = isEdit
        ? await controller.updatePlan(widget.plan!.id, newPlan.toJson())
        : await controller.createPlan(newPlan);

    if (ok && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isEdit ? 'تعديل خطة' : 'إضافة خطة جديدة'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('حفظ', style: TextStyle(color: KasbyColors.primaryGold, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tier Selection
              const Text('فئة الخطة', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              Obx(() => SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: KasbyColors.primaryGold,
                  selectedForegroundColor: Colors.black,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  side: const BorderSide(color: Colors.white10),
                ),
                segments: const [
                  // ButtonSegment(value: 'free', label: Text('مجانية')),
                  ButtonSegment(value: 'premium', label: Text('مميزة')),
                ],
                selected: {tier.value},
                onSelectionChanged: (set) => tier.value = set.first,
              )),
              
              const SizedBox(height: 32),

              KasbyTextField(
                controller: nameArController,
                labelText: 'الاسم (بالعربي)',
                prefixIcon: Icons.title_rounded,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              KasbyTextField(
                controller: nameEnController,
                labelText: 'Display Name (English)',
                prefixIcon: Icons.translate_rounded,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: KasbyTextField(
                      controller: priceController,
                      labelText: 'السعر (\$)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KasbyTextField(
                      controller: durationController,
                      labelText: 'المدة (مثلاً: 1 Month)',
                      prefixIcon: Icons.timer_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: KasbyTextField(
                      controller: maxInvestmentsController,
                      labelText: 'الاستثمارات القصوى',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.account_balance_wallet_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KasbyTextField(
                      controller: withdrawalTimeController,
                      labelText: 'ساعات السحب',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.history_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              
              const Text('المميزات الحصرية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              KasbyGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: KasbyTextField(
                            controller: featureController,
                            labelText: 'أضف ميزة جديدة',
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: () {
                            if (featureController.text.isNotEmpty) {
                              features.add(featureController.text);
                              featureController.clear();
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                          style: IconButton.styleFrom(backgroundColor: KasbyColors.primaryGold, foregroundColor: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() => Column(
                      children: features.map((f) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline_rounded, color: KasbyColors.success, size: 20),
                        title: Text(f, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        trailing: IconButton(
                          onPressed: () => features.remove(f),
                          icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                        ),
                      )).toList(),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              const Text('إعدادات إضافية', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              Obx(() => SwitchListTile(
                title: const Text('تفعيل الخطة', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: status.value == 'Active',
                activeColor: KasbyColors.primaryGold,
                onChanged: (v) => status.value = v ? 'Active' : 'Inactive',
              )),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
