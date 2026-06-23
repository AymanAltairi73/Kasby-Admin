import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/services/permission_service.dart';
import '../../notifications/controllers/notification_controller.dart';

enum ApprovalCategory { all, deposits, withdrawals, kyc, loans, agents }

class ApprovalItem {
  final String id;
  final ApprovalCategory category;
  final String userName;
  final String detail;
  final double? amount;
  final DateTime createdAt;
  final Map<String, dynamic> raw;

  const ApprovalItem({
    required this.id,
    required this.category,
    required this.userName,
    required this.detail,
    this.amount,
    required this.createdAt,
    required this.raw,
  });
}

class ApprovalQueueController extends GetxController {
  final items = <ApprovalItem>[].obs;
  final filteredItems = <ApprovalItem>[].obs;
  final isLoading = false.obs;
  final selectedCategory = ApprovalCategory.all.obs;
  final categoryCounts = <ApprovalCategory, int>{}.obs;

  StreamSubscription? _txnSub;
  StreamSubscription? _kycSub;
  StreamSubscription? _loanSub;
  StreamSubscription? _agentSub;
  Timer? _reloadDebounce;

  @override
  void onInit() {
    super.onInit();
    loadAllPending();
    _startListeners();
  }

  @override
  void onClose() {
    _txnSub?.cancel();
    _kycSub?.cancel();
    _loanSub?.cancel();
    _agentSub?.cancel();
    _reloadDebounce?.cancel();
    super.onClose();
  }

