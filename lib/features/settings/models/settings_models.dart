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
