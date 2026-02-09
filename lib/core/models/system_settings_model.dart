/// System Settings Model
/// Manages system-wide controls and emergency statuses
class SystemSettings {
  final bool pauseWithdrawals;
  final bool pauseProfits;
  final bool systemFreeze;
  final DateTime updatedAt;
  final String updatedBy;

  SystemSettings({
    required this.pauseWithdrawals,
    required this.pauseProfits,
    required this.systemFreeze,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      pauseWithdrawals: json['pauseWithdrawals'] ?? false,
      pauseProfits: json['pauseProfits'] ?? false,
      systemFreeze: json['systemFreeze'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      updatedBy: json['updatedBy'] ?? 'System',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pauseWithdrawals': pauseWithdrawals,
      'pauseProfits': pauseProfits,
      'systemFreeze': systemFreeze,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  SystemSettings copyWith({
    bool? pauseWithdrawals,
    bool? pauseProfits,
    bool? systemFreeze,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SystemSettings(
      pauseWithdrawals: pauseWithdrawals ?? this.pauseWithdrawals,
      pauseProfits: pauseProfits ?? this.pauseProfits,
      systemFreeze: systemFreeze ?? this.systemFreeze,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
