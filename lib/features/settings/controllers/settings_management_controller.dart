import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/settings_models.dart';
import '../../../core/services/audit_logger.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

/// Settings Management Controller
/// Manages FAQs, Terms, Fees, Currencies, Limits, and Maintenance
/// All data stored in Supabase — Single Source of Truth
class SettingsManagementController extends GetxController {
  // Reactive Lists
  final faqs = <FAQItem>[].obs;
  final terms = <TermSection>[].obs;
  final fees = <FeeItem>[].obs;
  final currencies = <CurrencyItem>[].obs;
  final limits = <LimitItem>[].obs;

  // Maintenance State
  final settingsId = ''.obs;
  final isMaintenanceMode = false.obs;
  final maintenanceMessage =
      'النظام حالياً في مرحلة التحديث الدوري لضمان أعلى معايير الأمان والامتثال. سنعود قريباً.'
          .obs;

  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Load all settings from Supabase
  Future<void> loadSettings() async {
    debugPrint('[SettingsController] ▶ Loading all settings...');
    isLoading.value = true;
    await Future.wait([
      _loadFAQs(),
      _loadTerms(),
      _loadFees(),
      _loadCurrencies(),
      _loadLimits(),
      _loadMaintenance(),
    ]);
    isLoading.value = false;
  }

  // ─────────── Loaders ───────────

  Future<void> _loadFAQs() async {
    try {
      final response = await SupabaseService.client
          .from('faqs')
          .select()
          .order('created_at', ascending: true);
      if ((response as List).isNotEmpty) {
        faqs.assignAll(
          response.map(
            (e) => FAQItem(
              id: e['id'].toString(),
              question: e['question'] ?? '',
              answer: e['answer'] ?? '',
            ),
          ),
        );
      } else {
        _loadDefaultFAQs();
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: '_loadFAQs',
        error: e,
        stackTrace: stackTrace,
      );
      _loadDefaultFAQs();
    }
  }

  Future<void> _loadTerms() async {
    try {
      final response = await SupabaseService.client
          .from('terms_sections')
          .select()
          .order('sort_order', ascending: true);
      if ((response as List).isNotEmpty) {
        terms.assignAll(
          response.map(
            (e) => TermSection(
              id: e['id'].toString(),
              title: e['title'] ?? '',
              content: e['content'] ?? '',
              order: e['sort_order'] ?? 0,
            ),
          ),
        );
      } else {
        _loadDefaultTerms();
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: '_loadTerms',
        error: e,
        stackTrace: stackTrace,
      );
      _loadDefaultTerms();
    }
  }

  Future<void> _loadFees() async {
    try {
      final response = await SupabaseService.client
          .from('fees')
          .select()
          .order('created_at', ascending: true);
      if ((response as List).isNotEmpty) {
        fees.assignAll(
          response.map(
            (e) => FeeItem(
              id: e['id'].toString(),
              label: e['label'] ?? '',
              value: e['value'] ?? '',
              category: e['category'] ?? '',
            ),
          ),
        );
      } else {
        _loadDefaultFees();
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: '_loadFees',
        error: e,
        stackTrace: stackTrace,
      );
      _loadDefaultFees();
    }
  }

  Future<void> _loadCurrencies() async {
    try {
      final response = await SupabaseService.client
          .from('currencies')
          .select()
          .order('updated_at', ascending: true);
      if ((response as List).isNotEmpty) {
        currencies.assignAll(
          response.map(
            (e) => CurrencyItem(
              id: e['id'].toString(),
              name: e['name'] ?? '',
              code: e['code'] ?? '',
              rate: e['rate']?.toString() ?? '0',
              isBase: e['is_base'] ?? false,
              iconCode: e['icon_code'] ?? FontAwesomeIcons.dollarSign.codePoint,
              iconFamily: e['icon_family'],
              iconPackage: e['icon_package'],
            ),
          ),
        );
      } else {
        _loadDefaultCurrencies();
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: '_loadCurrencies',
        error: e,
        stackTrace: stackTrace,
      );
      _loadDefaultCurrencies();
    }
  }

