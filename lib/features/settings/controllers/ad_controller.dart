import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';
import '../models/ad_model.dart';
import '../../../core/services/audit_logger.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

class AdController extends GetxController {
  final ads = <Ad>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAds();
  }

  Future<void> loadAds() async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('ads')
          .select()
          .order('created_at', ascending: false);

      ads.assignAll((response as List).map((e) => Ad.fromSupabase(e)).toList());
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AdController',
        method: 'loadAds',
        error: e,
        stackTrace: stackTrace,
      );
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

      final imageUrl = SupabaseService.client.storage
          .from('advertisements')
          .getPublicUrl(storagePath);

      return imageUrl;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AdController',
        method: 'uploadAdImage',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> deleteAdImage(String imageUrl) async {
    try {
      // Extract path from public URL
      // Example: https://.../storage/v1/object/public/advertisements/ad_images/123.jpg
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final adsIndex = pathSegments.indexOf('advertisements');
      
      if (adsIndex != -1 && adsIndex + 1 < pathSegments.length) {
        final storagePath = pathSegments.sublist(adsIndex + 1).join('/');
        await SupabaseService.client.storage
            .from('advertisements')
            .remove([storagePath]);
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AdController',
        method: 'deleteAdImage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> addAd(Ad ad) async {
    try {
      final data = ad.toSupabase();
      data['created_by'] = SupabaseService.client.auth.currentUser?.id;

      await SupabaseService.client.from('ads').insert(data);
      await loadAds();
      _logAction('إضافة إعلان جديد: ${ad.titleAr}');
      return true;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AdController',
        method: 'addAd',
        error: e,
        stackTrace: stackTrace,
      );
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
      _logAction('تحديث الإعلان: ${ad.titleAr}');
      return true;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AdController',
        method: 'updateAd',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> deleteAd(String id, String title, String? imageUrl) async {
    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await deleteAdImage(imageUrl);
      }
      await SupabaseService.client.from('ads').delete().eq('id', id);
      await loadAds();
      _logAction('حذف الإعلان: $title');
      return true;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AdController',
        method: 'deleteAd',
        error: e,
        stackTrace: stackTrace,
      );
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
      _logAction(
        'تغيير حالة الإعلان ${ad.titleAr} إلى: ${newStatus ? 'مفعل' : 'معطل'}',
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AdController',
        method: 'toggleAdStatus',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _logAction(String details) {
    AuditLogger.log(
      adminName: 'SuperAdmin',
      action: 'إدارة الإعلانات',
      details: details,
    );
  }
}
