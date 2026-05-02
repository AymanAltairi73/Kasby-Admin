import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/kyc_document_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../notifications/controllers/notification_controller.dart';

/// KYC Controller — manages user identity verification
class KycController extends GetxController {
  final pendingDocuments = <KycDocument>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPendingDocuments();
  }

  /// Load all pending KYC documents
  Future<void> loadPendingDocuments() async {
    debugPrint('[KycController][loadPendingDocuments] Fetching data from /kyc_documents');
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('kyc_documents')
          .select('*, profiles!kyc_documents_user_id_fkey(full_name, phone, email)')
          .eq('status', 'pending')
          .order('uploaded_at', ascending: false);

      debugPrint('[KycController][loadPendingDocuments] Response: ${response.length} pending documents');
      pendingDocuments.assignAll(
        (response as List).map((e) => KycDocument.fromJson(e)).toList(),
      );
      debugPrint('[KycController][loadPendingDocuments] Successfully loaded ${pendingDocuments.length} pending KYC documents');
    } catch (e, stackTrace) {
      debugPrint('[KycController][loadPendingDocuments] Error: $e');
      debugPrint('[KycController][loadPendingDocuments] Stack trace: $stackTrace');
      debugPrint('[KycController][loadPendingDocuments] Endpoint: /kyc_documents');
      // Handle silently
    } finally {
      isLoading.value = false;
    }
  }

  /// Update KYC document status + profile status + notification
  Future<bool> updateStatus({
    required String id,
    required String status,
    required String userId,
    String? rejectionReason,
  }) async {
    try {
      final adminId = SupabaseService.auth.currentUser?.id;
      
      // 1. Update the document status
      await SupabaseService.client.from('kyc_documents').update({
        'status': status,
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': rejectionReason,
      }).eq('id', id);

      // 2. Update profile status (Verified/Rejected)
      // Note: In a real system, you might wait until ALL docs are verified
      // but for this implementation we update when any doc is reviewed.
      final profileKycStatus = status == 'verified' ? 'verified' : 'rejected';
      await SupabaseService.client.from('profiles').update({
        'kyc_status': profileKycStatus,
      }).eq('id', userId);

      // 3. Send Notification to user (Genius Unified Text)
      final notifController = Get.find<NotificationController>();
      final title = status == 'verified' ? '✅ توثيق الحساب' : '❌ تنبيه التوثيق';
      final message = status == 'verified'
          ? 'تم توثيق حسابك بنجاح! يمكنك الآن الاستمتاع بكافة مميزات التطبيق.'
          : 'نعتذر، تم رفض طلب التوثيق الخاص بك. السبب: ${rejectionReason ?? "غير محدد"}. يرجى المحاولة مرة أخرى.';

      await notifController.sendNotification(title, message, 'specific', specificUserId: userId);

      // Refresh list
      await loadPendingDocuments();
      return true;
    } catch (e) {
      return false;
    }
  }
}
