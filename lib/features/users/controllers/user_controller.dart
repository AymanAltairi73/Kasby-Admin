import 'package:get/get.dart';
import '../models/user_model.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/controllers/transaction_controller.dart';
import '../../../core/services/audit_logger.dart';
import '../../../core/models/time_filter.dart';

/// User Management Controller
/// Handles user list, search, filter, and admin actions
class UserController extends GetxController {
  final users = <User>[].obs;
  final filteredUsers = <User>[].obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs; // All, Active, Blocked
  final selectedTimeFilter = TimeFilter.all.obs;
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

    // Apply time filter
    final now = DateTime.now();
    if (selectedTimeFilter.value != TimeFilter.all) {
      result = result.where((user) {
        final difference = now.difference(user.createdAt);
        switch (selectedTimeFilter.value) {
          case TimeFilter.daily:
            return difference.inDays == 0 && user.createdAt.day == now.day;
          case TimeFilter.weekly:
            return difference.inDays <= 7;
          case TimeFilter.monthly:
            return difference.inDays <= 30;
          default:
            return true;
        }
      }).toList();
    }

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

  /// Add new user
  Future<void> addUser({
    required String name,
    required String email,
    required String phone,
  }) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      status: 'Active',
      walletBalance: 0.0,
      investedAmount: 0.0,
      pendingAmount: 0.0,
      createdAt: DateTime.now(),
    );

    users.add(newUser);

    await AuditLogger.log(
      adminName: 'Admin',
      action: 'إضافة مستخدم جديد',
      details: 'تم إضافة المستخدم $name ($email)',
    );

    isLoading.value = false;
    _applyFilters();
    Get.snackbar('نجح', 'تم إضافة المستخدم بنجاح');
  }

  /// Update user
  Future<void> updateUser(User updatedUser) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final index = users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      final oldUser = users[index];
      users[index] = updatedUser;

      await AuditLogger.log(
        adminName: 'Admin',
        action: 'تعديل بيانات مستخدم',
        details: 'تم تعديل بيانات المستخدم ${oldUser.name}',
      );

      Get.snackbar('نجح', 'تم تحديث بيانات المستخدم');
    }

    isLoading.value = false;
    _applyFilters();
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final userName = users[index].name;
      users.removeAt(index);

      await AuditLogger.log(
        adminName: 'Admin',
        action: 'حذف مستخدم',
        details: 'تم حذف المستخدم $userName ($userId)',
      );

      Get.snackbar('نجح', 'تم حذف المستخدم بنجاح');
      if (Get.currentRoute.contains('user_details')) {
        Get.back();
      }
    }

    isLoading.value = false;
    _applyFilters();
  }

  /// Create a transaction request to add balance (No direct modification)
  Future<void> addBalance(String userId, double amount, String reason) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final user = users.firstWhere((u) => u.id == userId);
    final transactionController = Get.find<TransactionController>();

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: user.name,
      type: 'Adjustment',
      amount: amount,
      status: 'Pending',
      reason: 'إضافة رصيد: $reason',
      createdAt: DateTime.now(),
    );

    transactionController.transactions.add(transaction);

    await AuditLogger.log(
      adminName: 'Admin',
      action: 'طلب إضافة رصيد',
      details: 'تم طلب إضافة $amount للمستخدم ${user.name}. السبب: $reason',
    );

    isLoading.value = false;
    Get.snackbar('طلب معلق', 'تم إنشاء طلب إضافة الرصيد، بانتظار الموافقة');
  }

  /// Create a transaction request to deduct balance (No direct modification)
  Future<void> deductBalance(
    String userId,
    double amount,
    String reason,
  ) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final user = users.firstWhere((u) => u.id == userId);
    final transactionController = Get.find<TransactionController>();

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: user.name,
      type: 'Adjustment',
      amount: -amount, // Negative for deduction
      status: 'Pending',
      reason: 'خصم رصيد: $reason',
      createdAt: DateTime.now(),
    );

    transactionController.transactions.add(transaction);

    await AuditLogger.log(
      adminName: 'Admin',
      action: 'طلب خصم رصيد',
      details: 'تم طلب خصم $amount من المستخدم ${user.name}. السبب: $reason',
    );

    isLoading.value = false;
    Get.snackbar('طلب معلق', 'تم إنشاء طلب خصم الرصيد، بانتظار الموافقة');
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
