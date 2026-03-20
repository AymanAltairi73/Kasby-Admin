import 'package:get/get.dart';
import '../models/kyc_document_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

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
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('kyc_documents')
          .select('*, profiles!kyc_documents_user_id_fkey(full_name)')
          .eq('status', 'pending')
          .order('uploaded_at', ascending: false);

      pendingDocuments.assignAll(
        (response as List).map((e) => KycDocument.fromJson(e)).toList(),
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'KycController',
        method: 'loadPendingDocuments',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update KYC document status
  Future<bool> updateStatus({
    required String id,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      final adminId = SupabaseService.auth.currentUser?.id;
      
      await SupabaseService.client.from('kyc_documents').update({
        'status': status,
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': rejectionReason,
      }).eq('id', id);

      // Refresh list
      await loadPendingDocuments();
      return true;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'KycController',
        method: 'updateStatus',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
