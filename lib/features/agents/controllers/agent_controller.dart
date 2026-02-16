import 'package:get/get.dart';
import '../models/agent_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/time_filter.dart';

/// Agent Controller — manages agent data from Supabase `agents` table
class AgentController extends GetxController {
  final agents = <Agent>[].obs;
  final filteredAgents = <Agent>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'all'.obs;
  final selectedTimeFilter = TimeFilter.all.obs;

  /// Active agents getter
  List<Agent> get activeAgents =>
      agents.where((a) => a.status == 'Active').toList();

  @override
  void onInit() {
    super.onInit();
    loadAgents();
  }

  /// Load agents from Supabase
  Future<void> loadAgents() async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('agents')
          .select()
          .order('created_at', ascending: false);

      agents.value = (response as List)
          .map((json) => Agent.fromSupabase(json))
          .toList();
      _applyFilters();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل الوكلاء: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Search agents
  void searchAgents(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  /// Filter by status
  void filterByStatus(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  void _applyFilters() {
    List<Agent> result = List.from(agents);

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where(
            (a) =>
                a.name.toLowerCase().contains(q) ||
                a.email.toLowerCase().contains(q) ||
                a.phone.contains(q) ||
                a.country.toLowerCase().contains(q) ||
                a.city.toLowerCase().contains(q),
          )
          .toList();
    }

    if (selectedStatus.value != 'all') {
      result = result
          .where(
            (a) => a.status.toLowerCase() == selectedStatus.value.toLowerCase(),
          )
          .toList();
    }

    // Apply time filter
    final now = DateTime.now();
    switch (selectedTimeFilter.value) {
      case TimeFilter.daily:
        result = result
            .where(
              (a) =>
                  a.createdAt.year == now.year &&
                  a.createdAt.month == now.month &&
                  a.createdAt.day == now.day,
            )
            .toList();
        break;
      case TimeFilter.weekly:
        final weekAgo = now.subtract(const Duration(days: 7));
        result = result.where((a) => a.createdAt.isAfter(weekAgo)).toList();
        break;
      case TimeFilter.monthly:
        final monthAgo = now.subtract(const Duration(days: 30));
        result = result.where((a) => a.createdAt.isAfter(monthAgo)).toList();
        break;
      case TimeFilter.all:
        break;
    }

    filteredAgents.value = result;
  }

  /// Create new agent from named parameters (matches UI call site)
  Future<void> createAgent({
    required String name,
    required String country,
    String province = '',
    required String city,
    String address = '',
    required String phone,
    String whatsapp = '',
    String telegram = '',
    String email = '',
    String notes = '',
  }) async {
    try {
      isLoading.value = true;
      final agent = Agent(
        id: '',
        name: name,
        country: country,
        province: province,
        city: city,
        address: address,
        phone: phone,
        whatsapp: whatsapp,
        telegram: telegram,
        email: email,
        notes: notes,
        status: 'Active',
        isAvailableNow: true,
        successRate: 0.0,
        totalTransactions: 0,
        supportedMethods: [
          if (whatsapp.isNotEmpty) 'WhatsApp',
          if (telegram.isNotEmpty) 'Telegram',
          'Call',
        ],
        createdAt: DateTime.now(),
      );

      await SupabaseService.client.from('agents').insert(agent.toSupabase());

      await loadAgents();
      Get.snackbar(
        'تم',
        'تم إنشاء الوكيل بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في إنشاء الوكيل: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update agent by ID and a map of fields (matches UI call site)
  Future<void> updateAgent(String agentId, Map<String, dynamic> data) async {
    try {
      await SupabaseService.client
          .from('agents')
          .update(data)
          .eq('id', agentId);

      await loadAgents();

      Get.snackbar(
        'تم',
        'تم تحديث بيانات الوكيل',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث بيانات الوكيل',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Delete agent
  Future<void> deleteAgent(String agentId) async {
    try {
      await SupabaseService.client.from('agents').delete().eq('id', agentId);

      agents.removeWhere((a) => a.id == agentId);
      _applyFilters();

      Get.snackbar('تم', 'تم حذف الوكيل', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حذف الوكيل: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle availability
  Future<void> toggleAvailability(String agentId) async {
    try {
      final agent = agents.firstWhere((a) => a.id == agentId);
      final newVal = !agent.isAvailableNow;

      await SupabaseService.client
          .from('agents')
          .update({'is_available_now': newVal})
          .eq('id', agentId);

      final idx = agents.indexWhere((a) => a.id == agentId);
      if (idx != -1) {
        agents[idx] = agents[idx].copyWith(isAvailableNow: newVal);
        _applyFilters();
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث الحالة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle agent status (Active/Inactive) — aliased as toggleAgentStatus for UI compat
  Future<void> toggleStatus(String agentId) async {
    try {
      final agent = agents.firstWhere((a) => a.id == agentId);
      final newStatus = agent.status == 'Active' ? 'Inactive' : 'Active';

      await SupabaseService.client
          .from('agents')
          .update({'status': newStatus})
          .eq('id', agentId);

      final idx = agents.indexWhere((a) => a.id == agentId);
      if (idx != -1) {
        agents[idx] = agents[idx].copyWith(status: newStatus);
        _applyFilters();
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث الحالة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Alias used by UI
  Future<void> toggleAgentStatus(String agentId) => toggleStatus(agentId);

  /// Get agent by ID
  Agent? getAgentById(String agentId) {
    try {
      return agents.firstWhere((a) => a.id == agentId);
    } catch (e) {
      return null;
    }
  }
}
