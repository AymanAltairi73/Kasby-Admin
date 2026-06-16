import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import '../models/agent_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/admin_proxy_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/models/time_filter.dart';
import '../../auth/controllers/auth_controller.dart';

/// Agent Controller — manages agent data from Supabase `agents` table
class AgentController extends GetxController {
  final agents = <Agent>[].obs;
  final filteredAgents = <Agent>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'all'.obs;
  final selectedTimeFilter = TimeFilter.all.obs;

  StreamSubscription? _agentsSubscription;
  Timer? _reloadDebounce;
  Worker? _authWorker;

  /// Active agents getter
  List<Agent> get activeAgents => agents.where((a) => a.isActive).toList();

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'AgentController',
      method: 'onInit',
      feature: 'Agents',
      status: 'INFO',
    );
    super.onInit();
    try {
      final auth = Get.find<AuthController>();
      _authWorker = ever(auth.isLoggedIn, (loggedIn) {
        if (loggedIn) {
          loadAgents();
          _listenToAgents();
        } else {
          _stopListening();
          agents.clear();
          filteredAgents.clear();
        }
      });
      if (auth.isLoggedIn.value) {
        loadAgents();
        _listenToAgents();
      }
    } catch (_) {
      loadAgents();
      _listenToAgents();
    }
  }

  void _listenToAgents() {
    _agentsSubscription?.cancel();
    _agentsSubscription = SupabaseService.client
        .from('agents')
        .stream(primaryKey: ['id'])
        .listen((_) {
          _reloadDebounce?.cancel();
          _reloadDebounce = Timer(const Duration(milliseconds: 750), loadAgents);
        }, onError: (_) {});
  }

  void _stopListening() {
    _reloadDebounce?.cancel();
    _agentsSubscription?.cancel();
    _agentsSubscription = null;
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'AgentController',
      method: 'onClose',
      feature: 'Agents',
      status: 'INFO',
    );
    _stopListening();
    _authWorker?.dispose();
    super.onClose();
  }

  /// Load agents from Supabase
  Future<void> loadAgents() async {
    AppLoggerService.debugTrace(
      className: 'AgentController',
      method: 'loadAgents',
      feature: 'Agents',
      status: 'INFO',
    );
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('agents')
          .select('*, profiles!left(*)')
          .order('created_at', ascending: false);

      agents.value = (response as List)
          .map((json) => Agent.fromSupabase(json))
          .toList();
      _applyFilters();
      AppLoggerService.debugTrace(
        className: 'AgentController',
        method: 'loadAgents',
        feature: 'Agents',
        status: 'SUCCESS',
        params: {'count': agents.length},
      );
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'AgentController',
        method: 'loadAgents',
        feature: 'Agents',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
      AppLoggerService.logError(
        controller: 'AgentController',
        method: 'loadAgents',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحميل الوكلاء',
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

  String _generateTempPassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#';
    final random = Random.secure();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

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
    String availabilityStatus = 'available',
  }) async {
    try {
      AppLoggerService.debugTrace(
        className: 'AgentController',
        method: 'createAgent',
        feature: 'Agents',
        status: 'INFO',
        params: {'name': name},
      );
      isLoading.value = true;

      if (email.trim().isEmpty) {
        Get.snackbar(
          'خطأ',
          'البريد الإلكتروني مطلوب لإنشاء حساب الوكيل',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final tempPassword = _generateTempPassword();
      final userId = await AdminProxyService.createUser(
        email: email.trim(),
        password: tempPassword,
        userMetadata: {
          'full_name': name,
          'role': 'agent',
          'phone': phone,
          'country_code': country,
        },
      );

      if (userId == null || userId.isEmpty) {
        throw Exception('Failed to create auth user for agent');
      }

      final existingProfile = await SupabaseService.client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (existingProfile == null) {
        throw Exception(
          'لم يتم إنشاء ملف المستخدم — أعد نشر Edge Function admin-proxy',
        );
      }

      await SupabaseService.client.from('profiles').update({
        'full_name': name,
        'country_code': country,
        'province': province,
        'city': city,
        'address': address,
        'phone': phone,
        'whatsapp': whatsapp,
        'telegram': telegram,
        'email': email.trim(),
        'role': 'agent',
        'status': 'active',
      }).eq('id', userId);

      await SupabaseService.client.from('agents').insert({
        'user_id': userId,
        'name': name,
        'phone': phone,
        'email': email.trim(),
        'country': country,
        'province': province,
        'city': city,
        'address': address,
        'whatsapp': whatsapp,
        'telegram': telegram,
        'status': 'active',
        'is_available_now': availabilityStatus == 'available',
        'supported_methods': [
          if (whatsapp.isNotEmpty) 'WhatsApp',
          if (telegram.isNotEmpty) 'Telegram',
          'Call',
        ],
      });

      await loadAgents();
      Get.snackbar(
        'تم',
        'تم إنشاء الوكيل بنجاح. كلمة المرور المؤقتة: $tempPassword',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 8),
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AgentController',
        method: 'createAgent',
        error: e,
        stackTrace: stackTrace,
      );
      String msg = 'فشل في إنشاء الوكيل';
      final err = e.toString();
      if (err.contains('agents_user_id_fkey') ||
          err.contains('Key is not present in table "profiles"')) {
        msg =
            'لم يُنشأ ملف المستخدم — انشر Edge Function admin-proxy ثم أعد المحاولة';
      } else if (err.contains('already been registered') ||
          err.contains('already exists')) {
        msg = 'البريد الإلكتروني مسجل مسبقاً';
      } else if (err.replaceFirst('Exception: ', '').trim().isNotEmpty) {
        msg = err.replaceFirst('Exception: ', '');
      }
      Get.snackbar(
        'خطأ',
        msg,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load full agent record from Supabase (agents + profile join)
  Future<Agent?> fetchAgentDetails(String agentId) async {
    try {
      final response = await SupabaseService.client
          .from('agents')
          .select('*, profiles!agents_user_id_fkey(*)')
          .eq('id', agentId)
          .maybeSingle();

      if (response == null) return null;
      return Agent.fromSupabase(Map<String, dynamic>.from(response));
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AgentController',
        method: 'fetchAgentDetails',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Update agent by ID and a map of fields (matches UI call site)
  Future<void> updateAgent(String agentId, Map<String, dynamic> data) async {
    try {
      AppLoggerService.debugTrace(
        className: 'AgentController',
        method: 'updateAgent',
        feature: 'Agents',
        status: 'INFO',
        params: {'agentId': agentId},
      );

      final agentRow = await SupabaseService.client
          .from('agents')
          .select('id, user_id')
          .eq('id', agentId)
          .maybeSingle();

      final profileId = agentRow?['user_id']?.toString() ?? agentId;

      // Separate profile fields from agent fields
      final profileFields = [
        'full_name',
        'name',
        'country_code',
        'country',
        'city',
        'province',
        'address',
        'phone',
        'whatsapp',
        'telegram',
        'email',
      ];
      final Map<String, dynamic> profileData = {};
      final Map<String, dynamic> agentData = {};

      data.forEach((key, value) {
        if (key == 'availability_status') {
          agentData['is_available_now'] = value == 'available';
          return;
        }
        if (profileFields.contains(key)) {
          // Normalize keys for profiles table
          String normalizedKey = key;
          if (key == 'name') normalizedKey = 'full_name';
          if (key == 'country') normalizedKey = 'country_code';
          profileData[normalizedKey] = value;
        } else {
          agentData[key] = value;
        }
      });

      // Update profiles if needed
      if (profileData.isNotEmpty) {
        await SupabaseService.client
            .from('profiles')
            .update(profileData)
            .eq('id', profileId);
      }

      // Update agents if needed
      if (agentData.isNotEmpty) {
        await SupabaseService.client
            .from('agents')
            .update(agentData)
            .eq('id', agentId);
      }

      await loadAgents();

      Get.snackbar(
        'تم',
        'تم تحديث بيانات الوكيل والملف الموحد',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AgentController',
        method: 'updateAgent',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحديث بيانات الوكيل',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Delete agent row (and verify deletion)
  Future<bool> deleteAgent(String agentId) async {
    try {
      AppLoggerService.debugTrace(
        className: 'AgentController',
        method: 'deleteAgent',
        feature: 'Agents',
        status: 'INFO',
        params: {'agentId': agentId},
      );

      final deleted = await SupabaseService.client
          .from('agents')
          .delete()
          .eq('id', agentId)
          .select('id');

      if (deleted.isEmpty) {
        throw Exception('No agent row deleted');
      }

      agents.removeWhere((a) => a.id == agentId);
      _applyFilters();

      Get.snackbar('تم', 'تم حذف الوكيل', snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AgentController',
        method: 'deleteAgent',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في حذف الوكيل',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
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
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AgentController',
        method: 'toggleAvailability',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'خطأ',
        'فشل في تحديث الحالة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle agent status (active/inactive) — DB check constraint uses lowercase
  Future<void> toggleStatus(String agentId) async {
    try {
      final agent = agents.firstWhere((a) => a.id == agentId);
      final newStatus = agent.isActive ? 'inactive' : 'active';

      await SupabaseService.client
          .from('agents')
          .update({'status': newStatus})
          .eq('id', agentId);

      final idx = agents.indexWhere((a) => a.id == agentId);
      if (idx != -1) {
        agents[idx] = agents[idx].copyWith(status: newStatus);
        _applyFilters();
      }
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AgentController',
        method: 'toggleStatus',
        error: e,
        stackTrace: stackTrace,
      );
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
