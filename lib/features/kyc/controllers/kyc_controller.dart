import 'package:get/get.dart';
import '../models/kyc_document_model.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/permission_service.dart';
import '../../notifications/controllers/notification_controller.dart';

class KycController extends GetxController {
  final pendingDocuments = <KycDocument>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'KycController',
      method: 'onInit',
      feature: 'Kyc',
      status: 'INFO',
    );
    super.onInit();
    loadPendingDocuments();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'KycController',
      method: 'onClose',
      feature: 'Kyc',
      status: 'INFO',
    );
    super.onClose();
  }

  Future<void> loadPendingDocuments() async {
    AppLoggerService.debugTrace(
      className: 'KycController',
      method: 'loadPendingDocuments',
      feature: 'Kyc',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('kyc_documents')
          .select('*, profiles!kyc_documents_user_id_fkey(full_name, phone, email)')
          .eq('status', 'pending')
          .order('uploaded_at', ascending: false);

      pendingDocuments.assignAll(
        (response as List).map((e) => KycDocument.fromJson(e)).toList(),
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل طلبات التوثيق');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _syncProfileKycStatus(String userId) async {
    final docs = await SupabaseService.client
        .from('kyc_documents')
        .select('status')
        .eq('user_id', userId);

    final statuses = (docs as List).map((d) => d['status'] as String).toList();
    String profileStatus = 'pending';
    if (statuses.any((s) => s == 'rejected')) {
      profileStatus = 'rejected';
    } else if (statuses.isNotEmpty && statuses.every((s) => s == 'verified')) {
      profileStatus = 'verified';
    } else if (statuses.any((s) => s == 'pending')) {
      profileStatus = 'pending';
    }

    await SupabaseService.client
        .from('profiles')
        .update({'kyc_status': profileStatus})
        .eq('id', userId);
  }

  Future<bool> updateStatus({
    required String id,
    required String status,
    required String userId,
    String? rejectionReason,
  }) async {
    final permService = Get.find<PermissionService>();
    if (!permService.canManageUsers) {
      Get.snackbar('صلاحيات غير كافية', 'لا تملك صلاحية مراجعة KYC',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    try {
      final adminId = SupabaseService.auth.currentUser?.id;

      await SupabaseService.client.from('kyc_documents').update({
        'status': status,
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': rejectionReason,
      }).eq('id', id);

      await _syncProfileKycStatus(userId);

      await AppLoggerService.logActivity(
        action: status == 'verified' ? 'admin_verify_kyc' : 'admin_reject_kyc',
        entityType: 'kyc_document',
        entityId: id,
        details: {
          'user_id': userId,
          if (rejectionReason != null && rejectionReason.isNotEmpty)
            'reason': rejectionReason,
        },
      );

      final notifController = Get.find<NotificationController>();
      final title = status == 'verified' ? '✅ توثيق الحساب' : '❌ تنبيه التوثيق';
      final message = status == 'verified'
          ? 'تم توثيق حسابك بنجاح! يمكنك الآن الاستمتاع بكافة مميزات التطبيق.'
          : 'نعتذر، تم رفض طلب التوثيق الخاص بك. السبب: ${rejectionReason ?? "غير محدد"}. يرجى المحاولة مرة أخرى.';

      await notifController.sendNotification(
        title,
        message,
        'specific',
        specificUserId: userId,
      );

      await loadPendingDocuments();
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث حالة التوثيق');
      return false;
    }
  }
}
