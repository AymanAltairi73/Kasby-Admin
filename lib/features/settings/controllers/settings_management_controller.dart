import 'dart:convert';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_models.dart';
import '../../../core/services/audit_logger.dart';

class SettingsManagementController extends GetxController {
  // Reactive Lists
  final faqs = <FAQItem>[].obs;
  final terms = <TermSection>[].obs;
  final fees = <FeeItem>[].obs;
  final currencies = <CurrencyItem>[].obs;
  final limits = <LimitItem>[].obs;

  // Maintenance State
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

  Future<void> loadSettings() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();

    // Load FAQs
    final faqData = prefs.getString('faqs');
    if (faqData != null) {
      final List decoded = jsonDecode(faqData);
      faqs.assignAll(decoded.map((e) => FAQItem.fromJson(e)).toList());
    } else {
      _loadDefaultFAQs();
    }

    // Load Terms
    final termsData = prefs.getString('terms');
    if (termsData != null) {
      final List decoded = jsonDecode(termsData);
      terms.assignAll(decoded.map((e) => TermSection.fromJson(e)).toList());
    } else {
      _loadDefaultTerms();
    }

    // Load Fees
    final feesData = prefs.getString('fees');
    if (feesData != null) {
      final List decoded = jsonDecode(feesData);
      fees.assignAll(decoded.map((e) => FeeItem.fromJson(e)).toList());
    } else {
      _loadDefaultFees();
    }

    // Load Currencies
    final currenciesData = prefs.getString('currencies');
    if (currenciesData != null) {
      final List decoded = jsonDecode(currenciesData);
      currencies.assignAll(
        decoded.map((e) => CurrencyItem.fromJson(e)).toList(),
      );
    } else {
      _loadDefaultCurrencies();
    }

    // Load Limits
    final limitsData = prefs.getString('limits');
    if (limitsData != null) {
      final List decoded = jsonDecode(limitsData);
      limits.assignAll(decoded.map((e) => LimitItem.fromJson(e)).toList());
    } else {
      _loadDefaultLimits();
    }

    // Load Maintenance
    isMaintenanceMode.value = prefs.getBool('isMaintenanceMode') ?? false;
    maintenanceMessage.value =
        prefs.getString('maintenanceMessage') ?? maintenanceMessage.value;

    isLoading.value = false;
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'faqs',
      jsonEncode(faqs.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'terms',
      jsonEncode(terms.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'fees',
      jsonEncode(fees.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'currencies',
      jsonEncode(currencies.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'limits',
      jsonEncode(limits.map((e) => e.toJson()).toList()),
    );
    await prefs.setBool('isMaintenanceMode', isMaintenanceMode.value);
    await prefs.setString('maintenanceMessage', maintenanceMessage.value);
  }

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
        icon: FontAwesomeIcons.dollarSign,
      ),
      CurrencyItem(
        id: '2',
        name: 'الدرهم الإماراتي',
        code: 'AED',
        rate: '3.67',
        isBase: false,
        icon: FontAwesomeIcons.briefcase,
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

  // --- CRUD Actions ---

  // Maintenance
  void toggleMaintenance(bool value) {
    isMaintenanceMode.value = value;
    saveSettings();
    _logAction('تغيير وضع الصيانة إلى: ${value ? 'مفعل' : 'معطل'}');
  }

  void updateMaintenanceMessage(String message) {
    maintenanceMessage.value = message;
    saveSettings();
    _logAction('تحديث رسالة الصيانة');
  }

  // FAQ
  void addFAQ(String question, String answer) {
    faqs.add(
      FAQItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: question,
        answer: answer,
      ),
    );
    saveSettings();
    _logAction('إضافة سؤال شائع: $question');
  }

  void updateFAQ(String id, String question, String answer) {
    int index = faqs.indexWhere((e) => e.id == id);
    if (index != -1) {
      faqs[index] = faqs[index].copyWith(question: question, answer: answer);
      saveSettings();
      _logAction('تحديث سؤال شائع: $question');
    }
  }

  void deleteFAQ(String id) {
    faqs.removeWhere((e) => e.id == id);
    saveSettings();
    _logAction('حذف سؤال شائع');
  }

  // Terms
  void addTerm(String title, String content) {
    terms.add(
      TermSection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        order: terms.length + 1,
      ),
    );
    saveSettings();
    _logAction('إضافة بند شروط: $title');
  }

  void updateTerm(String id, String title, String content) {
    int index = terms.indexWhere((e) => e.id == id);
    if (index != -1) {
      terms[index] = terms[index].copyWith(title: title, content: content);
      saveSettings();
      _logAction('تحديث بند شروط: $title');
    }
  }

  void deleteTerm(String id) {
    terms.removeWhere((e) => e.id == id);
    saveSettings();
    _logAction('حذف بند شروط');
  }

  void reorderTerms(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = terms.removeAt(oldIndex);
    terms.insert(newIndex, item);

    for (int i = 0; i < terms.length; i++) {
      terms[i] = terms[i].copyWith(order: i + 1);
    }
    saveSettings();
    _logAction('إعادة ترتيب بنود الشروط');
  }

  // Fees
  void updateFee(String id, String newValue) {
    int index = fees.indexWhere((e) => e.id == id);
    if (index != -1) {
      fees[index] = fees[index].copyWith(value: newValue);
      saveSettings();
      _logAction('تحديث قيمة الرسوم: ${fees[index].label}');
    }
  }

  // Currencies
  void addCurrency(CurrencyItem currency) {
    if (currency.isBase) {
      for (int i = 0; i < currencies.length; i++) {
        currencies[i] = currencies[i].copyWith(isBase: false);
      }
    }
    currencies.add(currency);
    saveSettings();
    _logAction('إضافة عملة جديدة: ${currency.name}');
  }

  void deleteCurrency(String id) {
    currencies.removeWhere((e) => e.id == id);
    saveSettings();
    _logAction('حذف عملة');
  }

  // Limits
  void updateLimit(String id, String newValue) {
    int index = limits.indexWhere((e) => e.id == id);
    if (index != -1) {
      limits[index] = limits[index].copyWith(value: newValue);
      saveSettings();
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
