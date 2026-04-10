import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../../../core/widgets/kasby_confirmation_dialog.dart';
import '../controllers/agent_controller.dart';
import '../models/agent_model.dart';
import '../../chat/controllers/chat_controller.dart' as kasby_chat;
import 'agent_applications_screen.dart';

/// Agents Screen
/// Manage agents (proxies) and their performance with a dazzling Iraq focus
class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AgentController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إدارة الوكلاء'),
        actions: [
          // Search Icon
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearchDialog(context, controller),
          ),
          // // Time Filter Dropdown
          // PopupMenuButton<TimeFilter>(
          //   icon: const Icon(Icons.filter_list_rounded),
          //   tooltip: 'تصفية حسب الوقت',
          //   onSelected: (TimeFilter filter) {
          //     controller.selectedTimeFilter.value = filter;
          //   },
          //   itemBuilder: (context) => [
          //     PopupMenuItem(
          //       value: TimeFilter.all,
          //       child: Row(
          //         children: [
          //           Icon(
          //             Icons.all_inclusive,
          //             size: 18,
          //             color:
          //                 controller.selectedTimeFilter.value == TimeFilter.all
          //                 ? KasbyColors.primaryGold
          //                 : Colors.white60,
          //           ),
          //           const SizedBox(width: 8),
          //           Text('الكل'),
          //         ],
          //       ),
          //     ),
          //     PopupMenuItem(
          //       value: TimeFilter.daily,
          //       child: Row(
          //         children: [
          //           Icon(
          //             Icons.today,
          //             size: 18,
          //             color:
          //                 controller.selectedTimeFilter.value ==
          //                     TimeFilter.daily
          //                 ? KasbyColors.primaryGold
          //                 : Colors.white60,
          //           ),
          //           const SizedBox(width: 8),
          //           Text('اليوم'),
          //         ],
          //       ),
          //     ),
          //     PopupMenuItem(
          //       value: TimeFilter.weekly,
          //       child: Row(
          //         children: [
          //           Icon(
          //             Icons.date_range,
          //             size: 18,
          //             color:
          //                 controller.selectedTimeFilter.value ==
          //                     TimeFilter.weekly
          //                 ? KasbyColors.primaryGold
          //                 : Colors.white60,
          //           ),
          //           const SizedBox(width: 8),
          //           Text('الأسبوع'),
          //         ],
          //       ),
          //     ),
          //     PopupMenuItem(
          //       value: TimeFilter.monthly,
          //       child: Row(
          //         children: [
          //           Icon(
          //             Icons.calendar_month,
          //             size: 18,
          //             color:
          //                 controller.selectedTimeFilter.value ==
          //                     TimeFilter.monthly
          //                 ? KasbyColors.primaryGold
          //                 : Colors.white60,
          //           ),
          //           const SizedBox(width: 8),
          //           Text('الشهر'),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
          // Status Filter Dropdown
          // PopupMenuButton<String>(
          //   icon: const Icon(Icons.people_outline_rounded),
          //   tooltip: 'تصفية حسب الحالة',
          //   onSelected: (String status) {
          //     controller.filterByStatus(status);
          //   },
          //   itemBuilder: (context) => [
          //     PopupMenuItem(
          //       value: 'All',
          //       child: Row(
          //         children: [
          //           Icon(
          //             Icons.all_inclusive,
          //             size: 18,
          //             color: controller.selectedStatus.value == 'All'
          //                 ? KasbyColors.info
          //                 : Colors.white60,
          //           ),
          //           const SizedBox(width: 8),
          //           Text('الكل'),
          //         ],
          //       ),
          //     ),
          //     PopupMenuItem(
          //       value: 'Active',
          //       child: Row(
          //         children: [
          //           Icon(
          //             Icons.check_circle_outline,
          //             size: 18,
          //             color: controller.selectedStatus.value == 'Active'
          //                 ? KasbyColors.success
          //                 : Colors.white60,
          //           ),
          //           const SizedBox(width: 8),
          //           Text('نشط'),
          //         ],
          //       ),
          //     ),
          //     PopupMenuItem(
          //       value: 'Inactive',
          //       child: Row(
          //         children: [
          //           Icon(
          //             Icons.block,
          //             size: 18,
          //             color: controller.selectedStatus.value == 'Inactive'
          //                 ? KasbyColors.error
          //                 : Colors.white60,
          //           ),
          //           const SizedBox(width: 8),
          //           Text('معطل'),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),

          IconButton(
            icon: const Icon(Icons.mark_email_unread_rounded),
            tooltip: 'طلبات الانضمام',
            onPressed: () => Get.to(() => const AgentApplicationsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => Get.toNamed('/edit-agent'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Celestial Background
          RepaintBoundary(child: _buildCelestialBackground()),

          Column(
            children: [
              const SizedBox(height: 100),

              // Top Summary/Action Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Obx(() {
                  final totalAgents = controller.agents.length;
                  final activeAgents = controller.activeAgents.length;

                  return KasbyGlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إحصائيات شبكة الوكلاء',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: KasbyColors.primaryGold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildSummaryItem(
                                  label: 'الإجمالي:',
                                  value: totalAgents.toString(),
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                _buildSummaryItem(
                                  label: 'النشطون:',
                                  value: activeAgents.toString(),
                                  color: KasbyColors.success,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 4),

              // Agents List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.agents.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: KasbyColors.primaryGold,
                      ),
                    );
                  }

                  final filteredAgents = controller.filteredAgents;

                  if (filteredAgents.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => controller.loadAgents(),
                      color: KasbyColors.primaryGold,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.group_off_rounded,
                                  size: 64,
                                  color: KasbyColors.primaryGold.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'لا يوجد وكلاء متطابقين مع البحث',
                                  style: TextStyle(
                                    color: KasbyColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.loadAgents(),
                    color: KasbyColors.primaryGold,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filteredAgents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final agent = filteredAgents[index];
                        return _buildAgentCard(agent, controller, index);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search Dialog
  static void _showSearchDialog(
    BuildContext context,
    AgentController controller,
  ) {
    Get.dialog(
      Center(
        child: KasbyGlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'بحث عن وكيل',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: KasbyColors.primaryGold,
                ),
              ),
              const SizedBox(height: 24),
              KasbyTextField(
                hintText: 'بحث باسم المنطقة أو الوكيل...',
                prefixIcon: Icons.search_rounded,
                onChanged: (value) => controller.searchAgents(value),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'إغلاق النافذة',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentCard(Agent agent, AgentController controller, int index) {

    return KasbyGlassCard(
      onTap: () => Get.toNamed('/agent-details', arguments: agent),
      padding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          // Background Decorative Pattern
          Positioned(
            top: -20,
            left: -20,
            child: Icon(
              Icons.shield_outlined,
              size: 150,
              color: KasbyColors.primaryGold.withValues(alpha: 0.03),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Premium Avatar with Gradient Border
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            KasbyColors.primaryGold,
                            KasbyColors.primaryGold.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            agent.name.isNotEmpty ? agent.name[0] : '؟',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: KasbyColors.primaryGold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  agent.name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: KasbyColors.primaryGold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${agent.city} - ${agent.province}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Actions Menu
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          color: KasbyColors.primaryGold,
                          size: 20,
                        ),
                      ),
                      offset: const Offset(0, 40),
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'chat':
                            final chatController = Get.find<kasby_chat.ChatController>();
                            chatController.startChatWithUser(agent.userId);
                            break;
                          case 'edit':
                            Get.toNamed('/edit-agent', arguments: agent);
                            break;
                          case 'toggle':
                            controller.toggleAgentStatus(agent.id);
                            break;
                          case 'delete':
                            _showDeleteAgentConfirmation(
                              Get.context!,
                              agent,
                              controller,
                            );
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'chat',
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 22, color: KasbyColors.info),
                              const SizedBox(width: 12),
                              const Text('بدء محادثة',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_note_rounded,
                                  size: 22, color: KasbyColors.primaryGold),
                              const SizedBox(width: 12),
                              const Text('تحديث البيانات',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                agent.status == 'Active'
                                    ? Icons.pause_circle_outline_rounded
                                    : Icons.play_circle_outline_rounded,
                                size: 22,
                                color: agent.status == 'Active'
                                    ? KasbyColors.warning
                                    : KasbyColors.success,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                agent.status == 'Active' ? 'تعطيل' : 'تفعيل',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_sweep_rounded,
                                  size: 22, color: KasbyColors.error),
                              const SizedBox(width: 12),
                              const Text('حذف الوكيل',
                                  style: TextStyle(
                                      color: KasbyColors.error, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.swap_horizontal_circle_outlined,
                          label: 'المعاملات',
                          value: agent.totalTransactions.toString(),
                          color: KasbyColors.info,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Footer: Status and Methods
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusIndicator(agent.status),
                    Row(
                      children: agent.supportedMethods.map((method) {
                        IconData iconData;
                        Color iconColor;
                        switch (method) {
                          case 'WhatsApp':
                            iconData = FontAwesomeIcons.whatsapp;
                            iconColor = const Color(0xFF25D366);
                            break;
                          case 'Telegram':
                            iconData = FontAwesomeIcons.telegram;
                            iconColor = const Color(0xFF24A1DE);
                            break;
                          case 'Call':
                            iconData = Icons.phone_android_rounded;
                            iconColor = KasbyColors.info;
                            break;
                          default:
                            iconData = Icons.chat_bubble_outline_rounded;
                            iconColor = Colors.white70;
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: iconColor.withValues(alpha: 0.2)),
                          ),
                          child: Icon(iconData, size: 14, color: iconColor),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatusIndicator(String status) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? KasbyColors.success.withValues(alpha: 0.1)
            : KasbyColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? KasbyColors.success.withValues(alpha: 0.2)
              : KasbyColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? KasbyColors.success : KasbyColors.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isActive ? KasbyColors.success : KasbyColors.error)
                      .withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'نشط' : 'معطل',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isActive ? KasbyColors.success : KasbyColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: KasbyColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteAgentConfirmation(
    BuildContext context,
    Agent agent,
    AgentController controller,
  ) {
    KasbyConfirmationDialog.show(
      title: 'حذف الوكيل',
      message:
          'هل أنت متأكد من حذف الوكيل "${agent.name}"؟ لا يمكن التراجع عن هذه العملية.',
      isDangerous: true,
      confirmText: 'حذف',
      onConfirm: () {
        controller.deleteAgent(agent.id);
        if (Get.isDialogOpen ?? false) Get.back();
      },
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: KasbyColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        // Dark Base
        Container(color: const Color(0xFF0F172A)),

        // Animated Orbs
        _buildOrb(
          top: -100,
          left: -100,
          size: 400,
          color: KasbyColors.primaryGold.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -150,
          right: -150,
          size: 500,
          color: KasbyColors.info.withValues(alpha: 0.05),
        ),
        _buildOrb(
          top: 200,
          right: -50,
          size: 300,
          color: KasbyColors.success.withValues(alpha: 0.03),
        ),
      ],
    );
  }

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
            ],
          ),
        ),
      ),
    );
  }
}