  Future<void> _loadLimits() async {
    try {
      final response = await SupabaseService.client
          .from('transaction_limits')
          .select()
          .order('created_at', ascending: true);
      if ((response as List).isNotEmpty) {
        limits.assignAll(
          response.map(
            (e) => LimitItem(
              id: e['id'].toString(),
              label: e['label'] ?? '',
              value: e['value']?.toString() ?? '0',
              tier: e['tier'] ?? 'Normal',
            ),
          ),
        );
      } else {
        _loadDefaultLimits();
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: '_loadLimits',
        error: e,
        stackTrace: stackTrace,
      );
      _loadDefaultLimits();
    }
  }

  Future<void> _loadMaintenance() async {
    try {
      final response = await SupabaseService.client
          .from('system_settings')
          .select('id, is_maintenance_mode, maintenance_message')
          .limit(1)
          .maybeSingle();
      if (response != null) {
        settingsId.value = response['id'].toString();
        isMaintenanceMode.value = response['is_maintenance_mode'] ?? false;
        if (response['maintenance_message'] != null &&
            (response['maintenance_message'] as String).isNotEmpty) {
          maintenanceMessage.value = response['maintenance_message'];
        }
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: '_loadMaintenance',
        error: e,
        stackTrace: stackTrace,
      );
      // Keep defaults
    }
  }

  // ─────────── Defaults (fallback only) ───────────

  void _loadDefaultFAQs() {
    faqs.assignAll([
      FAQItem(
        id: '1',
        question: 'كيف يمكنني إضافة مشرف جديد لوحدة التحكم؟',
        answer:
            'يمكنك ذلك من خلال قسم "إدارة المشرفين" في الإعدادات، ثم النقر على زر الإضافة وتعبئة بيانات المشرف الجديد مع تحديد الصلاحيات المطلوبة.',
      ),
      FAQItem(
        id: '2',
        question: 'ما هي طريقة تفعيل وضع الصيانة للتطبيق؟',
        answer:
            'يتم التفعيل من قسم "وضع الصيانة" في الإعدادات، حيث يمكنك كتابة رسالة مخصصة تظهر للمستخدمين أثناء فترة العمل على النظام.',
      ),
      FAQItem(
        id: '3',
        question: 'كيف يتم تأمين بيانات الاستثمارات المالية؟',
        answer:
            'تستخدم Kasby Panel أنظمة تشفير متطورة (End-to-End Encryption) لضمان عدم وصول أي طرف غير مصرح له لبيانات المستخدمين أو الحركات المالية.',
      ),
    ]);
  }

  void _loadDefaultTerms() {
    terms.assignAll([
      TermSection(
        id: '1',
        title: '1. أركان الاتفاقية والقبول',
        content:
            'باستجابتك للدخول إلى منظومة Kasby Panel الإدارية، فإنك تقر بموافقتك الكاملة وغير المشروطة على كافة الضوابط والسياسات المنصوص عليها في هذه الاتفاقية.',
        order: 1,
      ),
      TermSection(
        id: '2',
        title: '2. بروتوكولات حماية الحساب والمسؤولية',
        content:
            'يتحمل المشرف المعتمد المسؤولية القانونية الكاملة عن حماية بيانات الدخول الخاصة به. يمنع منعاً باتاً مشاركة الصلاحيات مع أي طرف ثالث.',
        order: 2,
      ),
    ]);
  }

  void _loadDefaultFees() {
    fees.assignAll([
      FeeItem(
        id: '1',
        label: 'الإيداع البنكي',
        value: '1.5%',
        category: 'Deposit',
      ),
      FeeItem(
        id: '2',
        label: 'بطاقة الائتمان',
        value: '2.5%',
        category: 'Deposit',
      ),
      FeeItem(
        id: '3',
        label: 'السحب البنكي',
        value: '\$10.00',
        category: 'Withdraw',
      ),
      FeeItem(
        id: '4',
        label: 'رسوم الإدارة سنوية',
        value: '2.0%',
        category: 'Investment',
      ),
    ]);
  }

