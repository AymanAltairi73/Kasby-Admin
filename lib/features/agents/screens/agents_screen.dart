import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/agent_controller.dart';
import '../models/agent_model.dart';

/// Agents Screen
/// Manage agents (proxies) and their performance
class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AgentController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('الوكلاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateAgentDialog(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                KasbyTextField(
                  hintText: 'بحث بالاسم، البلد، أو البريد',
                  prefixIcon: Icons.search,
                  onChanged: (value) => controller.searchAgents(value),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('الكل', 'All', controller),
                        const SizedBox(width: 8),
                        _buildFilterChip('نشط', 'Active', controller),
                        const SizedBox(width: 8),
                        _buildFilterChip('معطل', 'Inactive', controller),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

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
                return const Center(
                  child: Text(
                    'لا توجد وكلاء',
                    style: TextStyle(
                      color: KasbyColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filteredAgents.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final agent = filteredAgents[index];
                  return _buildAgentCard(agent, controller);
                },
              );
            }),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KasbyColors.primaryGold : KasbyColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : KasbyColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAgentCard(Agent agent, AgentController controller) {
    return KasbyCard(
      onTap: () => _showAgentDetailsDialog(Get.context!, agent, controller),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: KasbyColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    agent.name[0],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: KasbyColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          agent.country,
                          style: const TextStyle(
                            fontSize: 14,
                            color: KasbyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: agent.status == 'Active'
                      ? KasbyColors.success.withValues(alpha: 0.2)
                      : KasbyColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  agent.status == 'Active' ? 'نشط' : 'معطل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: agent.status == 'Active'
                        ? KasbyColors.success
                        : KasbyColors.error,
                  ),
                ),
              ),
            ],
          ),
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.email,
                size: 14,
                color: KasbyColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  agent.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: KasbyColors.textSecondary,
                  ),
                ),
              ),
            ],
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
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: KasbyColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
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
    final countryController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: const Text(
          'إضافة وكيل جديد',
          style: TextStyle(color: KasbyColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KasbyTextField(
                controller: nameController,
                hintText: 'اسم الوكيل',
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: countryController,
                hintText: 'البلد',
                prefixIcon: Icons.location_on,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: phoneController,
                hintText: 'رقم الهاتف',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
              ),
              const SizedBox(height: 12),
              KasbyTextField(
                controller: emailController,
                hintText: 'البريد الإلكتروني',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: KasbyColors.textSecondary),
            ),
          ),
          TextButton(
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
              style: TextStyle(color: KasbyColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAgentDetailsDialog(
    BuildContext context,
    Agent agent,
    AgentController controller,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: KasbyColors.surface,
        title: Text(
          agent.name,
          style: const TextStyle(color: KasbyColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('البلد', agent.country, Icons.location_on),
              const SizedBox(height: 12),
              _buildDetailRow('الهاتف', agent.phone, Icons.phone),
              const SizedBox(height: 12),
              _buildDetailRow('البريد', agent.email, Icons.email),
              const SizedBox(height: 12),
              _buildDetailRow(
                'نسبة النجاح',
                '${agent.successRate.toStringAsFixed(1)}%',
                Icons.trending_up,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'إجمالي المعاملات',
                agent.totalTransactions.toString(),
                Icons.receipt_long,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'تاريخ الإضافة',
                DateFormat('dd/MM/yyyy', 'en').format(agent.createdAt),
                Icons.calendar_today,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.toggleAgentStatus(agent.id);
            },
            child: Text(
              agent.status == 'Active' ? 'تعطيل' : 'تفعيل',
              style: TextStyle(
                color: agent.status == 'Active'
                    ? KasbyColors.error
                    : KasbyColors.success,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'إغلاق',
              style: TextStyle(color: KasbyColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KasbyColors.primaryGold),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: KasbyColors.textPrimary,
          ),
        ),
        Expanded(
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: KasbyColors.textBody),
            ),
          ),
        ),
      ],
    );
  }
}
