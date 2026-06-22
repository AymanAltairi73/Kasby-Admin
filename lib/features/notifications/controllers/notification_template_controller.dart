import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';

class NotificationTemplate {
  final String id;
  final String name;
  final String titleTemplate;
  final String messageTemplate;
  final String category;
  final List<String> variables;
  final DateTime? createdAt;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.titleTemplate,
    required this.messageTemplate,
    this.category = 'general',
    this.variables = const [],
    this.createdAt,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      titleTemplate: json['title_template'] ?? '',
      messageTemplate: json['message_template'] ?? '',
      category: json['category'] ?? 'general',
      variables: (json['variables'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'title_template': titleTemplate,
        'message_template': messageTemplate,
        'category': category,
        'variables': variables,
      };
}

class NotificationTemplateController extends GetxController {
  final templates = <NotificationTemplate>[].obs;
  final isLoading = false.obs;
  final _useLocal = false.obs;

  static const List<String> categories = [
    'general',
    'financial',
    'investment',
    'promotion',
    'system',
  ];

  static const Map<String, String> categoryLabels = {
    'general': 'عام',
    'financial': 'مالي',
    'investment': 'استثمار',
    'promotion': 'ترويجي',
    'system': 'نظام',
  };

  static final List<NotificationTemplate> _builtInTemplates = [
    NotificationTemplate(
      id: 'builtin-1',
      name: 'ترحيب مستخدم جديد',
      titleTemplate: 'مرحباً {{user_name}}!',
      messageTemplate:
          'أهلاً بك في كاسبي! بدأت رحلتك الاستثمارية الآن.',
      category: 'general',
      variables: ['user_name'],
    ),
    NotificationTemplate(
      id: 'builtin-2',
      name: 'تأكيد الإيداع',
      titleTemplate: 'تم الإيداع بنجاح',
      messageTemplate:
          'تم إيداع {{amount}} {{currency}} في حسابك بنجاح.',
      category: 'financial',
      variables: ['amount', 'currency'],
    ),
    NotificationTemplate(
      id: 'builtin-3',
      name: 'أرباح استثمارية',
      titleTemplate: 'أرباحك جاهزة!',
      messageTemplate:
          'تم إضافة أرباح بقيمة {{amount}} من خطة {{plan_name}}.',
      category: 'investment',
      variables: ['amount', 'plan_name'],
    ),
    NotificationTemplate(
      id: 'builtin-4',
      name: 'عرض ترويجي',
      titleTemplate: '{{offer_title}}',
      messageTemplate:
          'لفترة محدودة: {{offer_description}}. لا تفوّت الفرصة!',
      category: 'promotion',
      variables: ['offer_title', 'offer_description'],
    ),
    NotificationTemplate(
      id: 'builtin-5',
      name: 'صيانة مجدولة',
      titleTemplate: 'صيانة مجدولة',
      messageTemplate:
          'سيتم إجراء صيانة على النظام يوم {{date}} من {{start_time}} إلى {{end_time}}.',
      category: 'system',
      variables: ['date', 'start_time', 'end_time'],
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    AppLoggerService.debugTrace(
      className: 'NotificationTemplateController',
      method: 'loadTemplates',
      feature: 'Notifications',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final data = await SupabaseService.client
          .from('notification_templates')
          .select()
          .order('created_at', ascending: false);

      templates.assignAll(
        (data as List).map((e) => NotificationTemplate.fromJson(e)).toList(),
      );
      _useLocal.value = false;

      AppLoggerService.debugTrace(
        className: 'NotificationTemplateController',
        method: 'loadTemplates',
        feature: 'Notifications',
        status: 'SUCCESS',
        params: {'count': templates.length},
      );
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'NotificationTemplateController',
        method: 'loadTemplates',
        feature: 'Notifications',
        status: 'FAILED',
        error: e,
        message: 'Falling back to built-in templates',
      );
      _useLocal.value = true;
      templates.assignAll(_builtInTemplates);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTemplate(NotificationTemplate template) async {
    try {
      if (_useLocal.value) {
        final localTemplate = NotificationTemplate(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          name: template.name,
          titleTemplate: template.titleTemplate,
          messageTemplate: template.messageTemplate,
          category: template.category,
          variables: template.variables,
          createdAt: DateTime.now(),
        );
        templates.insert(0, localTemplate);
        templates.refresh();
        Get.snackbar(
          'تمت الإضافة',
          'تم إضافة القالب محلياً',
          backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
          colorText: KasbyColors.textPrimary,
        );
        return;
      }

      await SupabaseService.client
          .from('notification_templates')
          .insert(template.toJson());
      await loadTemplates();

      Get.snackbar(
        'تمت الإضافة',
        'تم إضافة القالب بنجاح',
        backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'NotificationTemplateController',
        method: 'addTemplate',
        feature: 'Notifications',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل إضافة القالب');
    }
  }

  Future<void> updateTemplate(String id, NotificationTemplate template) async {
    try {
      if (_useLocal.value || id.startsWith('builtin-') || id.startsWith('local-')) {
        final index = templates.indexWhere((t) => t.id == id);
        if (index != -1) {
          templates[index] = NotificationTemplate(
            id: id,
            name: template.name,
            titleTemplate: template.titleTemplate,
            messageTemplate: template.messageTemplate,
            category: template.category,
            variables: template.variables,
            createdAt: templates[index].createdAt,
          );
          templates.refresh();
        }
        Get.snackbar(
          'تم التحديث',
          'تم تحديث القالب',
          backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
          colorText: KasbyColors.textPrimary,
        );
        return;
      }

      await SupabaseService.client
          .from('notification_templates')
          .update(template.toJson())
          .eq('id', id);
      await loadTemplates();

      Get.snackbar(
        'تم التحديث',
        'تم تحديث القالب بنجاح',
        backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'NotificationTemplateController',
        method: 'updateTemplate',
        feature: 'Notifications',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل تحديث القالب');
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      if (_useLocal.value || id.startsWith('builtin-') || id.startsWith('local-')) {
        templates.removeWhere((t) => t.id == id);
        templates.refresh();
        Get.snackbar(
          'تم الحذف',
          'تم حذف القالب',
          backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
          colorText: KasbyColors.textPrimary,
        );
        return;
      }

      await SupabaseService.client
          .from('notification_templates')
          .delete()
          .eq('id', id);
      templates.removeWhere((t) => t.id == id);
      templates.refresh();

      Get.snackbar(
        'تم الحذف',
        'تم حذف القالب بنجاح',
        backgroundColor: KasbyColors.success.withValues(alpha: 0.9),
        colorText: KasbyColors.textPrimary,
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'NotificationTemplateController',
        method: 'deleteTemplate',
        feature: 'Notifications',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل حذف القالب');
    }
  }

  List<String> extractVariables(String text) {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    return regex.allMatches(text).map((m) => m.group(1)!).toSet().toList();
  }
}
