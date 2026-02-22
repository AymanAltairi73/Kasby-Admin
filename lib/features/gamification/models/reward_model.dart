/// Reward Model
class Reward {
  final String id;
  final String title;
  final String description;
  final int points;
  final String icon;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
  });

  Reward copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    String? icon,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      icon: icon ?? this.icon,
    );
  }

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    points: json['points'],
    icon: json['icon'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'points': points,
    'icon': icon,
  };
}

/// Prize Model for Spin Wheel
class Prize {
  final String id;
  final String label;
  final String value;
  final String type; // Points, Cash
  final double probability;

  Prize({
    required this.id,
    required this.label,
    required this.value,
    required this.type,
    required this.probability,
  });

  Prize copyWith({
    String? id,
    String? label,
    String? value,
    String? type,
    double? probability,
  }) {
    return Prize(
      id: id ?? this.id,
      label: label ?? this.label,
      value: value ?? this.value,
      type: type ?? this.type,
      probability: probability ?? this.probability,
    );
  }

  factory Prize.fromJson(Map<String, dynamic> json) => Prize(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    label: json['label'],
    value: json['value'],
    type: json['type'],
    probability: (json['probability'] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'type': type,
    'probability': probability,
  };
}

/// Point Rule Model
class PointRule {
  final String id;
  final String action;
  final int points;
  final String type; // Earn, Redeem
  final bool isDefault;

  PointRule({
    required this.id,
    required this.action,
    required this.points,
    required this.type,
    this.isDefault = true,
  });

  PointRule copyWith({
    String? id,
    String? action,
    int? points,
    String? type,
    bool? isDefault,
  }) {
    return PointRule(
      id: id ?? this.id,
      action: action ?? this.action,
      points: points ?? this.points,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory PointRule.fromJson(Map<String, dynamic> json) => PointRule(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    action: json['action'],
    points: json['points'] is int
        ? json['points']
        : int.tryParse(json['points']?.toString() ?? '0') ?? 0,
    type: json['type'] ?? 'Earn',
    isDefault: json['isDefault'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'points': points,
    'type': type,
    'isDefault': isDefault,
  };
}
