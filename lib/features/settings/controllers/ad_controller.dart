import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';
import '../models/ad_model.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/supabase_service.dart';

class AdController extends GetxController {
  final ads = <Ad>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'AdController',
      method: 'onInit',
      feature: 'Settings',
      status: 'INFO',
    );
    super.onInit();
    loadAds();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'AdController',
      method: 'onClose',
      feature: 'Settings',
      status: 'INFO',
    );
    super.onClose();
  }

  Future<void> loadAds() async {
    AppLoggerService.debugTrace(
      className: 'AdController',
      method: 'loadAds',
      feature: 'Settings',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('ads')
          .select()
          .order('created_at', ascending: false);

      ads.assignAll((response as List).map((e) => Ad.fromSupabase(e)).toList());
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل الإعلانات');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadAdImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final storagePath = 'ad_images/$fileName';

      await SupabaseService.client.storage
          .from('advertisements')
          .upload(storagePath, file);

      return SupabaseService.client.storage
          .from('advertisements')
          .getPublicUrl(storagePath);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل رفع الصورة');
      return null;
    }
  }

  Future<void> deleteAdImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final adsIndex = pathSegments.indexOf('advertisements');

      if (adsIndex != -1 && adsIndex + 1 < pathSegments.length) {
        final storagePath = pathSegments.sublist(adsIndex + 1).join('/');
        await SupabaseService.client.storage
            .from('advertisements')
            .remove([storagePath]);
      }
    } catch (_) {}
  }

  Future<bool> addAd(Ad ad) async {
    try {
      final data = ad.toSupabase();
      data['created_by'] = SupabaseService.client.auth.currentUser?.id;

      await SupabaseService.client.from('ads').insert(data);
      await loadAds();
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إضافة الإعلان');
      return false;
    }
  }

  Future<bool> updateAd(Ad ad) async {
    try {
      await SupabaseService.client
          .from('ads')
          .update(ad.toSupabase())
          .eq('id', ad.id);
      await loadAds();
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث الإعلان');
      return false;
    }
  }

  Future<bool> deleteAd(String id, String title, String? imageUrl) async {
    try {
      final deleted = await SupabaseService.client
          .from('ads')
          .delete()
          .eq('id', id)
          .select('id');

      if (deleted.isEmpty) {
        AppLoggerService.debugTrace(
          className: 'AdController',
          method: 'deleteAd',
          feature: 'Settings',
          status: 'FAILED',
          message: 'No rows deleted — RLS or missing ad',
          params: {'adId': id},
        );
        Get.snackbar('خطأ', 'لم يتم حذف الإعلان — تحقق من الصلاحيات');
        return false;
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        await deleteAdImage(imageUrl);
      }

      await loadAds();
      return true;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AdController',
        method: 'deleteAd',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل حذف الإعلان');
      return false;
    }
  }

  Future<void> toggleAdStatus(Ad ad) async {
    final newStatus = !ad.isActive;
    try {
      await SupabaseService.client
          .from('ads')
          .update({'is_active': newStatus})
          .eq('id', ad.id);
      await loadAds();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تغيير حالة الإعلان');
    }
  }
}
