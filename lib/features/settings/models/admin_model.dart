enum AdminRole { superAdmin, manager, support, viewer }

class AdminUser {
  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final String status; // Active, Inactive, Blocked
  final DateTime createdAt;
  final String lastLogin;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.lastLogin,
  });
}
