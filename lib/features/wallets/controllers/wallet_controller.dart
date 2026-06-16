import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

class WalletEntry {
  final String userId;
  final String userName;
  final String email;
  final double available;
  final double invested;
  final double profit;
  final double pending;

  WalletEntry({
    required this.userId,
    required this.userName,
    required this.email,
    required this.available,
    required this.invested,
    required this.profit,
    required this.pending,
  });

  double get totalBalance => available + invested + profit + pending;

  factory WalletEntry.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map? ?? {};
    return WalletEntry(
      userId: json['user_id'] ?? '',
      userName: profile['full_name'] ?? '',
      email: profile['email'] ?? '',
      available: (json['available_balance'] as num? ?? 0).toDouble(),
      invested: (json['invested_balance'] as num? ?? 0).toDouble(),
      profit: (json['profit_balance'] as num? ?? 0).toDouble(),
      pending: (json['pending_balance'] as num? ?? 0).toDouble(),
    );
  }
}

class WalletController extends GetxController {
  final wallets = <WalletEntry>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'WalletController',
      method: 'onInit',
      feature: 'Wallets',
      status: 'INFO',
    );
    super.onInit();
    loadWallets();
  }

  Future<void> loadWallets() async {
    AppLoggerService.debugTrace(
      className: 'WalletController',
      method: 'loadWallets',
      feature: 'Wallets',
      status: 'INFO',
    );
    isLoading.value = true;
    hasError.value = false;
    try {
      final response = await SupabaseService.client
          .from('wallets')
          .select(
            'user_id, available_balance, invested_balance, profit_balance, pending_balance, updated_at, profiles!wallets_user_id_fkey(full_name, email, role)',
          )
          .eq('currency', 'USD')
          .order('updated_at', ascending: false)
          .limit(300);

      wallets.assignAll(
        (response as List)
            .where((w) {
              final profile = w['profiles'] as Map?;
              return profile?['role'] != 'admin';
            })
            .map((w) => WalletEntry.fromJson(Map<String, dynamic>.from(w)))
            .toList(),
      );

      AppLoggerService.debugTrace(
        className: 'WalletController',
        method: 'loadWallets',
        feature: 'Wallets',
        status: 'SUCCESS',
        params: {'count': wallets.length},
      );
    } catch (e, stackTrace) {
      hasError.value = true;
      AppLoggerService.logError(
        controller: 'WalletController',
        method: 'loadWallets',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل تحميل المحافظ');
    } finally {
      isLoading.value = false;
    }
  }

  List<WalletEntry> get filteredWallets {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return wallets;
    return wallets
        .where(
          (w) =>
              w.userName.toLowerCase().contains(q) ||
              w.email.toLowerCase().contains(q),
        )
        .toList();
  }

  double get totalAvailable =>
      wallets.fold(0, (sum, w) => sum + w.available);

  double get totalInvested =>
      wallets.fold(0, (sum, w) => sum + w.invested);

  double get totalProfit =>
      wallets.fold(0, (sum, w) => sum + w.profit);

  double get totalPending =>
      wallets.fold(0, (sum, w) => sum + w.pending);

  void updateSearch(String query) => searchQuery.value = query;
}
