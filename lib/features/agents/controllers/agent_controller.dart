import 'package:get/get.dart';
import '../models/agent_model.dart';

/// Agent Controller
/// Manages agents (proxies) and their performance
class AgentController extends GetxController {
  final agents = <Agent>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    loadAgents();
  }

  /// Load agents
  Future<void> loadAgents() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    agents.value = Agent.getMockAgents();
    isLoading.value = false;
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

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((agent) {
        return agent.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            agent.country.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            agent.email.toLowerCase().contains(searchQuery.value.toLowerCase());
      }).toList();
    }

    // Filter by status
    if (selectedStatus.value != 'All') {
      filtered = filtered.where((agent) => agent.status == selectedStatus.value).toList();
    }

    return filtered;
  }

  /// Create new agent
  Future<void> createAgent({
    required String name,
    required String country,
    required String phone,
    required String email,
  }) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    Get.snackbar(
      'نجح',
      'تم إضافة الوكيل بنجاح',
      snackPosition: SnackPosition.BOTTOM,
    );

    isLoading.value = false;
    loadAgents();
  }

  /// Update agent
  Future<void> updateAgent(String agentId, Map<String, dynamic> updates) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    Get.snackbar(
      'نجح',
      'تم تحديث بيانات الوكيل',
      snackPosition: SnackPosition.BOTTOM,
    );

    isLoading.value = false;
    loadAgents();
  }

  /// Toggle agent status
  Future<void> toggleAgentStatus(String agentId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    Get.snackbar(
      'نجح',
      'تم تحديث حالة الوكيل',
      snackPosition: SnackPosition.BOTTOM,
    );

    isLoading.value = false;
    loadAgents();
  }

  /// Delete agent
  Future<void> deleteAgent(String agentId) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    Get.snackbar(
      'نجح',
      'تم حذف الوكيل',
      snackPosition: SnackPosition.BOTTOM,
    );

    isLoading.value = false;
    loadAgents();
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
