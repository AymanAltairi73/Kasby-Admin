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
          .order('priority', ascending: false);

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

  Future<bool> deleteAd(String id, String title) async {
    try {
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