  void _startListeners() {
    void scheduleReload() {
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 800), loadAllPending);
    }

    _txnSub = SupabaseService.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});

    _kycSub = SupabaseService.client
        .from('kyc_documents')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});

    _loanSub = SupabaseService.client
        .from('loans')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});

    _agentSub = SupabaseService.client
        .from('agent_applications')
        .stream(primaryKey: ['id'])
        .listen((_) => scheduleReload(), onError: (_) {});
  }

  Future<void> loadAllPending() async {
    AppLoggerService.debugTrace(
      className: 'ApprovalQueueController',
      method: 'loadAllPending',
      feature: 'Approvals',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _fetchPendingDeposits(),
        _fetchPendingWithdrawals(),
        _fetchPendingKYC(),
        _fetchPendingLoans(),
        _fetchPendingAgents(),
      ]);

      final all = <ApprovalItem>[];
      for (final batch in results) {
        all.addAll(batch);
      }
      all.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      items.value = all;
      _updateCounts();
      _applyFilter();

      AppLoggerService.debugTrace(
        className: 'ApprovalQueueController',
        method: 'loadAllPending',
        feature: 'Approvals',
        status: 'SUCCESS',
        params: {'total': all.length},
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'ApprovalQueueController',
        method: 'loadAllPending',
        feature: 'Approvals',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void setCategory(ApprovalCategory cat) {
    selectedCategory.value = cat;
    _applyFilter();
  }

  void _applyFilter() {
    if (selectedCategory.value == ApprovalCategory.all) {
      filteredItems.value = List.from(items);
    } else {
      filteredItems.value =
          items.where((i) => i.category == selectedCategory.value).toList();
    }
  }

  void _updateCounts() {
    final counts = <ApprovalCategory, int>{};
    for (final cat in ApprovalCategory.values) {
      if (cat == ApprovalCategory.all) {
        counts[cat] = items.length;
      } else {
        counts[cat] = items.where((i) => i.category == cat).length;
      }
    }
    categoryCounts.value = counts;
  }

  bool _ensureCanApprove() {
    final permService = Get.find<PermissionService>();
    if (!permService.canApproveFinancials) {
      Get.snackbar(
        'صلاحيات غير كافية',
        'لا تملك صلاحية الموافقة على الطلبات',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }

  Future<void> _syncProfileKycStatus(String userId) async {
    final docs = await SupabaseService.client
        .from('kyc_documents')
        .select('status')
        .eq('user_id', userId);

    final statuses = (docs as List).map((d) => d['status'] as String).toList();
    String profileStatus = 'pending';
    if (statuses.any((s) => s == 'rejected')) {
      profileStatus = 'rejected';
    } else if (statuses.isNotEmpty && statuses.every((s) => s == 'verified')) {
      profileStatus = 'verified';
    } else if (statuses.any((s) => s == 'pending')) {
      profileStatus = 'pending';
    }

    await SupabaseService.client
        .from('profiles')
        .update({'kyc_status': profileStatus})
        .eq('id', userId);
  }

  Future<List<ApprovalItem>> _fetchPendingDeposits() async {
    try {
      final data = await SupabaseService.client
          .from('transactions')
          .select(
            'id, user_id, amount, reference, created_at, profiles!transactions_user_id_fkey(full_name)',
          )
          .eq('type', 'deposit')
          .eq('status', 'pending')
          .order('created_at');

      return (data as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.deposits,
          userName: profile?['full_name'] ?? 'مستخدم',
          detail: 'مرجع: ${row['reference'] ?? row['id']}',
          amount: (row['amount'] as num?)?.toDouble(),
          createdAt:
              DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ApprovalItem>> _fetchPendingWithdrawals() async {
    try {
      final data = await SupabaseService.client
          .from('transactions')
          .select(
            'id, user_id, amount, reference, created_at, profiles!transactions_user_id_fkey(full_name)',
          )
          .eq('type', 'withdrawal')
          .eq('status', 'pending')
          .order('created_at');

      return (data as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.withdrawals,
          userName: profile?['full_name'] ?? 'مستخدم',
          detail: 'مرجع: ${row['reference'] ?? row['id']}',
          amount: (row['amount'] as num?)?.toDouble(),
          createdAt:
              DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ApprovalItem>> _fetchPendingKYC() async {
    try {
      final data = await SupabaseService.client
          .from('kyc_documents')
          .select(
            'id, user_id, document_type, uploaded_at, profiles!kyc_documents_user_id_fkey(full_name)',
          )
          .eq('status', 'pending')
          .order('uploaded_at');

      return (data as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.kyc,
          userName: profile?['full_name'] ?? 'مستخدم',
          detail: 'نوع: ${row['document_type'] ?? 'وثيقة'}',
          createdAt:
              DateTime.tryParse(row['uploaded_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ApprovalItem>> _fetchPendingLoans() async {
    try {
      final data = await SupabaseService.client
          .from('loans')
          .select(
            'id, user_id, amount, status, created_at, profiles!loans_user_id_fkey(full_name)',
          )
          .eq('status', 'pending')
          .order('created_at');

      return (data as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.loans,
          userName: profile?['full_name'] ?? 'مستخدم',
          detail: 'طلب سلفة',
          amount: (row['amount'] as num?)?.toDouble(),
          createdAt:
              DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ApprovalItem>> _fetchPendingAgents() async {
    try {
      final data = await SupabaseService.client
          .from('agent_applications')
          .select('id, user_id, full_name, phone, city, created_at')
          .eq('status', 'pending')
          .order('created_at');

      return (data as List).map((row) {
        return ApprovalItem(
          id: row['id'],
          category: ApprovalCategory.agents,
          userName: row['full_name'] ?? 'وكيل',
          detail: row['phone'] ?? row['city'] ?? '',
          createdAt:
              DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          raw: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> approveItem(ApprovalItem item) async {
    if (!_ensureCanApprove()) return;

    AppLoggerService.debugTrace(
      className: 'ApprovalQueueController',
      method: 'approveItem',
      feature: 'Approvals',
      status: 'INFO',
      params: {'id': item.id, 'category': item.category.name},
    );

    try {
      final adminId = SupabaseService.auth.currentUser?.id;
      final notifController = Get.find<NotificationController>();

      switch (item.category) {
        case ApprovalCategory.deposits:
          await SupabaseService.client.rpc('fn_process_deposit', params: {
            'p_txn_id': item.id,
            'p_admin_id': adminId,
          });
          await AppLoggerService.logActivity(
            action: 'admin_approve_deposit',
            entityType: 'transaction',
            entityId: item.id,
            details: {
              'user_id': item.raw['user_id'],
              'amount': item.amount,
            },
          );
          await notifController.sendNotification(
            '📥 إيداع ناجح',
            'تم تأكيد عملية الإيداع وإضافة الرصيد إلى حسابك بنجاح.',
            'specific',
            specificUserId: item.raw['user_id'] as String?,
          );
          break;

        case ApprovalCategory.withdrawals:
          await SupabaseService.client.rpc('approve_withdrawal', params: {
            'p_txn_id': item.id,
            'p_admin_id': adminId,
          });
          await AppLoggerService.logActivity(
            action: 'admin_approve_withdrawal',
            entityType: 'transaction',
            entityId: item.id,
            details: {
              'user_id': item.raw['user_id'],
              'amount': item.amount,
            },
          );
          await notifController.sendNotification(
            '📤 سحب ناجح',
            'تمت الموافقة على طلب السحب الخاص بك، المبلغ في طريقه إليك.',
            'specific',
            specificUserId: item.raw['user_id'] as String?,
          );
          break;

        case ApprovalCategory.kyc:
          final userId = item.raw['user_id'] as String;
          await SupabaseService.client.from('kyc_documents').update({
            'status': 'verified',
            'reviewed_by': adminId,
            'reviewed_at': DateTime.now().toIso8601String(),
          }).eq('id', item.id);
          await _syncProfileKycStatus(userId);
          await AppLoggerService.logActivity(
            action: 'admin_verify_kyc',
            entityType: 'kyc_document',
            entityId: item.id,
            details: {'user_id': userId},
          );
          await notifController.sendNotification(
            '✅ توثيق الحساب',
            'تم توثيق حسابك بنجاح! يمكنك الآن الاستمتاع بكافة مميزات التطبيق.',
            'specific',
            specificUserId: userId,
          );
          break;

        case ApprovalCategory.loans:
          await SupabaseService.client.rpc('fn_approve_loan', params: {
            'p_loan_id': item.id,
            'p_admin_id': adminId,
          });
          await AppLoggerService.logActivity(
            action: 'admin_approve_loan',
            entityType: 'loan',
            entityId: item.id,
            details: {
              'user_id': item.raw['user_id'],
              'amount': item.amount,
            },
          );
          await notifController.sendNotification(
            '💰 مبروك!',
            'تمت الموافقة على طلب القرض الخاص بك، تم إضافة المبلغ إلى محفظتك.',
            'specific',
            specificUserId: item.raw['user_id'] as String?,
          );
          break;

        case ApprovalCategory.agents:
          final response = await SupabaseService.client.rpc(
            'admin_approve_agent_application',
            params: {'p_application_id': item.id},
          );
          if (response is Map && response['success'] != true) {
            throw Exception(response['message'] ?? 'فشل في قبول طلب الوكالة');
          }
          await AppLoggerService.logActivity(
            action: 'admin_approve_agent',
            entityType: 'agent_application',
            entityId: item.id,
            details: {'user_id': item.raw['user_id']},
          );
          await notifController.sendNotification(
            '🌟 مبروك! انضممت للوكلاء',
            'تمت الموافقة على طلب انضمامك كوكيل رسمي. يمكنك الآن البدء في تقديم الخدمات.',
            'specific',
            specificUserId: item.raw['user_id'] as String?,
          );
          break;

        case ApprovalCategory.all:
          return;
      }

      items.remove(item);
      _updateCounts();
      _applyFilter();

      Get.snackbar('تم', 'تمت الموافقة بنجاح', snackPosition: SnackPosition.BOTTOM);
    } catch (e, st) {
      AppLoggerService.logError(
        controller: 'ApprovalQueueController',
        method: 'approveItem',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل في الموافقة', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> rejectItem(ApprovalItem item, [String reason = '']) async {
    if (!_ensureCanApprove()) return;

    final rejectReason =
        reason.isNotEmpty ? reason : 'رفض بواسطة المدير';

    AppLoggerService.debugTrace(
      className: 'ApprovalQueueController',
      method: 'rejectItem',
      feature: 'Approvals',
      status: 'INFO',
      params: {'id': item.id, 'category': item.category.name},
    );

    try {
      final adminId = SupabaseService.auth.currentUser?.id;
      final notifController = Get.find<NotificationController>();

      switch (item.category) {
        case ApprovalCategory.deposits:
        case ApprovalCategory.withdrawals:
          final fnName = item.category == ApprovalCategory.withdrawals
              ? 'reject_withdrawal'
              : 'fn_reject_transaction';
          await SupabaseService.client.rpc(fnName, params: {
            'p_txn_id': item.id,
            'p_admin_id': adminId,
            'p_reason': rejectReason,
          });
          await AppLoggerService.logActivity(
            action: 'admin_reject_transaction',
            entityType: 'transaction',
            entityId: item.id,
            details: {
              'user_id': item.raw['user_id'],
              'reason': rejectReason,
            },
          );
          await notifController.sendNotification(
            '⚠️ تنبيه مالي',
            'تم رفض المعاملة المالية. يرجى مراجعة السبب في قائمة المعاملات.',
            'specific',
            specificUserId: item.raw['user_id'] as String?,
          );
          break;

        case ApprovalCategory.kyc:
          final userId = item.raw['user_id'] as String;
          await SupabaseService.client.from('kyc_documents').update({
            'status': 'rejected',
            'reviewed_by': adminId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'rejection_reason': rejectReason,
          }).eq('id', item.id);
          await _syncProfileKycStatus(userId);
          await AppLoggerService.logActivity(
            action: 'admin_reject_kyc',
            entityType: 'kyc_document',
            entityId: item.id,
            details: {'user_id': userId, 'reason': rejectReason},
          );
          await notifController.sendNotification(
            '❌ تنبيه التوثيق',
            'نعتذر، تم رفض طلب التوثيق الخاص بك. السبب: $rejectReason',
            'specific',
            specificUserId: userId,
          );
          break;

        case ApprovalCategory.loans:
          await SupabaseService.client.rpc('fn_reject_loan', params: {
            'p_loan_id': item.id,
            'p_admin_id': adminId,
            'p_reason': rejectReason,
          });
          await AppLoggerService.logActivity(
            action: 'admin_reject_loan',
            entityType: 'loan',
            entityId: item.id,
            details: {
              'user_id': item.raw['user_id'],
              'reason': rejectReason,
            },
          );
          await notifController.sendNotification(
            '⚠️ طلب القرض',
            'لم تتم الموافقة على طلب القرض الخاص بك. السبب: $rejectReason',
            'specific',
            specificUserId: item.raw['user_id'] as String?,
          );
          break;

        case ApprovalCategory.agents:
          await SupabaseService.client
              .from('agent_applications')
              .update({'status': 'rejected'})
              .eq('id', item.id);
          await AppLoggerService.logActivity(
            action: 'admin_reject_agent',
            entityType: 'agent_application',
            entityId: item.id,
            details: {
              'user_id': item.raw['user_id'],
              'reason': rejectReason,
            },
          );
          await notifController.sendNotification(
            '⚠️ طلب الوكالة',
            'نعتذر، لم يتم قبول طلب انضمامك كوكيل في الوقت الحالي.',
            'specific',
            specificUserId: item.raw['user_id'] as String?,
          );
          break;

        case ApprovalCategory.all:
          return;
      }

      items.remove(item);
      _updateCounts();
      _applyFilter();

      Get.snackbar('تم', 'تم الرفض', snackPosition: SnackPosition.BOTTOM);
    } catch (e, st) {
      AppLoggerService.logError(
        controller: 'ApprovalQueueController',
        method: 'rejectItem',
        error: e,
        stackTrace: st,
      );
      Get.snackbar('خطأ', 'فشل في الرفض', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
