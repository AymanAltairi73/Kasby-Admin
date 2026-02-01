import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/agent_controller.dart';
import '../models/agent_model.dart';

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
        title: const Text('قائمة الوكلاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _showCreateAgentDialog(context, controller),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Celestial Background
          _buildCelestialBackground(),

          Column(
            children: [
              const SizedBox(height: 100),

              // Search and Filter Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child:
                    KasbyGlassCard(
                          padding: const EdgeInsets.all(16),
                          opacity: 0.08,
                          child: Column(
                            children: [
                              KasbyTextField(
                                hintText: 'بحث باسم المنطقة أو الوكيل...',
                                prefixIcon: Icons.search_rounded,
                                onChanged: (value) =>
                                    controller.searchAgents(value),
                              ),
                              const SizedBox(height: 12),
                              Obx(() {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildFilterChip(
                                        'الكل',
                                        'All',
                                        controller,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        'نشط',
                                        'Active',
                                        controller,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        'معطل',
                                        'Inactive',
                                        controller,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 600))
                        .slideY(begin: -0.2),
              ),

              const SizedBox(height: 16),

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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_rounded,
                            size: 64,
                            color: KasbyColors.primaryGold.withOpacity(0.3),
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
                      ).animate().fadeIn(),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: filteredAgents.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final agent = filteredAgents[index];
                      return _buildAgentCard(agent, controller, index);
                    },
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    AgentController controller,
  ) {
    final isSelected = controller.selectedStatus.value == value;
    return GestureDetector(
      onTap: () => controller.filterByStatus(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? KasbyColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? KasbyColors.primaryGold.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: KasbyColors.primaryGold.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : KasbyColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAgentCard(Agent agent, AgentController controller, int index) {
    return KasbyGlassCard(
          onTap: () => _showAgentDetailsDialog(Get.context!, agent, controller),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: KasbyColors.primaryGradient,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: KasbyColors.primaryGold.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        agent.name[0],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ).animate().scale(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: KasbyColors.primaryGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              agent.country,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusIndicator(agent.status),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: FontAwesomeIcons.chartLine,
                      label: 'نسبة النجاح',
                      value: '${agent.successRate.toStringAsFixed(1)}%',
                      color: KasbyColors.success,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: FontAwesomeIcons.arrowRightArrowLeft,
                      label: 'المعاملات',
                      value: agent.totalTransactions.toString(),
                      color: KasbyColors.info,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: 0.2);
  }

  Widget _buildStatusIndicator(String status) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? KasbyColors.success.withOpacity(0.1)
            : KasbyColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? KasbyColors.success.withOpacity(0.3)
              : KasbyColors.error.withOpacity(0.3),
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
                      color:
                          (isActive ? KasbyColors.success : KasbyColors.error)
                              .withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: const Duration(seconds: 1),
              ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'نشط' : 'معطل',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
            Icon(icon, size: 14, color: color.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateAgentDialog(
    BuildContext context,
    AgentController controller,
  ) {
    final nameController = TextEditingController();
    final countryController = TextEditingController(text: 'العراق');
    final phoneController = TextEditingController(text: '+964');
    final emailController = TextEditingController();

    Get.dialog(
      BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: KasbyGlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إضافة وكيل عراقي جديد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: KasbyColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 24),
                KasbyTextField(
                  controller: nameController,
                  hintText: 'اسم الوكيل (مثال: وكيل بغداد)',
                  prefixIcon: Icons.person_rounded,
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: countryController,
                  hintText: 'البلد',
                  prefixIcon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: phoneController,
                  hintText: 'رقم الهاتف',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_rounded,
                ),
                const SizedBox(height: 16),
                KasbyTextField(
                  controller: emailController,
                  hintText: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_rounded,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: KasbyColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () {
                            if (nameController.text.isNotEmpty &&
                                countryController.text.isNotEmpty &&
                                phoneController.text.isNotEmpty &&
                                emailController.text.isNotEmpty) {
                              controller.createAgent(
                                name: nameController.text,
                                country: countryController.text,
                                phone: phoneController.text,
                                email: emailController.text,
                              );
                              Get.back();
                            } else {
                              Get.snackbar('خطأ', 'الرجاء ملء جميع الحقول');
                            }
                          },
                          child: const Text(
                            'إضافة',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAgentDetailsDialog(
    BuildContext context,
    Agent agent,
    AgentController controller,
  ) {
    Get.dialog(
      BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: KasbyGlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child:
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: KasbyColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: KasbyColors.primaryGold.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            agent.name[0],
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ).animate().scale(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                      ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    agent.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildDetailRow('المنطقة', agent.country, Icons.map_rounded),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'رقم التواصل',
                  agent.phone,
                  Icons.phone_android_rounded,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'البريد',
                  agent.email,
                  Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'تاريخ الانضمام',
                  DateFormat('dd MMMM yyyy', 'en').format(agent.createdAt),
                  Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: agent.status == 'Active'
                              ? KasbyColors.error.withOpacity(0.1)
                              : KasbyColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: agent.status == 'Active'
                                ? KasbyColors.error.withOpacity(0.3)
                                : KasbyColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            controller.toggleAgentStatus(agent.id);
                          },
                          child: Text(
                            agent.status == 'Active'
                                ? 'تعطيل الوكيل'
                                : 'تفعيل الوكيل',
                            style: TextStyle(
                              color: agent.status == 'Active'
                                  ? KasbyColors.error
                                  : KasbyColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: const Text(
                            'إغلاق',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: KasbyColors.primaryGold),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          Expanded(
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
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
          color: KasbyColors.primaryGold.withOpacity(0.05),
        ),
        _buildOrb(
          bottom: -150,
          right: -150,
          size: 500,
          color: KasbyColors.info.withOpacity(0.05),
        ),
        _buildOrb(
          top: 200,
          right: -50,
          size: 300,
          color: KasbyColors.success.withOpacity(0.03),
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
      child:
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -20, end: 20, duration: const Duration(seconds: 4))
              .moveX(begin: -20, end: 20, duration: const Duration(seconds: 5)),
    );
  }
}
