import 'package:flutter/material.dart';

/// Settings Data Models
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
    return FAQItem(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
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
    return TermSection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      order: json['order'] ?? 0,
    );
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

  FeeItem({
    required this.id,
    required this.label,
    required this.value,
    required this.category,
  });

  FeeItem copyWith({String? label, String? value, String? category}) {
    return FeeItem(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
      category: category ?? this.category,
    );
  }

  factory FeeItem.fromJson(Map<String, dynamic> json) {
    return FeeItem(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      value: json['value'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'value': value, 'category': category};
  }
}

class CurrencyItem {
  final String id;
  final String name;
  final String code;
  final String rate;
  final bool isBase;
  final dynamic icon; // IconData or similar

  CurrencyItem({
    required this.id,
    required this.name,
    required this.code,
    required this.rate,
    this.isBase = false,
    this.icon,
  });

  CurrencyItem copyWith({
    String? name,
    String? code,
    String? rate,
    bool? isBase,
    dynamic icon,
  }) {
    return CurrencyItem(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      rate: rate ?? this.rate,
      isBase: isBase ?? this.isBase,
      icon: icon ?? this.icon,
    );
  }

  factory CurrencyItem.fromJson(Map<String, dynamic> json) {
    IconData? iconData;
    if (json['icon_code'] != null) {
      iconData = IconData(
        json['icon_code'],
        fontFamily: json['icon_family'] ?? 'MaterialIcons',
        fontPackage: json['icon_package'],
      );
    }

    return CurrencyItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      rate: json['rate'] ?? '',
      isBase: json['isBase'] ?? false,
      icon: iconData,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      'id': id,
      'name': name,
      'code': code,
      'rate': rate,
      'isBase': isBase,
    };

    if (icon is IconData) {
      final data = icon as IconData;
      map['icon_code'] = data.codePoint;
      map['icon_family'] = data.fontFamily;
      map['icon_package'] = data.fontPackage;
    }

    return map;
  }
}

class LimitItem {
  final String id;
  final String label;
  final String value;
  final String tier; // e.g., 'Normal', 'VIP'

  LimitItem({
    required this.id,
    required this.label,
    required this.value,
    required this.tier,
  });

  LimitItem copyWith({String? label, String? value, String? tier}) {
    return LimitItem(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
      tier: tier ?? this.tier,
    );
  }

  factory LimitItem.fromJson(Map<String, dynamic> json) {
    return LimitItem(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      value: json['value'] ?? '',
      tier: json['tier'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'value': value, 'tier': tier};
  }
}
