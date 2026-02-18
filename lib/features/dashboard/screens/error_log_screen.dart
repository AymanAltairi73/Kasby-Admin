import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/models/error_log_model.dart';
import '../../../core/models/time_filter.dart';
import '../controllers/error_log_controller.dart';

class ErrorLogScreen extends StatelessWidget {
  const ErrorLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ErrorLogController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(controller),
      body: Stack(
        children: [
          _buildCelestialBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildSearchAndFilters(controller),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.filteredLogs.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: KasbyColors.primaryGold,
                        ),
                      );
                    }

                    if (controller.filteredLogs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = controller.filteredLogs[index];
                        return _buildLogItem(context, log, index);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ErrorLogController controller) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.02),
            elevation: 0,
            title: const Text(
              'سجل أخطاء النظام',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: KasbyColors.error,
                ),
                onPressed: () => _showPurgeConfirm(controller),
                tooltip: 'تنظيف السجلات القديمة',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => controller.fetchLogs(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(ErrorLogController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          KasbyGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: BorderRadius.circular(15),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث في الرسائل أو الكنترولر...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                icon: const Icon(
                  Icons.search_rounded,
                  color: KasbyColors.primaryGold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'الكل',
                    isSelected:
                        controller.selectedTimeFilter.value == TimeFilter.all,
                    onTap: () =>
                        controller.selectedTimeFilter.value = TimeFilter.all,
                  ),
                  _buildFilterChip(
                    label: 'اليوم',
                    isSelected:
                        controller.selectedTimeFilter.value == TimeFilter.daily,
                    onTap: () =>
                        controller.selectedTimeFilter.value = TimeFilter.daily,
                  ),
                  _buildFilterChip(
                    label: 'هذا الأسبوع',
                    isSelected:
                        controller.selectedTimeFilter.value ==
                        TimeFilter.weekly,
                    onTap: () =>
                        controller.selectedTimeFilter.value = TimeFilter.weekly,
                  ),
                  _buildFilterChip(
                    label: 'هذا الشهر',
                    isSelected:
                        controller.selectedTimeFilter.value ==
                        TimeFilter.monthly,
                    onTap: () => controller.selectedTimeFilter.value =
                        TimeFilter.monthly,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedController.value,
                      hint: const Text(
                        'الكنترولر',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('جميع الكنترولر'),
                        ),
                        ...controller.availableControllers.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (val) =>
                          controller.selectedController.value = val,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? KasbyColors.primaryGold
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? KasbyColors.primaryGold
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, ErrorLog log, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child:
          KasbyGlassCard(
                onTap: () => _showLogDetails(context, log),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: KasbyColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bug_report_rounded,
                        color: KasbyColors.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log.controllerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: KasbyColors.primaryGold,
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm').format(log.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.errorMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.code_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                log.methodName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.devices_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                log.deviceInfo?['platform'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: 30 * index))
              .fadeIn()
              .slideX(begin: 0.05),
    );
  }

  void _showLogDetails(BuildContext context, ErrorLog log) {
    Get.bottomSheet(
      KasbyGlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تفاصيل الخطأ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white10, height: 32),
              _buildDetailItem(
                'الكنترولر والميثود',
                '${log.controllerName} ➜ ${log.methodName}',
              ),
              _buildDetailItem(
                'رسالة الخطأ',
                log.errorMessage,
                color: KasbyColors.error,
              ),
              _buildDetailItem(
                'الجهاز والإصدار',
                '${log.deviceSummary} (App: ${log.appVersion})',
              ),
              _buildDetailItem(
                'التاريخ',
                DateFormat('yyyy/MM/dd HH:mm:ss').format(log.createdAt),
              ),

              if (log.stackTrace != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Stack Trace',
                  style: TextStyle(
                    color: KasbyColors.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: SelectableText(
                    log.stackTrace!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: color ?? Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.circleCheck,
            size: 60,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد أخطاء مسجلة حالياً',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildCelestialBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
    );
  }

  void _showPurgeConfirm(ErrorLogController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'تنظيف السجلات',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'هل أنت متأكد من حذف السجلات التي مضى عليها أكثر من 30 يوماً؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.purgeLogs();
            },
            child: const Text(
              'تنظيف',
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
