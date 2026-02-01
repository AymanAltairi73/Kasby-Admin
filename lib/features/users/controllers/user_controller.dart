import 'package:get/get.dart';
import '../models/user_model.dart';
import '../../../core/services/audit_logger.dart';

/// User Management Controller
/// Handles user list, search, filter, and admin actions
class UserController extends GetxController {
  final users = <User>[].obs;
  final filteredUsers = <User>[].obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs; // All, Active, Blocked
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  /// Load users from API (mock)
  Future<void> loadUsers() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    users.value = User.getMockUsers();
    filteredUsers.value = users;

    isLoading.value = false;
  }

  /// Search users by name, email, or phone
  void searchUsers(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  /// Filter users by status
  void filterByStatus(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  /// Apply search and filter
  void _applyFilters() {
    var result = users.toList();

    // Apply status filter
    if (selectedStatus.value != 'All') {
      result = result
          .where((user) => user.status == selectedStatus.value)
          .toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      result = result.where((user) {
        final query = searchQuery.value.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.phone.contains(query);
      }).toList();
    }

    filteredUsers.value = result;
  }

  /// Add balance to user
  Future<void> addBalance(String userId, double amount, String reason) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    // Log action
    await AuditLogger.log(
      adminName: 'Admin', // In real app, get from AuthController
      action: 'إضافة رصيد',
      details: 'تم إضافة $amount للمستخدم $userId. السبب: $reason',
    );

    isLoading.value = false;
  }

  /// Deduct balance from user
  Future<void> deductBalance(
    String userId,
    double amount,
    String reason,
  ) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    // Log action
    await AuditLogger.log(
      adminName: 'Admin',
      action: 'خصم رصيد',
      details: 'تم خصم $amount من المستخدم $userId. السبب: $reason',
    );

    isLoading.value = false;
  }

  /// Block user
  Future<void> blockUser(String userId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      // Log action
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'حظر مستخدم',
        details: 'تم حظر المستخدم $userId',
      );
    }

    isLoading.value = false;
    loadUsers(); // Reload
  }

  /// Activate user
  Future<void> activateUser(String userId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      // Log action
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'تفعيل مستخدم',
        details: 'تم تفعيل المستخدم $userId',
      );
    }

    isLoading.value = false;
    loadUsers(); // Reload
  }
}