  void _loadDefaultCurrencies() {
    currencies.assignAll([
      CurrencyItem(
        id: '1',
        name: 'الدولار الأمريكي',
        code: 'USD',
        rate: '1.00',
        isBase: true,
        iconCode: FontAwesomeIcons.dollarSign.codePoint,
        iconFamily: FontAwesomeIcons.dollarSign.fontFamily,
        iconPackage: FontAwesomeIcons.dollarSign.fontPackage,
      ),
      CurrencyItem(
        id: '2',
        name: 'الدرهم الإماراتي',
        code: 'AED',
        rate: '3.67',
        isBase: false,
        iconCode: FontAwesomeIcons.briefcase.codePoint,
        iconFamily: FontAwesomeIcons.briefcase.fontFamily,
        iconPackage: FontAwesomeIcons.briefcase.fontPackage,
      ),
    ]);
  }

  void _loadDefaultLimits() {
    limits.assignAll([
      LimitItem(
        id: '1',
        label: 'الحد الأدنى للإيداع',
        value: '50',
        tier: 'Normal',
      ),
      LimitItem(
        id: '2',
        label: 'الحد الأقصى للإيداع (يومي)',
        value: '5000',
        tier: 'Normal',
      ),
      LimitItem(
        id: '3',
        label: 'الحد الأدنى للإيداع',
        value: '10',
        tier: 'VIP',
      ),
      LimitItem(
        id: '4',
        label: 'الحد الأقصى للسحب (شهري)',
        value: 'Unlimited',
        tier: 'VIP',
      ),
    ]);
  }

  // ─────────── CRUD Actions → Supabase ───────────

