import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';

enum SearchCategory { all, users, transactions, investments, agents, loans }

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchCategory type;
  final Map<String, dynamic>? extra;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.extra,
  });
}

class AdminSearchController extends GetxController {
  static const _recentKey = 'admin_recent_searches';
  static const _maxRecent = 10;

  final query = ''.obs;
  final results = <SearchResult>[].obs;
  final isLoading = false.obs;
  final selectedCategory = SearchCategory.all.obs;
  final recentSearches = <String>[].obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      results.clear();
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _debounce = Timer(const Duration(milliseconds: 300), _executeSearch);
  }

  void setCategory(SearchCategory category) {
    selectedCategory.value = category;
    if (query.value.trim().isNotEmpty) {
      isLoading.value = true;
      _executeSearch();
    }
  }

  Future<void> _executeSearch() async {
    final q = query.value.trim();
    if (q.isEmpty) {
      results.clear();
      isLoading.value = false;
      return;
    }

    AppLoggerService.debugTrace(
      className: 'AdminSearchController',
      method: '_executeSearch',
      feature: 'Search',
      status: 'INFO',
      params: {'query': q, 'category': selectedCategory.value.name},
    );

    try {
      final allResults = <SearchResult>[];
      final cat = selectedCategory.value;

      final futures = <Future<List<SearchResult>>>[];

      if (cat == SearchCategory.all || cat == SearchCategory.users) {
        futures.add(_searchUsers(q));
      }
      if (cat == SearchCategory.all || cat == SearchCategory.transactions) {
        futures.add(_searchTransactions(q));
      }
      if (cat == SearchCategory.all || cat == SearchCategory.investments) {
        futures.add(_searchInvestments(q));
      }
      if (cat == SearchCategory.all || cat == SearchCategory.agents) {
        futures.add(_searchAgents(q));
      }
      if (cat == SearchCategory.all || cat == SearchCategory.loans) {
        futures.add(_searchLoans(q));
      }

      final batched = await Future.wait(futures);
      for (final batch in batched) {
        allResults.addAll(batch);
      }

      results.value = allResults;

      AppLoggerService.debugTrace(
        className: 'AdminSearchController',
        method: '_executeSearch',
        feature: 'Search',
        status: 'SUCCESS',
        params: {'resultCount': allResults.length},
      );
    } catch (e, st) {
      AppLoggerService.debugTrace(
        className: 'AdminSearchController',
        method: '_executeSearch',
        feature: 'Search',
        status: 'FAILED',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<SearchResult>> _searchUsers(String q) async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, email, phone')
          .or('full_name.ilike.%$q%,email.ilike.%$q%,phone.ilike.%$q%')
          .limit(10);

      return (response as List).map((row) {
        return SearchResult(
          id: row['id'] ?? '',
          title: row['full_name'] ?? 'بدون اسم',
          subtitle: row['email'] ?? row['phone'] ?? '',
          type: SearchCategory.users,
          extra: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchResult>> _searchTransactions(String q) async {
    try {
      final response = await SupabaseService.client
          .from('transactions')
          .select('id, type, amount, status, reference, created_at')
          .or('id.ilike.%$q%,reference.ilike.%$q%')
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List).map((row) {
        final type = row['type'] ?? '';
        final amount = row['amount'] ?? 0;
        return SearchResult(
          id: row['id'] ?? '',
          title: '$type — \$$amount',
          subtitle: 'المرجع: ${row['reference'] ?? row['id'] ?? ''}',
          type: SearchCategory.transactions,
          extra: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchResult>> _searchInvestments(String q) async {
    try {
      final response = await SupabaseService.client
          .from('investment_plans')
          .select('id, name, min_amount, max_amount, profit_percentage')
          .ilike('name', '%$q%')
          .limit(10);

      return (response as List).map((row) {
        return SearchResult(
          id: row['id'] ?? '',
          title: row['name'] ?? '',
          subtitle: 'عائد ${row['profit_percentage'] ?? 0}%',
          type: SearchCategory.investments,
          extra: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchResult>> _searchAgents(String q) async {
    try {
      final response = await SupabaseService.client
          .from('agents')
          .select('id, name, phone, status')
          .or('name.ilike.%$q%,phone.ilike.%$q%')
          .limit(10);

      return (response as List).map((row) {
        return SearchResult(
          id: row['id'] ?? '',
          title: row['name'] ?? 'بدون اسم',
          subtitle: row['phone'] ?? '',
          type: SearchCategory.agents,
          extra: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchResult>> _searchLoans(String q) async {
    try {
      final response = await SupabaseService.client
          .from('loans')
          .select('id, amount, status, user_id, created_at')
          .or('id.ilike.%$q%,status.ilike.%$q%')
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List).map((row) {
        final amount = row['amount'] ?? 0;
        return SearchResult(
          id: row['id'] ?? '',
          title: 'سلفة — \$$amount',
          subtitle: 'الحالة: ${row['status'] ?? ''}',
          type: SearchCategory.loans,
          extra: row,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Recent searches
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      recentSearches.value = prefs.getStringList(_recentKey) ?? [];
    } catch (_) {}
  }

  Future<void> addToRecent(String term) async {
    if (term.trim().isEmpty) return;
    recentSearches.remove(term);
    recentSearches.insert(0, term);
    if (recentSearches.length > _maxRecent) {
      recentSearches.removeRange(_maxRecent, recentSearches.length);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentKey, recentSearches);
    } catch (_) {}
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
    } catch (_) {}
  }
}
