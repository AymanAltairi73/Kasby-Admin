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
  final selectedCountry = 'All'.obs; // New
  final selectedAccountType = 'All'.obs; // New
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
    _applyFilters();
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

  /// Filter users by country
  void filterByCountry(String country) {
    selectedCountry.value = country;
    _applyFilters();
  }

  /// Filter users by account type
  void filterByAccountType(String type) {
    selectedAccountType.value = type;
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
          //    .where((user) => user.status.toLowerCase() == selectedStatus.value.toLowerCase()) // Case insensitive if needed
          .toList();
    }

    // Apply country filter
    if (selectedCountry.value != 'All') {
      result = result
          .where((user) => user.country == selectedCountry.value)
          .toList();
    }

    // Apply account type filter
    if (selectedAccountType.value != 'All') {
      result = result
          .where((user) => user.accountType == selectedAccountType.value)
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
    String country = 'Unknown',
    String accountType = 'Free',
    String kycStatus = 'Unverified',
  }) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      status: 'Active',
      country: country,
      accountType: accountType,
      kycStatus: kycStatus,
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
      final user = users[index];
      users[index] = user.copyWith(status: 'Blocked'); // Update local state

      // Log action
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'حظر مستخدم',
        details: 'تم حظر المستخدم $userId',
      );
    }

    isLoading.value = false;
    _applyFilters(); // Re-apply filters
    update(); // Force update if needed
  }

  /// Activate user
  Future<void> activateUser(String userId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = users[index];
      users[index] = user.copyWith(status: 'Active'); // Update local state

      // Log action
      await AuditLogger.log(
        adminName: 'Admin',
        action: 'تفعيل مستخدم',
        details: 'تم تفعيل المستخدم $userId',
      );
    }

    isLoading.value = false;
    _applyFilters(); // Re-apply filters
    update();
  }

  /// Verify User Documents (KYC)
  Future<void> verifyDocuments(String userId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = users[index];
      users[index] = user.copyWith(
        kycStatus: 'Verified',
        accountType: 'Verified', // Auto upgrade to Verified
      );

      // Update Activity Log
      // In a real app, we would append to the list, but for now we rely on the object update (if mutable) or just log it
      // Since the list in model is final, we should ideally construct a new list.
      // For this mock, we are just updating the main user object in the list.
      // Let's assume we maintain local state only.

      await AuditLogger.log(
        adminName: 'Admin',
        action: 'توثيق حساب',
        details: 'تم توثيق حساب المستخدم ${user.name}',
      );

      Get.snackbar('نجح', 'تم توثيق الحساب بنجاح');
    }

    isLoading.value = false;
    _applyFilters();
    update();
  }

  /// Reject User Documents (KYC)
  Future<void> rejectDocuments(String userId, String reason) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = users[index];
      // Reset to Unverified or keep Pending depending on logic. Usually 'Unverified' allows re-upload.
      users[index] = user.copyWith(kycStatus: 'Unverified');

      await AuditLogger.log(
        adminName: 'Admin',
        action: 'رفض وثائق',
        details: 'تم رفض وثائق المستخدم ${user.name}. السبب: $reason',
      );

      Get.snackbar('تم', 'تم رفض الوثائق وإشعار المستخدم');
    }

    isLoading.value = false;
    _applyFilters();
    update();
  }

  /// Promote user to VIP
  Future<void> promoteToVIP(String userId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = users[index];
      users[index] = user.copyWith(accountType: 'VIP');

      await AuditLogger.log(
        adminName: 'Admin',
        action: 'ترقية إلى VIP',
        details: 'تم ترقية المستخدم ${user.name} إلى فئة VIP',
      );

      Get.snackbar('نجح', 'تمت ترقية المستخدم إلى VIP بنجاح');
    }

    isLoading.value = false;
    _applyFilters();
    update();
  }

  /// Reset Password (Mock)
  Future<void> resetPassword(String userId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final user = users.firstWhere((u) => u.id == userId);

    await AuditLogger.log(
      adminName: 'Admin',
      action: 'إعادة تعيين كلمة مرور',
      details: 'تم إرسال رابط إعادة تعيين كلمة المرور للمستخدم ${user.name}',
    );

    isLoading.value = false;
    Get.snackbar(
      'تم الإرسال',
      'تم إرسال رابط إعادة تعيين كلمة المرور للمستخدم',
    );
  }
}
