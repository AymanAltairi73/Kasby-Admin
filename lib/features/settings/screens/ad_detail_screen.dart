import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../models/ad_model.dart';
import '../controllers/ad_controller.dart';
import 'add_edit_ad_screen.dart';

class AdDetailScreen extends StatefulWidget {
  final Ad ad;

  const AdDetailScreen({super.key, required this.ad});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  Ad get ad => widget.ad;

  @override
  void initState() {
    super.initState();
    AppLoggerService.debugTrace(
      className: 'AdDetailScreen',
      method: 'initState',
      feature: 'Settings',
      status: 'INFO',
      message: 'Screen mounted',
      params: {'adId': widget.ad.id},
    );
  }

  @override
  void dispose() {
    AppLoggerService.debugTrace(
      className: 'AdDetailScreen',
      method: 'dispose',
      feature: 'Settings',
      status: 'INFO',
      message: 'Screen unmounted',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: KasbyColors.primaryGold),
            onPressed: () => Get.to(() => AddEditAdScreen(ad: ad)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: KasbyColors.error),
            onPressed: () => _showDeleteConfirmation(context, controller),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildImageHeader(), // Replaced by direct CachedNetworkImage
                CachedNetworkImage(
                  imageUrl: ad.imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.05),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 300,
                    color: Colors.white.withOpacity(0.05),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: KasbyColors.error,
                          size: 50,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'فشل في تحميل صورة الإعلان',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusChip(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('العنوان (عربي)'),
                      _buildContentText(ad.titleAr, isMain: true),
                      const SizedBox(height: 12),
                      if (ad.titleEn != null && ad.titleEn!.isNotEmpty) ...[
                        _buildSectionTitle('Title (English)'),
                        _buildContentText(ad.titleEn!),
                        const SizedBox(height: 12),
                      ],
                      const Divider(color: Colors.white10, height: 32),
                      _buildSectionTitle('الوصف (عربي)'),
                      _buildContentText(ad.descriptionAr ?? 'لا يوجد وصف'),
                      const SizedBox(height: 12),
                      if (ad.descriptionEn != null &&
                          ad.descriptionEn!.isNotEmpty) ...[
                        _buildSectionTitle('Description (English)'),
                        _buildContentText(ad.descriptionEn!),
                        const SizedBox(height: 12),
                      ],
                      const Divider(color: Colors.white10, height: 32),
                      _buildInfoRow(Icons.calendar_today_rounded, 'تاريخ الإنشاء', DateFormat('yyyy/MM/dd').format(ad.createdAt)),
                      if (ad.expiresAt != null)
                        _buildInfoRow(Icons.timer_off_rounded, 'تاريخ الانتهاء', DateFormat('yyyy/MM/dd').format(ad.expiresAt!)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ad.isActive ? KasbyColors.success.withValues(alpha: 0.1) : KasbyColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ad.isActive ? KasbyColors.success : KasbyColors.error,
          width: 0.5,
        ),
      ),
      child: Text(
        ad.isActive ? 'نشط' : 'معطل',
        style: TextStyle(
          color: ad.isActive ? KasbyColors.success : KasbyColors.error,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: KasbyColors.primaryGold,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildContentText(String text, {bool isMain = false}) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: isMain ? 22 : 15,
        fontWeight: isMain ? FontWeight.w900 : FontWeight.w500,
        height: 1.5,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: KasbyColors.primaryGold),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AdController controller) {
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
        if (success) {
          Get.back(); // Close dialog
          Get.back(); // Go back to ads list
          Get.snackbar('تم الحذف', 'تم حذف الإعلان بنجاح');
        } else {
          Get.snackbar('خطأ', 'حدث خطأ أثناء حذف الإعلان');
        }
      },
    );
  }
}
