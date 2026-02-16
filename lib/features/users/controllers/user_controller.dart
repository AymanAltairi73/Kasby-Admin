import 'package:get/get.dart';
import '../models/user_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/time_filter.dart';

/// User Controller — manages user data from Supabase `profiles` + `wallets`
class UserController extends GetxController {
  final users = <User>[].obs;
  final filteredUsers = <User>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'all'.obs;
  final selectedKyc = 'all'.obs;
  final selectedTimeFilter = TimeFilter.all.obs;
  final selectedCountry = ''.obs;
  final selectedAccountType = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  /// Load users from Supabase
  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select('*, wallets(*)')
          .order('created_at', ascending: false);

      users.value = (response as List)
          .map((json) => User.fromSupabase(json))
          .toList();
      _applyFilters();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل المستخدمين: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Search users
  void searchUsers(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  /// Filter by status
  void filterByStatus(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  /// Filter by KYC status
  void filterByKyc(String kyc) {
    selectedKyc.value = kyc;
    _applyFilters();
  }

  /// Filter by country
  void filterByCountry(String country) {
    selectedCountry.value = country;
    _applyFilters();
  }

  /// Filter by account type
  void filterByAccountType(String type) {
    selectedAccountType.value = type;
    _applyFilters();
  }

  void _applyFilters() {
    List<User> result = List.from(users);

    // Apply search
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where(
            (u) =>
                u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                u.phone.contains(q),
          )
          .toList();
    }

    // Apply status filter
    if (selectedStatus.value != 'all') {
      result = result
          .where(
            (u) => u.status.toLowerCase() == selectedStatus.value.toLowerCase(),
          )
          .toList();
    }

    // Apply KYC filter
    if (selectedKyc.value != 'all') {
      result = result
          .where(
            (u) => u.kycStatus.toLowerCase() == selectedKyc.value.toLowerCase(),
          )
          .toList();
    }

    // Apply country filter
    if (selectedCountry.value.isNotEmpty) {
      result = result
          .where(
            (u) =>
                u.country.toLowerCase() == selectedCountry.value.toLowerCase(),
          )
          .toList();
    }

    // Apply account type filter
    if (selectedAccountType.value.isNotEmpty) {
      result = result
          .where(
            (u) =>
                u.accountType.toLowerCase() ==
                selectedAccountType.value.toLowerCase(),
          )
          .toList();
    }

    filteredUsers.value = result;
  }

  /// Block user
  Future<void> blockUser(String userId) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'status': 'blocked'})
          .eq('id', userId);

      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(status: 'blocked');
        _applyFilters();
      }

      Get.snackbar(
        'تم',
        'تم حظر المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حظر المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Activate user
  Future<void> activateUser(String userId) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'status': 'active'})
          .eq('id', userId);

      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(status: 'active');
        _applyFilters();
      }

      Get.snackbar(
        'تم',
        'تم تفعيل المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تفعيل المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle block (convenience method)
  Future<void> toggleBlockUser(String userId) async {
    try {
      final user = users.firstWhere((u) => u.id == userId);
      if (user.status == 'blocked') {
        await activateUser(userId);
      } else {
        await blockUser(userId);
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Verify KYC / documents
  Future<void> verifyKyc(String userId) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'kyc_status': 'Verified'})
          .eq('id', userId);

      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(kycStatus: 'Verified');
        _applyFilters();
      }

      Get.snackbar(
        'تم',
        'تم التحقق من المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في التحقق', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Verify documents (alias for verifyKyc used by UI)
  Future<void> verifyDocuments(String userId) => verifyKyc(userId);

  /// Reject KYC
  Future<void> rejectKyc(String userId) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'kyc_status': 'Rejected'})
          .eq('id', userId);

      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(kycStatus: 'Rejected');
        _applyFilters();
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في رفض KYC',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Reject documents (alias for rejectKyc used by UI)
  Future<void> rejectDocuments(String userId, [String reason = '']) =>
      rejectKyc(userId);

  /// Add balance to user wallet
  Future<void> addBalance(
    String userId,
    double amount, [
    String reason = '',
  ]) async {
    try {
      await SupabaseService.client.rpc(
        'fn_admin_add_balance',
        params: {'p_user_id': userId, 'p_amount': amount},
      );

      await loadUsers();
      Get.snackbar(
        'تم',
        'تم إضافة الرصيد بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Fallback: update wallet directly
      try {
        final wallet = await SupabaseService.client
            .from('wallets')
            .select()
            .eq('user_id', userId)
            .single();

        final currentBalance = (wallet['available_balance'] ?? 0.0).toDouble();
        await SupabaseService.client
            .from('wallets')
            .update({'available_balance': currentBalance + amount})
            .eq('user_id', userId);

        await loadUsers();
        Get.snackbar(
          'تم',
          'تم إضافة الرصيد بنجاح',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e2) {
        Get.snackbar(
          'خطأ',
          'فشل في إضافة الرصيد: $e2',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  /// Deduct balance from user wallet
  Future<void> deductBalance(
    String userId,
    double amount, [
    String reason = '',
  ]) async {
    try {
      await SupabaseService.client.rpc(
        'fn_admin_deduct_balance',
        params: {'p_user_id': userId, 'p_amount': amount},
      );

      await loadUsers();
      Get.snackbar(
        'تم',
        'تم خصم الرصيد بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Fallback: update wallet directly
      try {
        final wallet = await SupabaseService.client
            .from('wallets')
            .select()
            .eq('user_id', userId)
            .single();

        final currentBalance = (wallet['available_balance'] ?? 0.0).toDouble();
        final newBalance = currentBalance - amount;
        if (newBalance < 0) {
          Get.snackbar(
            'خطأ',
            'الرصيد غير كافي',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        await SupabaseService.client
            .from('wallets')
            .update({'available_balance': newBalance})
            .eq('user_id', userId);

        await loadUsers();
        Get.snackbar(
          'تم',
          'تم خصم الرصيد بنجاح',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e2) {
        Get.snackbar(
          'خطأ',
          'فشل في خصم الرصيد: $e2',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  /// Add user from named parameters (matches UI call site)
  Future<void> addUser({
    required String name,
    required String country,
    required String city,
    required String phone,
    String whatsapp = '',
    String telegram = '',
    String email = '',
  }) async {
    try {
      await SupabaseService.client.from('profiles').insert({
        'full_name': name,
        'country': country,
        'city': city,
        'phone': phone,
        'whatsapp': whatsapp,
        'telegram': telegram,
        'email': email,
        'status': 'active',
        'kyc_status': 'none',
        'account_type': 'Free',
      });

      await loadUsers();
      Get.snackbar(
        'تم',
        'تم إضافة المستخدم بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في إضافة المستخدم: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Update user profile
  Future<void> updateUser(User user) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update(user.toSupabase())
          .eq('id', user.id);

      final idx = users.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        users[idx] = user;
        _applyFilters();
      }

      Get.snackbar(
        'تم',
        'تم تحديث بيانات المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث البيانات',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await SupabaseService.client.from('profiles').delete().eq('id', userId);

      users.removeWhere((u) => u.id == userId);
      _applyFilters();

      Get.snackbar(
        'تم',
        'تم حذف المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حذف المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Get user by ID
  User? getUserById(String userId) {
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }
}
