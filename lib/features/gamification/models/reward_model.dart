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
}

/// Prize Model for Spin Wheel
class Prize {
  final String label;
  final String value;
  final String type; // Points, Cash
  final double probability;

  Prize({
    required this.label,
    required this.value,
    required this.type,
    required this.probability,
  });
}

/// Point Rule Model
class PointRule {
  final String action;
  final String points;
  final bool isDefault;

  PointRule({
    required this.action,
    required this.points,
    this.isDefault = true,
  });
}
