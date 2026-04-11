import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../notifications/controllers/notification_controller.dart';

class AgentApplicationModel {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String city;
  final String? experienceDesc;
  final String status;
  final DateTime createdAt;

  AgentApplicationModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.city,
    this.experienceDesc,
    required this.status,
    required this.createdAt,
  });

  factory AgentApplicationModel.fromJson(Map<String, dynamic> json) {
    return AgentApplicationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      city: json['city'] as String,
      experienceDesc: json['experience_desc'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AgentApplicationsController extends GetxController {
  final applications = <AgentApplicationModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadApplications();
  }

  Future<void> loadApplications() async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('agent_applications')
          .select()
          .order('created_at', ascending: false);

      applications.value = (response as List)
          .map((json) => AgentApplicationModel.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AgentApplicationsController',
        method: 'loadApplications',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل الطلبات',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveApplication(String applicationId) async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client.rpc(
        'admin_approve_agent_application',
        params: {'p_application_id': applicationId},
      );

      if (response['success'] == true) {
        // Send User Notification
        final app = applications.firstWhereOrNull((a) => a.id == applicationId);
        if (app != null) {
          Get.find<NotificationController>().sendNotification(
            '🌟 مبروك! انضممت للوكلاء',
            'تمت الموافقة على طلب انضمامك كوكيل رسمي. يمكنك الآن البدء في تقديم الخدمات.',
            'specific',
            specificUserId: app.userId,
          );
        }

        loadApplications();
      } else {
        Get.snackbar('خطأ', response['message'] ?? 'فشل في قبول الطلب');
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AgentApplicationsController',
        method: 'approveApplication',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء الموافقة على الطلب',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectApplication(String applicationId) async {
    isLoading.value = true;
    try {
      // Send User Notification
      final app = applications.firstWhereOrNull((a) => a.id == applicationId);
      if (app != null) {
        Get.find<NotificationController>().sendNotification(
          '⚠️ طلب الوكالة',
          'نعتذر، لم يتم قبول طلب انضمامك كوكيل في الوقت الحالي. يمكنك المحاولة مستقبلاً.',
          'specific',
          specificUserId: app.userId,
        );
      }

      loadApplications();
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AgentApplicationsController',
        method: 'rejectApplication',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء رفض الطلب',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