  // Maintenance
  void toggleMaintenance(bool value) async {
    isMaintenanceMode.value = value;
    try {
      await SupabaseService.client
          .from('system_settings')
          .update({
            'is_maintenance_mode': value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', settingsId.value);
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: 'toggleMaintenance',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _logAction('تغيير وضع الصيانة إلى: ${value ? 'مفعل' : 'معطل'}');
  }

  void updateMaintenanceMessage(String message) async {
    maintenanceMessage.value = message;
    try {
      await SupabaseService.client
          .from('system_settings')
          .update({
            'maintenance_message': message,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', settingsId.value);
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: 'updateMaintenanceMessage',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _logAction('تحديث رسالة الصيانة');
  }

  // FAQ — CRUD to Supabase
  void addFAQ(String question, String answer) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    faqs.add(FAQItem(id: newId, question: question, answer: answer));
    try {
      await SupabaseService.client.from('faqs').insert({
        'question': question,
        'answer': answer,
      });
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: 'addFAQ',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _logAction('إضافة سؤال شائع: $question');
  }

  void updateFAQ(String id, String question, String answer) async {
    int index = faqs.indexWhere((e) => e.id == id);
    if (index != -1) {
      faqs[index] = faqs[index].copyWith(question: question, answer: answer);
      try {
        await SupabaseService.client
            .from('faqs')
            .update({'question': question, 'answer': answer})
            .eq('id', id);
      } catch (e, stackTrace) {
        AppLoggerService.logError(
          controller: 'SettingsManagementController',
          method: 'updateFAQ',
          error: e,
          stackTrace: stackTrace,
        );
      }
      _logAction('تحديث سؤال شائع: $question');
    }
  }

  void deleteFAQ(String id) async {
    faqs.removeWhere((e) => e.id == id);
    try {
      await SupabaseService.client.from('faqs').delete().eq('id', id);
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: 'deleteFAQ',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _logAction('حذف سؤال شائع');
  }

  // Terms — CRUD to Supabase
  void addTerm(String title, String content) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    terms.add(
      TermSection(
        id: newId,
        title: title,
        content: content,
        order: terms.length + 1,
      ),
    );
    try {
      await SupabaseService.client.from('terms_sections').insert({
        'title': title,
        'content': content,
        'sort_order': terms.length,
      });
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: 'addTerm',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _logAction('إضافة بند شروط: $title');
  }

  void updateTerm(String id, String title, String content) async {
    int index = terms.indexWhere((e) => e.id == id);
    if (index != -1) {
      terms[index] = terms[index].copyWith(title: title, content: content);
      try {
        await SupabaseService.client
            .from('terms_sections')
            .update({'title': title, 'content': content})
            .eq('id', id);
      } catch (e, stackTrace) {
        AppLoggerService.logError(
          controller: 'SettingsManagementController',
          method: 'updateTerm',
          error: e,
          stackTrace: stackTrace,
        );
      }
      _logAction('تحديث بند شروط: $title');
    }
  }

  void deleteTerm(String id) async {
    terms.removeWhere((e) => e.id == id);
    try {
      await SupabaseService.client.from('terms_sections').delete().eq('id', id);
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: 'deleteTerm',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _logAction('حذف بند شروط');
  }

  void reorderTerms(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = terms.removeAt(oldIndex);
    terms.insert(newIndex, item);

    for (int i = 0; i < terms.length; i++) {
      terms[i] = terms[i].copyWith(order: i + 1);
    }
    // Batch update sort_order in Supabase
    for (int i = 0; i < terms.length; i++) {
      try {
        await SupabaseService.client
            .from('terms_sections')
            .update({'sort_order': i + 1})
            .eq('id', terms[i].id);
      } catch (e, stackTrace) {
        AppLoggerService.logError(
          controller: 'SettingsManagementController',
          method: 'reorderTerms',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    _logAction('إعادة ترتيب بنود الشروط');
  }

  // Fees — update to Supabase
  void updateFee(String id, String newValue) async {
    int index = fees.indexWhere((e) => e.id == id);
    if (index != -1) {
      fees[index] = fees[index].copyWith(value: newValue);
      try {
        await SupabaseService.client
            .from('fees')
            .update({'value': newValue})
            .eq('id', id);
      } catch (e, stackTrace) {
        AppLoggerService.logError(
          controller: 'SettingsManagementController',
          method: 'updateFee',
          error: e,
          stackTrace: stackTrace,
        );
      }
      _logAction('تحديث قيمة الرسوم: ${fees[index].label}');
    }
  }

  // Currencies — CRUD to Supabase
  void addCurrency(CurrencyItem currency) async {
    if (currency.isBase) {
      for (int i = 0; i < currencies.length; i++) {
        currencies[i] = currencies[i].copyWith(isBase: false);
      }
    }
    currencies.add(currency);
    try {
      await SupabaseService.client.from('currencies').insert({
        'name': currency.name,
        'code': currency.code,
        'rate': currency.rate,
        'is_base': currency.isBase,
        'icon_code': currency.iconCode,
        'icon_family': currency.iconFamily,
        'icon_package': currency.iconPackage,
      });
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: 'addCurrency',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _logAction('إضافة عملة جديدة: ${currency.name}');
  }

  void deleteCurrency(String id) async {
    currencies.removeWhere((e) => e.id == id);
    try {
      await SupabaseService.client.from('currencies').delete().eq('id', id);
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'SettingsManagementController',
        method: 'deleteCurrency',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _logAction('حذف عملة');
  }

  // Limits — update to Supabase
  void updateLimit(String id, String newValue) async {
    int index = limits.indexWhere((e) => e.id == id);
    if (index != -1) {
      limits[index] = limits[index].copyWith(value: newValue);
      try {
        await SupabaseService.client
            .from('transaction_limits')
            .update({'value': newValue})
            .eq('id', id);
      } catch (e, stackTrace) {
        AppLoggerService.logError(
          controller: 'SettingsManagementController',
          method: 'updateLimit',
          error: e,
          stackTrace: stackTrace,
        );
      }
      _logAction('تحديث حد المعاملة: ${limits[index].label}');
    }
  }

  void _logAction(String details) {
    AuditLogger.log(
      adminName: 'SuperAdmin',
      action: 'تعديل الإعدادات',
      details: details,
    );
  }
}
