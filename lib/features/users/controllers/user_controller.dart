import 'dart:async';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/admin_proxy_service.dart';
import '../../../core/models/time_filter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/profile_repository.dart';
import '../../investments/models/investment_model.dart';
import '../../transactions/models/transaction_model.dart';
import '../models/user_activity_model.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/permission_service.dart';
import '../services/user_management_service.dart';
import '../../notifications/controllers/notification_controller.dart';

/// User Controller — manages user data from Supabase `profiles` + `wallets`
class UserController extends GetxController {
  final ProfileRepository _profileRepo = ProfileRepository(
    SupabaseService.client,
  );

  final users = <User>[].obs;
  final filteredUsers = <User>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'all'.obs;
  final selectedKyc = 'all'.obs;
  final selectedTimeFilter = TimeFilter.all.obs;
  final selectedCountry = ''.obs;
  final selectedAccountType = ''.obs;

  // Extra User Details (for details screen)
  final selectedUserInvestments = <UserInvestment>[].obs;
  final selectedUserTransactions = <Transaction>[].obs;
  final selectedUserActivities = <UserActivity>[].obs;
  final isDetailsLoading = false.obs;
  Worker? _authWorker;
  StreamSubscription? _profilesSubscription;
  Timer? _reloadDebounce;
  bool _hasMoreUsers = true;
  bool _isLoadingMore = false;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'UserController',
      method: 'onInit',
      feature: 'Users',
      status: 'INFO',
    );
    super.onInit();
    try {
      final auth = Get.find<AuthController>();
      _authWorker = ever(auth.isLoggedIn, (loggedIn) {
        if (loggedIn) {
          loadUsers();
          _listenToProfiles();
        } else {
          _stopListening();
          users.clear();
          filteredUsers.clear();
        }
      });
      if (auth.isLoggedIn.value) {
        loadUsers();
        _listenToProfiles();
      }
    } catch (_) {
      loadUsers();
      _listenToProfiles();
    }
  }

  void _listenToProfiles() {
    _profilesSubscription?.cancel();
    _profilesSubscription = SupabaseService.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .listen((_) {
          _reloadDebounce?.cancel();
          _reloadDebounce = Timer(const Duration(milliseconds: 750), loadUsers);
        }, onError: (_) {});
  }

  void _stopListening() {
    _reloadDebounce?.cancel();
    _profilesSubscription?.cancel();
    _profilesSubscription = null;
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'UserController',
      method: 'onClose',
      feature: 'Users',
      status: 'INFO',
    );
    _stopListening();
    _authWorker?.dispose();
    super.onClose();
  }

  /// Load users from Supabase with pagination
  Future<void> loadUsers() async {
    AppLoggerService.debugTrace(
      className: 'UserController',
      method: 'loadUsers',
      feature: 'Users',
      status: 'INFO',
    );
    isLoading.value = true;
    _hasMoreUsers = true;
    try {
      final response = await _profileRepo.getProfilesPaginated(
        from: 0,
        to: 49,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        status: selectedStatus.value.toLowerCase() == 'all'
            ? null
            : selectedStatus.value.toLowerCase(),
        kycStatus: selectedKyc.value,
        country: selectedCountry.value.isNotEmpty ? selectedCountry.value : null,
        excludeAdmins: true,
      );
      users.value = response;
      _applyFilters();
      AppLoggerService.debugTrace(
        className: 'UserController',
        method: 'loadUsers',
        feature: 'Users',
        status: 'SUCCESS',
        params: {'count': users.length},
      );
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'UserController',
        method: 'loadUsers',
        feature: 'Users',
        status: 'FAILED',
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

  /// Load more users for pagination
  Future<void> loadMoreUsers() async {
    if (isLoading.value || _isLoadingMore || !_hasMoreUsers) return;

    _isLoadingMore = true;
    AppLoggerService.debugTrace(
      className: 'UserController',
      method: 'loadMoreUsers',
      feature: 'Users',
      status: 'INFO',
    );
    try {
      final nextFrom = users.length;
      final nextTo = nextFrom + 49;

      final response = await _profileRepo.getProfilesPaginated(
        from: nextFrom,
        to: nextTo,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        status: selectedStatus.value.toLowerCase() == 'all'
            ? null
            : selectedStatus.value.toLowerCase(),
        kycStatus: selectedKyc.value,
        country: selectedCountry.value.isNotEmpty ? selectedCountry.value : null,
        excludeAdmins: true,
      );

      if (response.isNotEmpty) {
        users.addAll(response);
        _applyFilters();
        if (response.length < 50) {
          _hasMoreUsers = false;
        }
        AppLoggerService.debugTrace(
          className: 'UserController',
          method: 'loadMoreUsers',
          feature: 'Users',
          status: 'SUCCESS',
          params: {'count': response.length},
        );
      } else {
        _hasMoreUsers = false;
        AppLoggerService.debugTrace(
          className: 'UserController',
          method: 'loadMoreUsers',
          feature: 'Users',
          status: 'INFO',
          message: 'No more users to load',
        );
      }
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'UserController',
        method: 'loadMoreUsers',
        feature: 'Users',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoadingMore = false;
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

  /// Block user with mandatory reason (RPC + audit + notification via DB trigger)
  Future<void> blockUser(String userId, {String? reason}) async {
    final permService = Get.find<PermissionService>();
    if (!permService.canManageUsers) {
      Get.snackbar('صلاحيات غير كافية', 'لا تملك صلاحية حظر المستخدمين',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final blockReason = reason?.trim();
    if (blockReason == null || blockReason.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يجب إدخال سبب الحظر',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await UserManagementService.blockUser(userId, blockReason);

      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(
          status: 'blocked',
          statusReason: blockReason,
          statusChangedAt: DateTime.now(),
        );
        _applyFilters();
      }

      await AppLoggerService.logActivity(
        action: 'admin_block_user',
        entityType: 'user',
        entityId: userId,
        details: {'reason': blockReason},
      );

      Get.snackbar(
        'تم',
        'تم حظر المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حظر المستخدم: ${e.toString().replaceFirst('Exception: ', '')}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Activate / unblock user
  Future<void> activateUser(String userId) async {
    try {
      await UserManagementService.unblockUser(userId);

      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(
          status: 'active',
          statusReason: '',
          statusChangedAt: DateTime.now(),
        );
        _applyFilters();
      }

      await AppLoggerService.logActivity(
        action: 'admin_unblock_user',
        entityType: 'user',
        entityId: userId,
      );

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
      if (user.status.toLowerCase() == 'blocked') {
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
      await SupabaseService.client.rpc(
        'fn_admin_set_kyc_status',
        params: {'p_user_id': userId, 'p_status': 'verified'},
      );

      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(kycStatus: 'verified');
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
  Future<void> rejectKyc(String userId, [String reason = '']) async {
    try {
      await SupabaseService.client.rpc(
        'fn_admin_set_kyc_status',
        params: {
          'p_user_id': userId,
          'p_status': 'rejected',
          'p_reason': reason.isNotEmpty ? reason : null,
        },
      );

      final idx = users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        users[idx] = users[idx].copyWith(kycStatus: 'rejected');
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
      rejectKyc(userId, reason);

  /// Add balance to user wallet — MUST use RPC only (atomic)
  Future<void> addBalance(
    String userId,
    double amount, [
    String reason = '',
  ]) async {
    final permService = Get.find<PermissionService>();
    if (!permService.canAdjustBalance) {
      Get.snackbar('صلاحيات غير كافية', 'لا تملك صلاحية تعديل الأرصدة',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      await AdminProxyService.addBalance(userId, amount);

      // Send User Notification
      Get.find<NotificationController>().sendNotification(
        '⚖️ تحديث رصيد',
        'قام النظام بتحديث رصيد محفظتك بمبلغ $amount. تفقد سجل المعاملات للتفاصيل.',
        'specific',
        specificUserId: userId,
      );

      await loadUsers();
      Get.snackbar(
        'تم',
        'تم إضافة الرصيد بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      String msg = 'فشل في إضافة الرصيد';
      final err = e.toString();
      if (err.contains('Insufficient balance')) {
        msg = 'الرصيد غير كافٍ في المحفظة';
      } else if (err.contains('23514')) {
        msg = 'خطأ في قيود البيانات — يرجى مراجعة حالة المعاملة';
      } else if (err.isNotEmpty && err != 'Exception') {
        msg = err.replaceFirst('Exception: ', '');
      }
      Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Deduct balance from user wallet — MUST use RPC only (atomic)
  Future<void> deductBalance(
    String userId,
    double amount, [
    String reason = '',
  ]) async {
    final permService = Get.find<PermissionService>();
    if (!permService.canAdjustBalance) {
      Get.snackbar('صلاحيات غير كافية', 'لا تملك صلاحية تعديل الأرصدة',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      await AdminProxyService.deductBalance(userId, amount);

      // Send User Notification
      Get.find<NotificationController>().sendNotification(
        '⚖️ تحديث رصيد',
        'قام النظام بخصم مبلغ $amount من محفظتك. تفقد سجل المعاملات للتفاصيل.',
        'specific',
        specificUserId: userId,
      );

      await loadUsers();
      Get.snackbar(
        'تم',
        'تم خصم الرصيد بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      String msg = 'فشل في خصم الرصيد';
      final err = e.toString();
      if (err.contains('Insufficient balance')) {
        msg = 'الرصيد غير كافٍ في المحفظة';
      } else if (err.contains('23514')) {
        msg = 'خطأ في قيود البيانات — يرجى مراجعة البيانات';
      } else if (err.isNotEmpty && err != 'Exception') {
        msg = err.replaceFirst('Exception: ', '');
      }
      Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Add user from named parameters (matches UI call site).
  /// Uses the admin-proxy Edge Function for user creation, which
  /// keeps the service role key server-side only.
  Future<void> addUser({
    required String name,
    required String country,
    required String city,
    required String phone,
    String whatsapp = '',
    String telegram = '',
    String email = '',
    String avatarUrl = '',
  }) async {
    try {
      // Generate email if not provided
      final userEmail = email.isNotEmpty
          ? email
          : '${phone.replaceAll(RegExp(r'[^0-9]'), '')}@kasby.app';

      final tempPassword = 'Kasby@${DateTime.now().millisecondsSinceEpoch}';

      // Create user via admin-proxy Edge Function (service role stays server-side)
      final userId = await AdminProxyService.createUser(
        email: userEmail,
        password: tempPassword,
        userMetadata: {
          'full_name': name,
          'phone': phone,
          'country_code': country,
          'city': city,
          if (whatsapp.isNotEmpty) 'whatsapp': whatsapp,
          if (telegram.isNotEmpty) 'telegram': telegram,
          if (avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
        },
      );

      if (userId == null) {
        throw Exception('فشل إنشاء حساب المستخدم');
      }

      await loadUsers();
      Get.snackbar(
        'تم',
        'تم إضافة المستخدم بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      String errorMsg = 'فشل في إضافة المستخدم';
      final errStr = e.toString();
      if (errStr.contains('already been registered') ||
          errStr.contains('already exists')) {
        errorMsg = 'هذا البريد الإلكتروني أو رقم الهاتف مسجل بالفعل';
      } else if (errStr.contains('Database error')) {
        errorMsg =
            'خطأ في قاعدة البيانات — تأكد من عدم تكرار رقم الهاتف أو البريد';
      }
      Get.snackbar('خطأ', errorMsg, snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Hard-delete a user and all related data via the admin-proxy Edge Function.
  /// The backend calls fn_admin_purge_user_data (RPC) followed by
  /// auth.admin.deleteUser — both execute in a single transactional flow.
  Future<bool> deleteUser(String userId) async {
    final permService = Get.find<PermissionService>();
    if (!permService.canDeleteUsers) {
      Get.snackbar('صلاحيات غير كافية', 'لا تملك صلاحية حذف المستخدمين',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    try {
      await AdminProxyService.deleteUser(userId);

      await AppLoggerService.logActivity(
        action: 'admin_delete_user',
        entityType: 'user',
        entityId: userId,
      );

      users.removeWhere((u) => u.id == userId);
      _applyFilters();

      Get.snackbar(
        'تم',
        'تم حذف المستخدم بالكامل',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      final err = e.toString();
      String msg = err.replaceFirst('Exception: ', '');
      if (msg.length > 120) msg = msg.substring(0, 120);
      Get.snackbar(
        'خطأ',
        'فشل في حذف المستخدم: $msg',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
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

  /// Load extra details for a specific user (Investments, Transactions, Activities)
  Future<void> loadUserExtraDetails(String userId) async {
    AppLoggerService.debugTrace(
      className: 'UserController',
      method: 'loadUserExtraDetails',
      feature: 'Users',
      status: 'INFO',
      params: {'userId': userId},
    );
    isDetailsLoading.value = true;

    selectedUserInvestments.clear();
    selectedUserTransactions.clear();
    selectedUserActivities.clear();

    try {
      final results = await Future.wait([
        _profileRepo.getUserInvestments(userId),
        _profileRepo.getUserTransactions(userId),
        _profileRepo.getUserActivities(userId),
      ]);

      selectedUserInvestments.value = results[0] as List<UserInvestment>;
      selectedUserTransactions.value = results[1] as List<Transaction>;
      selectedUserActivities.value = results[2] as List<UserActivity>;

      AppLoggerService.debugTrace(
        className: 'UserController',
        method: 'loadUserExtraDetails',
        feature: 'Users',
        status: 'SUCCESS',
        params: {
          'investments': selectedUserInvestments.length,
          'transactions': selectedUserTransactions.length,
          'activities': selectedUserActivities.length,
        },
      );
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'UserController',
        method: 'loadUserExtraDetails',
        feature: 'Users',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      isDetailsLoading.value = false;
    }
  }
}
