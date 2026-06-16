import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../controllers/ad_controller.dart';
import '../models/ad_model.dart';
import 'ad_detail_screen.dart';
import 'add_edit_ad_screen.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  @override
  void initState() {
    super.initState();
    AppLoggerService.debugTrace(
      className: 'AdsScreen',
      method: 'initState',
      feature: 'Settings',
      status: 'INFO',
      message: 'Screen mounted',
    );
  }

  @override
  void dispose() {
    AppLoggerService.debugTrace(
      className: 'AdsScreen',
      method: 'dispose',
      feature: 'Settings',
      status: 'INFO',
      message: 'Screen unmounted',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'إدارة الإعلانات',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => safePop(null, context),
        ),
      ),
      body: Stack(
        children: [
          _buildBackground(),
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: KasbyColors.primaryGold),
              );
            }

            if (controller.ads.isEmpty) {
              return _buildEmptyState(context, controller);
            }

            return RefreshIndicator(
              onRefresh: () => controller.loadAds(),
              color: KasbyColors.primaryGold,
              backgroundColor: const Color(0xFF1E293B),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.ads.length,
                itemBuilder: (context, index) {
                  final ad = controller.ads[index];
                  return _buildAdCard(context, controller, ad);
                },
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KasbyColors.primaryGold,
        onPressed: () => Get.to(() => const AddEditAdScreen()),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AdController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.rectangleAd,
              size: 80,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد إعلانات نشطة حالياً',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ بإضافة أول إعلان لنظام كسببي',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 32),
          KasbyButton(
            text: 'إضافة إعلان جديد',
            width: 220,
            onPressed: () => Get.to(() => const AddEditAdScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, AdController controller, Ad ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: KasbyGlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.to(() => AdDetailScreen(ad: ad)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: ad.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.white.withOpacity(0.05),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: Colors.white.withOpacity(0.05),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            color: KasbyColors.error,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'خطأ في تحميل الصورة',
                            style: TextStyle(
                              color: KasbyColors.error.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: _buildStatusIndicator(ad.isActive),
                ),
              ],
            ),
            
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.titleAr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  if (ad.descriptionAr != null && ad.descriptionAr!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      ad.descriptionAr!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Get.to(() => AdDetailScreen(ad: ad)),
                          icon: const Icon(Icons.info_outline_rounded, size: 18),
                          label: const Text('التفاصيل'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded, color: KasbyColors.info, size: 20),
                          onPressed: () => Get.to(() => AddEditAdScreen(ad: ad)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: KasbyColors.error, size: 20),
                          onPressed: () => _showDeleteConfirmation(context, controller, ad),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? KasbyColors.success : KasbyColors.error).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isActive ? KasbyColors.success : KasbyColors.error).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? KasbyColors.success : KasbyColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'نشط' : 'معطل',
            style: TextStyle(
              color: isActive ? KasbyColors.success : KasbyColors.error,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AdController controller, Ad ad) {
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
        final success = await controller.deleteAd(ad.id, ad.titleAr, ad.imageUrl);
        safePop();
        if (success) {
          Get.snackbar('تم', 'تم حذف الإعلان بنجاح');
        } else {
          Get.snackbar('خطأ', 'حدث خطأ أثناء حذف الإعلان');
        }
      },
    );
  }
}
