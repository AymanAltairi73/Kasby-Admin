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

  // Analytics
  final selectedRange = 'all'.obs;
  final customStart = Rxn<DateTime>();
  final customEnd = Rxn<DateTime>();
  final dailyReferrals = <Map<String, dynamic>>[].obs;
  final conversionRate = 0.0.obs;
  final totalUsersWithCode = 0.obs;

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
          .select('referred_by_id, created_at')
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

      // Analytics computations
      totalUsersWithCode.value = (profiles as List).length;
      final totalReferred = (referred as List).length;
      conversionRate.value = totalUsersWithCode.value > 0
          ? (activeReferrers / totalUsersWithCode.value) * 100
          : 0;

      // Build daily referrals trend from referred profiles
      _buildDailyReferralsTrend(referred as List);

      AppLoggerService.debugTrace(
        className: 'ReferralController',
        method: 'loadReferrals',
        feature: 'Referrals',
        status: 'SUCCESS',
        params: {'count': entries.length, 'totalReferred': totalReferred},
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

  void _buildDailyReferralsTrend(List<dynamic> referredProfiles) {
    final now = DateTime.now();
    final daysBack = _analyticsRangeDays;
    final cutoff = now.subtract(Duration(days: daysBack));

    final dayMap = <String, int>{};

    for (final row in referredProfiles) {
      final createdStr = row['created_at'] as String?;
      if (createdStr == null) continue;
      try {
        final dt = DateTime.parse(createdStr);
        if (dt.isBefore(cutoff)) continue;
        final key = createdStr.substring(0, 10);
        dayMap[key] = (dayMap[key] ?? 0) + 1;
      } catch (_) {
        continue;
      }
    }

    final sorted = dayMap.keys.toList()..sort();
    dailyReferrals.assignAll(
      sorted.map((d) => {'date': d, 'count': dayMap[d] ?? 0}),
    );
  }

  int get _analyticsRangeDays {
    switch (selectedRange.value) {
      case 'last_7':
        return 7;
      case 'last_30':
        return 30;
      case 'last_90':
        return 90;
      default:
        return 365;
    }
  }

  void changeAnalyticsRange(String range) {
    selectedRange.value = range;
    loadReferrals();
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

  List<ReferralEntry> get topReferrersByCount {
    final sorted = List<ReferralEntry>.from(entries);
    sorted.sort((a, b) => b.referralCount.compareTo(a.referralCount));
    return sorted.take(10).where((e) => e.referralCount > 0).toList();
  }

  List<ReferralEntry> get topReferrersByEarnings {
    final sorted = List<ReferralEntry>.from(entries);
    sorted.sort((a, b) => b.totalCommissions.compareTo(a.totalCommissions));
    return sorted.take(10).where((e) => e.totalCommissions > 0).toList();
  }

  int get totalReferrals =>
      entries.fold(0, (sum, e) => sum + e.referralCount);

  double get totalCommissions =>
      entries.fold(0, (sum, e) => sum + e.totalCommissions);

  int get activeReferrers =>
      entries.where((e) => e.referralCount > 0).length;

  void updateSearch(String query) => searchQuery.value = query;
}
