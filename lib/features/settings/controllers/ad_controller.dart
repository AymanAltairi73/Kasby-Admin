import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';
import '../models/ad_model.dart';
import '../../../core/services/supabase_service.dart';

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
    } catch (e) {
      // Handle silently
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
    } catch (e) {
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
    } catch (e) {
      // Continue
    }
  }

  Future<bool> addAd(Ad ad) async {
    try {
      final data = ad.toSupabase();
      data['created_by'] = SupabaseService.client.auth.currentUser?.id;

      await SupabaseService.client.from('ads').insert(data);
      await loadAds();
      return true;
    } catch (e) {
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
      return true;
    } catch (e) {
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
      // Continue
    }
  }

}
