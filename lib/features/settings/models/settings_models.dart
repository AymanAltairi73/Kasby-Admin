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
}
