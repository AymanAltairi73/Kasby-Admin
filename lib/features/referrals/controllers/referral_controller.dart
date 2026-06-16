import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

class ReferralEntry {
  final String userId;
  final String name;
  final String email;
  final String referralCode;
  final int referralCount;
  final double totalCommissions;

  ReferralEntry({
    required this.userId,
    required this.name,
    required this.email,
    required this.referralCode,
    required this.referralCount,
    required this.totalCommissions,
  });
}

class ReferralController extends GetxController {
  final entries = <ReferralEntry>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final searchQuery = ''.obs;
  final isFromBackend = true.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'ReferralController',
      method: 'onInit',
      feature: 'Referrals',
      status: 'INFO',
    );
    super.onInit();
    loadReferrals();
  }

  Future<void> loadReferrals() async {
    AppLoggerService.debugTrace(
      className: 'ReferralController',
      method: 'loadReferrals',
      feature: 'Referrals',
      status: 'INFO',
    );
    isLoading.value = true;
    hasError.value = false;
    try {
      final profiles = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, email, referral_code, role')
          .not('referral_code', 'is', null)
          .neq('role', 'admin')
          .order('created_at', ascending: false)
          .limit(300);

      final referred = await SupabaseService.client
          .from('profiles')
          .select('referred_by_id')
          .not('referred_by_id', 'is', null);

      final counts = <String, int>{};
      for (final row in referred as List) {
        final id = row['referred_by_id'] as String?;
        if (id != null) counts[id] = (counts[id] ?? 0) + 1;
      }

      final commissions = await SupabaseService.client
          .from('transactions')
          .select('user_id, amount')
          .inFilter('type', ['referral_bonus', 'reward'])
          .eq('status', 'completed');

      final earnings = <String, double>{};
      for (final row in commissions as List) {
        final id = row['user_id'] as String?;
        if (id != null) {
          earnings[id] =
              (earnings[id] ?? 0) + (row['amount'] as num? ?? 0).toDouble();
        }
      }

      entries.assignAll(
        (profiles as List).map((p) {
          final id = p['id'] as String;
          return ReferralEntry(
            userId: id,
            name: p['full_name'] ?? '',
            email: p['email'] ?? '',
            referralCode: p['referral_code'] ?? '',
            referralCount: counts[id] ?? 0,
            totalCommissions: earnings[id] ?? 0,
          );
        }),
      );

      isFromBackend.value = true;
      AppLoggerService.debugTrace(
        className: 'ReferralController',
        method: 'loadReferrals',
        feature: 'Referrals',
        status: 'SUCCESS',
        params: {'count': entries.length},
      );
    } catch (e, stackTrace) {
      hasError.value = true;
      isFromBackend.value = false;
      AppLoggerService.logError(
        controller: 'ReferralController',
        method: 'loadReferrals',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل تحميل بيانات الإحالة');
    } finally {
      isLoading.value = false;
    }
  }

  List<ReferralEntry> get filteredEntries {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return entries;
    return entries
        .where(
          (e) =>
              e.name.toLowerCase().contains(q) ||
              e.referralCode.toLowerCase().contains(q) ||
              e.email.toLowerCase().contains(q),
        )
        .toList();
  }

  int get totalReferrals =>
      entries.fold(0, (sum, e) => sum + e.referralCount);

  double get totalCommissions =>
      entries.fold(0, (sum, e) => sum + e.totalCommissions);

  int get activeReferrers =>
      entries.where((e) => e.referralCount > 0).length;

  void updateSearch(String query) => searchQuery.value = query;
}
