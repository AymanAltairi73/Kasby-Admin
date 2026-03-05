import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AdminUserAttributes;
import '../models/user_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/models/time_filter.dart';
import '../../auth/controllers/auth_controller.dart';

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
    // Listen to auth state — reload users when admin logs in
    try {
      final auth = Get.find<AuthController>();
      ever(auth.isLoggedIn, (loggedIn) {
        if (loggedIn) {
          loadUsers();
        } else {
          users.clear();
          filteredUsers.clear();
        }
      });
      // If already logged in at init time, load immediately
      if (auth.isLoggedIn.value) {
        loadUsers();
      }
    } catch (_) {
      // AuthController not ready yet — will reload via ever()
    }
  }

  /// Load users from Supabase
  Future<void> loadUsers() async {
    debugPrint('[UserController] ▶ Loading users from Supabase...');
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
      debugPrint('[UserController] ✓ Loaded ${users.length} users');
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'loadUsers',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل المستخدمين',
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

    // Apply role filter - by default hide admins from general user list
    result = result.where((u) => u.role != 'admin').toList();

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

    // Apply status filter (skip if 'all' or 'All')
    if (selectedStatus.value.toLowerCase() != 'all') {
      result = result
          .where(
            (u) => u.status.toLowerCase() == selectedStatus.value.toLowerCase(),
          )
          .toList();
    }

    // Apply KYC filter (skip if 'all' or 'All')
    if (selectedKyc.value.toLowerCase() != 'all') {
      result = result
          .where(
            (u) => u.kycStatus.toLowerCase() == selectedKyc.value.toLowerCase(),
          )
          .toList();
    }

    // Apply country filter (skip if empty or 'all'/'All')
    if (selectedCountry.value.isNotEmpty &&
        selectedCountry.value.toLowerCase() != 'all') {
      result = result
          .where(
            (u) =>
                u.country.toLowerCase() == selectedCountry.value.toLowerCase(),
          )
          .toList();
    }

    // Apply account type filter (skip if empty or 'all'/'All')
    if (selectedAccountType.value.isNotEmpty &&
        selectedAccountType.value.toLowerCase() != 'all') {
      result = result
          .where(
            (u) =>
                u.accountType.toLowerCase() ==
                selectedAccountType.value.toLowerCase(),
          )
          .toList();
    }

    // Apply time filter
    final now = DateTime.now();
    switch (selectedTimeFilter.value) {
      case TimeFilter.daily:
        result = result
            .where(
              (u) =>
                  u.createdAt.year == now.year &&
                  u.createdAt.month == now.month &&
                  u.createdAt.day == now.day,
            )
            .toList();
        break;
      case TimeFilter.weekly:
        final weekAgo = now.subtract(const Duration(days: 7));
        result = result.where((u) => u.createdAt.isAfter(weekAgo)).toList();
        break;
      case TimeFilter.monthly:
        final monthAgo = now.subtract(const Duration(days: 30));
        result = result.where((u) => u.createdAt.isAfter(monthAgo)).toList();
        break;
      case TimeFilter.all:
        break;
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'blockUser',
        error: e,
        stackTrace: stackTrace,
      );
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'activateUser',
        error: e,
        stackTrace: stackTrace,
      );
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'toggleBlockUser',
        error: e,
        stackTrace: stackTrace,
      );
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'verifyKyc',
        error: e,
        stackTrace: stackTrace,
      );
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'rejectKyc',
        error: e,
        stackTrace: stackTrace,
      );
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

  /// Add balance to user wallet — MUST use RPC only (atomic)
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'addBalance',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في إضافة الرصيد',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Deduct balance from user wallet — MUST use RPC only (atomic)
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'deductBalance',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في خصم الرصيد',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Add user from named parameters (matches UI call site)
  /// Uses adminClient (service role key) to create users without affecting
  /// the current admin session. Falls back to signUp if no service role key.
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
      // Generate email if not provided
      final userEmail = email.isNotEmpty
          ? email
          : '${phone.replaceAll(RegExp(r'[^0-9]'), '')}@kasby.app';

      final tempPassword = 'Kasby@${DateTime.now().millisecondsSinceEpoch}';

      String? userId;

      if (SupabaseService.hasAdminClient) {
        // ═══ Preferred: Use admin client (service role key) ═══
        // This does NOT affect the current admin session
        final response = await SupabaseService.adminClient.auth.admin
            .createUser(
              AdminUserAttributes(
                email: userEmail,
                password: tempPassword,
                emailConfirm: true,
                userMetadata: {
                  'full_name': name,
                  'phone': phone,
                  'country_code': country,
                },
              ),
            );
        userId = response.user?.id;
      } else {
        // ═══ Fallback: Use signUp (requires session restore) ═══
        debugPrint(
          '[UserController] ⚠ No service role key — using signUp fallback',
        );
        final adminRefreshToken =
            SupabaseService.auth.currentSession?.refreshToken;

        final response = await SupabaseService.auth.signUp(
          email: userEmail,
          password: tempPassword,
          data: {'full_name': name, 'phone': phone, 'country_code': country},
        );
        userId = response.user?.id;

        // Restore admin session
        if (adminRefreshToken != null) {
          await SupabaseService.auth.setSession(adminRefreshToken);
        }
      }

      if (userId == null) {
        throw Exception('فشل إنشاء حساب المستخدم');
      }

      // Update profile with extra fields not handled by trigger
      await SupabaseService.client
          .from('profiles')
          .update({
            'city': city,
            'whatsapp': whatsapp.isNotEmpty ? whatsapp : null,
            'telegram': telegram.isNotEmpty ? telegram : null,
            'status': 'active',
            'kyc_status': 'unverified',
            'account_tier': 'free',
          })
          .eq('id', userId);

      await loadUsers();
      Get.snackbar(
        'تم',
        'تم إضافة المستخدم بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'addUser',
        error: e,
        stackTrace: stackTrace,
      );

      String errorMsg = 'فشل في إضافة المستخدم';
      final errStr = e.toString();
      if (errStr.contains('already been registered') ||
          errStr.contains('already exists')) {
        errorMsg = 'هذا البريد الإلكتروني أو رقم الهاتف مسجل بالفعل';
      } else if (errStr.contains('Database error')) {
        errorMsg =
            'خطأ في قاعدة البيانات — تأكد من عدم تكرار رقم الهاتف أو البريد';
      } else if (!SupabaseService.hasAdminClient) {
        errorMsg =
            'يرجى تشغيل التطبيق مع --dart-define=SUPABASE_SERVICE_ROLE_KEY=...';
      }
      Get.snackbar('خطأ', errorMsg, snackPosition: SnackPosition.BOTTOM);
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'updateUser',
        error: e,
        stackTrace: stackTrace,
      );
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'UserController',
        method: 'deleteUser',
        error: e,
        stackTrace: stackTrace,
      );
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
