/// System Settings Model
/// Manages system-wide controls and emergency statuses
class SystemSettings {
  final bool pauseDeposits;
  final bool pauseWithdrawals;
  final bool pauseProfits;
  final bool pauseInvestments;
  final bool pauseLoans;
  final bool systemFreeze;
  final bool isMaintenanceMode;
  final String maintenanceMessage;
  final DateTime updatedAt;
  final String updatedBy;

  SystemSettings({
    required this.pauseDeposits,
    required this.pauseWithdrawals,
    required this.pauseProfits,
    required this.pauseInvestments,
    required this.pauseLoans,
    required this.systemFreeze,
    required this.isMaintenanceMode,
    required this.maintenanceMessage,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      pauseDeposits: json['pause_deposits'] ?? json['pauseDeposits'] ?? false,
      pauseWithdrawals:
          json['pause_withdrawals'] ?? json['pauseWithdrawals'] ?? false,
      pauseProfits: json['pause_profits'] ?? json['pauseProfits'] ?? false,
      pauseInvestments:
          json['pause_investments'] ?? json['pauseInvestments'] ?? false,
      pauseLoans: json['pause_loans'] ?? json['pauseLoans'] ?? false,
      systemFreeze: json['system_freeze'] ?? json['systemFreeze'] ?? false,
      isMaintenanceMode:
          json['is_maintenance_mode'] ?? json['isMaintenanceMode'] ?? false,
      maintenanceMessage:
          json['maintenance_message'] ?? json['maintenanceMessage'] ?? '',
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at']) ?? DateTime.now())
          : (json['updatedAt'] != null
                ? (DateTime.tryParse(json['updatedAt']) ?? DateTime.now())
                : DateTime.now()),
      updatedBy: json['updated_by'] ?? json['updatedBy'] ?? 'System',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pause_deposits': pauseDeposits,
      'pause_withdrawals': pauseWithdrawals,
      'pause_profits': pauseProfits,
      'pause_investments': pauseInvestments,
      'pause_loans': pauseLoans,
      'system_freeze': systemFreeze,
      'is_maintenance_mode': isMaintenanceMode,
      'maintenance_message': maintenanceMessage,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  SystemSettings copyWith({
    bool? pauseDeposits,
    bool? pauseWithdrawals,
    bool? pauseProfits,
    bool? pauseInvestments,
    bool? pauseLoans,
    bool? systemFreeze,
    bool? isMaintenanceMode,
    String? maintenanceMessage,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SystemSettings(
      pauseDeposits: pauseDeposits ?? this.pauseDeposits,
      pauseWithdrawals: pauseWithdrawals ?? this.pauseWithdrawals,
      pauseProfits: pauseProfits ?? this.pauseProfits,
      pauseInvestments: pauseInvestments ?? this.pauseInvestments,
      pauseLoans: pauseLoans ?? this.pauseLoans,
      systemFreeze: systemFreeze ?? this.systemFreeze,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
