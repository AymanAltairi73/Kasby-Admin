/// Settings Data Models
import '../../../core/services/app_logger_service.dart';

class FAQItem {
  final String id;
  final String question;
  final String answer;

  FAQItem({required this.id, required this.question, required this.answer});

  FAQItem copyWith({String? question, String? answer}) {
    return FAQItem(
      id: id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
    );
  }

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    try {
      return FAQItem(
        id: json['id'] ?? '',
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
      );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'FAQItem',
        method: 'fromJson',
        feature: 'Settings',
        status: 'FAILED',
        params: {'id': json['id']?.toString()},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'question': question, 'answer': answer};
  }
}

class TermSection {
  final String id;
  final String title;
  final String content;
  final int order;

  TermSection({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
  });

  TermSection copyWith({String? title, String? content, int? order}) {
    return TermSection(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
    );
  }

  factory TermSection.fromJson(Map<String, dynamic> json) {
    try {
      return TermSection(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        order: json['order'] ?? 0,
      );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'TermSection',
        method: 'fromJson',
        feature: 'Settings',
        status: 'FAILED',
        params: {'id': json['id']?.toString()},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'content': content, 'order': order};
  }
}

class FeeItem {
  final String id;
  final String label;
  final String value;
  final String category;
  final double? percentage;
  final double? fixedAmount;
  final bool isActive;

  FeeItem({
    required this.id,
    required this.label,
    required this.value,
    required this.category,
    this.percentage,
    this.fixedAmount,
    this.isActive = true,
  });

  FeeItem copyWith({
    String? label,
    String? value,
    String? category,
    double? percentage,
    double? fixedAmount,
    bool? isActive,
  }) {
    return FeeItem(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
      category: category ?? this.category,
      percentage: percentage ?? this.percentage,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      isActive: isActive ?? this.isActive,
    );
  }

  factory FeeItem.fromJson(Map<String, dynamic> json) {
    try {
      return FeeItem(
        id: json['id']?.toString() ?? '',
        label: json['label'] ?? '',
        value: json['value'] ?? '',
        category: json['category'] ?? '',
        percentage: json['percentage'] is num ? (json['percentage'] as num).toDouble() : null,
        fixedAmount: json['fixed_amount'] is num ? (json['fixed_amount'] as num).toDouble() : null,
        isActive: json['is_active'] ?? true,
      );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'FeeItem',
        method: 'fromJson',
        feature: 'Settings',
        status: 'FAILED',
        params: {'id': json['id']?.toString()},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'value': value,
      'category': category,
      'percentage': percentage,
      'fixed_amount': fixedAmount,
      'is_active': isActive,
    };
  }
}

class CurrencyItem {
  final String id;
  final String name;
  final String code;
  final String rate;
  final bool isBase;
  final int? iconCode;
  final String? iconFamily;
  final String? iconPackage;

  CurrencyItem({
    required this.id,
    required this.name,
    required this.code,
    required this.rate,
    this.isBase = false,
    this.iconCode,
    this.iconFamily,
    this.iconPackage,
  });

  CurrencyItem copyWith({
    String? name,
    String? code,
    String? rate,
    bool? isBase,
    int? iconCode,
    String? iconFamily,
    String? iconPackage,
  }) {
    return CurrencyItem(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      rate: rate ?? this.rate,
      isBase: isBase ?? this.isBase,
      iconCode: iconCode ?? this.iconCode,
      iconFamily: iconFamily ?? this.iconFamily,
      iconPackage: iconPackage ?? this.iconPackage,
    );
  }

  factory CurrencyItem.fromJson(Map<String, dynamic> json) {
    try {
      return CurrencyItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        rate: json['rate'] ?? '',
        isBase: json['isBase'] ?? false,
        iconCode: json['icon_code'] is int
            ? json['icon_code']
            : (json['icon_code'] != null
                  ? int.tryParse(json['icon_code'].toString())
                  : null),
        iconFamily: json['icon_family'],
        iconPackage: json['icon_package'],
      );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'CurrencyItem',
        method: 'fromJson',
        feature: 'Settings',
        status: 'FAILED',
        params: {'id': json['id']?.toString()},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'rate': rate,
      'isBase': isBase,
      'icon_code': iconCode,
      'icon_family': iconFamily,
      'icon_package': iconPackage,
    };
  }
}

class LimitItem {
  final String id;
  final String label;
  final String value;
  final String tier; // e.g., 'Normal', 'VIP'
  final bool isUnlimited;
  final String? category;

  LimitItem({
    required this.id,
    required this.label,
    required this.value,
    required this.tier,
    this.isUnlimited = false,
    this.category,
  });

  LimitItem copyWith({
    String? label,
    String? value,
    String? tier,
    bool? isUnlimited,
    String? category,
  }) {
    return LimitItem(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
      tier: tier ?? this.tier,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      category: category ?? this.category,
    );
  }

  factory LimitItem.fromJson(Map<String, dynamic> json) {
    try {
      return LimitItem(
        id: json['id']?.toString() ?? '',
        label: json['label'] ?? '',
        value: json['value']?.toString() ?? '0',
        tier: json['tier'] ?? '',
        isUnlimited: json['is_unlimited'] ?? false,
        category: json['category'],
      );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'LimitItem',
        method: 'fromJson',
        feature: 'Settings',
        status: 'FAILED',
        params: {'id': json['id']?.toString()},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'value': value,
      'tier': tier,
      'is_unlimited': isUnlimited,
      'category': category,
    };
  }
}
