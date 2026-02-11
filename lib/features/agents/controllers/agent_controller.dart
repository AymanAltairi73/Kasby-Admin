import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent_model.dart';
import '../../../core/models/time_filter.dart';

/// Agent Controller
/// Manages agents (proxies) and their performance
class AgentController extends GetxController {
  final agents = <Agent>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;
  final selectedTimeFilter = TimeFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    loadAgents();
  }

  /// Load agents
  Future<void> loadAgents() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    final agentsData = prefs.getString('agents');

    if (agentsData != null) {
      final List decoded = jsonDecode(agentsData);
      agents.assignAll(decoded.map((e) => Agent.fromJson(e)).toList());
    } else {
      // Fallback to mock data if no saved data
      agents.assignAll(Agent.getMockAgents());
      saveAgents(); // Initial save
    }
    isLoading.value = false;
  }

  /// Save agents to persistent storage
  Future<void> saveAgents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'agents',
      jsonEncode(agents.map((e) => e.toJson()).toList()),
    );
  }

  /// Search agents
  void searchAgents(String query) {
    searchQuery.value = query;
  }

  /// Filter by status
  void filterByStatus(String status) {
    selectedStatus.value = status;
  }

  /// Get filtered agents
  List<Agent> get filteredAgents {
    var filtered = agents.toList();

    // Filter by time
    final now = DateTime.now();
    if (selectedTimeFilter.value != TimeFilter.all) {
      filtered = filtered.where((agent) {
        final difference = now.difference(agent.createdAt);
        switch (selectedTimeFilter.value) {
          case TimeFilter.daily:
            return difference.inDays == 0 && agent.createdAt.day == now.day;
          case TimeFilter.weekly:
            return difference.inDays <= 7;
          case TimeFilter.monthly:
            return difference.inDays <= 30;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((agent) {
        return agent.name.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            agent.country.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            agent.city.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            agent.email.toLowerCase().contains(searchQuery.value.toLowerCase());
      }).toList();
    }

    // Filter by status
    if (selectedStatus.value != 'All') {
      filtered = filtered
          .where((agent) => agent.status == selectedStatus.value)
          .toList();
    }

    return filtered;
  }

  /// Create new agent
  Future<void> createAgent({
    required String name,
    required String country,
    required String province,
    required String city,
    required String address,
    required String phone,
    required String whatsapp,
    required String telegram,
    required String email,
    String notes = '',
    bool isAvailableNow = true,
    List<String> supportedMethods = const ['WhatsApp', 'Telegram', 'Call'],
  }) async {
    isLoading.value = true;

    final newAgent = Agent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      country: country,
      province: province,
      city: city,
      address: address,
      phone: phone,
      whatsapp: whatsapp,
      telegram: telegram,
      email: email,
      status: 'Active',
      isAvailableNow: isAvailableNow,
      supportedMethods: supportedMethods,
      successRate: 0.0,
      totalTransactions: 0,
      notes: notes,
      createdAt: DateTime.now(),
    );

    agents.add(newAgent);
    await saveAgents();

    Get.snackbar(
      'نجح',
      'تم إضافة الوكيل بنجاح',
      snackPosition: SnackPosition.BOTTOM,
    );

    isLoading.value = false;
  }

  /// Update agent
  Future<void> updateAgent(String agentId, Map<String, dynamic> updates) async {
    isLoading.value = true;

    final index = agents.indexWhere((a) => a.id == agentId);
    if (index != -1) {
      final old = agents[index];
      agents[index] = Agent(
        id: old.id,
        name: updates['name'] ?? old.name,
        country: updates['country'] ?? old.country,
        province: updates['province'] ?? old.province,
        city: updates['city'] ?? old.city,
        address: updates['address'] ?? old.address,
        phone: updates['phone'] ?? old.phone,
        whatsapp: updates['whatsapp'] ?? old.whatsapp,
        telegram: updates['telegram'] ?? old.telegram,
        email: updates['email'] ?? old.email,
        status: updates['status'] ?? old.status,
        isAvailableNow: updates['isAvailableNow'] ?? old.isAvailableNow,
        supportedMethods: updates['supportedMethods'] ?? old.supportedMethods,
        successRate: old.successRate,
        totalTransactions: old.totalTransactions,
        notes: updates['notes'] ?? old.notes,
        createdAt: old.createdAt,
      );

      await saveAgents();

      Get.snackbar(
        'نجح',
        'تم تحديث بيانات الوكيل',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    isLoading.value = false;
  }

  /// Toggle agent status
  Future<void> toggleAgentStatus(String agentId) async {
    isLoading.value = true;

    final index = agents.indexWhere((a) => a.id == agentId);
    if (index != -1) {
      final old = agents[index];
      final newStatus = old.status == 'Active' ? 'Inactive' : 'Active';

      agents[index] = old.copyWith(status: newStatus);

      await saveAgents();

      Get.snackbar(
        'نجح',
        'تم تحديث حالة الوكيل إلى ${newStatus == 'Active' ? 'نشط' : 'معطل'}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    isLoading.value = false;
  }

  /// Delete agent
  Future<void> deleteAgent(String agentId) async {
    isLoading.value = true;

    agents.removeWhere((a) => a.id == agentId);
    await saveAgents();

    Get.snackbar('نجح', 'تم حذف الوكيل', snackPosition: SnackPosition.BOTTOM);

    isLoading.value = false;
  }

  /// Get active agents
  List<Agent> get activeAgents {
    return agents.where((agent) => agent.status == 'Active').toList();
  }

  /// Get inactive agents
  List<Agent> get inactiveAgents {
    return agents.where((agent) => agent.status == 'Inactive').toList();
  }
}
