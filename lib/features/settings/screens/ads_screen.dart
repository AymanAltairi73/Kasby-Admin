import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/ad_controller.dart';
import '../models/ad_model.dart';

class AdsScreen extends StatelessWidget {
  const AdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdController());

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الإعلانات')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: KasbyColors.primaryGold),
          );
        }

        if (controller.ads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.rectangleAd,
                  size: 64,
                  color: KasbyColors.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد إعلانات حالياً',
                  style: TextStyle(color: KasbyColors.textSecondary),
                ),
                const SizedBox(height: 24),
                KasbyButton(
                  text: 'إضافة إعلان جديد',
                  width: 200,
                  onPressed: () => _showAdForm(context, controller),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadAds(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.ads.length,
            itemBuilder: (context, index) {
              final ad = controller.ads[index];
              return _buildAdCard(context, controller, ad);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KasbyColors.primaryGold,
        onPressed: () => _showAdForm(context, controller),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, AdController controller, Ad ad) {
    return KasbyGlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ad.imageUrl,
                  width: 80,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 50,
                    color: Colors.white10,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 20,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.titleAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    if (ad.descriptionAr != null &&
                        ad.descriptionAr!.isNotEmpty)
                      Text(
                        ad.descriptionAr!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: KasbyColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: ad.isActive,
                activeColor: KasbyColors.primaryGold,
                onChanged: (val) => controller.toggleAdStatus(ad),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'الأولوية: ${ad.priority}',
                style: const TextStyle(
                  color: KasbyColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: KasbyColors.info, size: 20),
                onPressed: () => _showAdForm(context, controller, ad: ad),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: KasbyColors.error,
                  size: 20,
                ),
                onPressed: () =>
                    _showDeleteConfirmation(context, controller, ad),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdForm(BuildContext context, AdController controller, {Ad? ad}) {
    final titleArController = TextEditingController(text: ad?.titleAr);
    final titleEnController = TextEditingController(text: ad?.titleEn);
    final descArController = TextEditingController(text: ad?.descriptionAr);
    final descEnController = TextEditingController(text: ad?.descriptionEn);
    final imageUrlController = TextEditingController(text: ad?.imageUrl);
    final actionUrlController = TextEditingController(text: ad?.actionUrl);
    final priorityController = TextEditingController(
      text: ad?.priority.toString() ?? '0',
    );
    final isActive = (ad?.isActive ?? true).obs;

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: Get.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ad == null ? 'إضافة إعلان جديد' : 'تعديل الإعلان',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: descArController,
                  labelText: 'الوصف (بالعربية)',
                  hintText: 'وصف قصير للإعلان',
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: descEnController,
                  labelText: 'الوصف (بالإنجليزي) - اختياري',
                  hintText: 'Short description',
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: imageUrlController,
                  labelText: 'رابط الصورة',
                  hintText: 'https://example.com/image.jpg',
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: actionUrlController,
                  labelText: 'رابط التوجيه (اختياري)',
                  hintText: 'https://kasby.com/details',
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: priorityController,
                  labelText: 'الأولوية',
                  hintText: 'رقم يعبر عن ترتيب الظهور (الأعلى أولاً)',
                ),
                const SizedBox(height: 16),
                Obx(
                  () => CheckboxListTile(
                    title: const Text(
                      'نشط',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: isActive.value,
                    onChanged: (val) => isActive.value = val ?? true,
                    activeColor: KasbyColors.primaryGold,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 32),
                KasbyButton(
                  text: ad == null ? 'إضافة' : 'حفظ التغييرات',
                  onPressed: () async {
                    if (titleArController.text.isEmpty ||
                        imageUrlController.text.isEmpty) {
                      Get.snackbar(
                        'خطأ',
                        'يرجى ملء الحقول الأساسية (العنوان بالعربية ورابط الصورة)',
                      );
                      return;
                    }

                    final newAd = Ad(
                      id: ad?.id ?? '',
                      titleAr: titleArController.text,
                      titleEn: titleEnController.text,
                      descriptionAr: descArController.text,
                      descriptionEn: descEnController.text,
                      imageUrl: imageUrlController.text,
                      actionUrl: actionUrlController.text,
                      priority: int.tryParse(priorityController.text) ?? 0,
                      isActive: isActive.value,
                      createdAt: ad?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    bool success;
                    if (ad == null) {
                      success = await controller.addAd(newAd);
                    } else {
                      success = await controller.updateAd(newAd);
                    }

                    if (success) {
                      Get.back();
                      Get.snackbar(
                        'تم',
                        ad == null
                            ? 'تم إضافة الإعلان بنجاح'
                            : 'تم تحديث الإعلان بنجاح',
                      );
                    } else {
                      Get.snackbar('خطأ', 'حدث خطأ أثناء حفظ البيانات');
                    }
                  },
                ),
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
    AdController controller,
    Ad ad,
  ) {
    Get.defaultDialog(
      title: 'حذف الإعلان',
      middleText: 'هل أنت متأكد من حذف الإعلان "${ad.titleAr}"؟',
      backgroundColor: const Color(0xFF1E293B),
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: KasbyColors.textSecondary),
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.black,
      cancelTextColor: KasbyColors.primaryGold,
      buttonColor: KasbyColors.error,
      onConfirm: () async {
        final success = await controller.deleteAd(ad.id, ad.titleAr);
        Get.back();
        if (success) {
          Get.snackbar('تم', 'تم حذف الإعلان بنجاح');
        } else {
          Get.snackbar('خطأ', 'حدث خطأ أثناء حذف الإعلان');
        }
      },
    );
  }
}
