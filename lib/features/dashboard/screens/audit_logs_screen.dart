import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/audit_controller.dart';
import '../models/audit_log_model.dart';
import '../../../core/models/time_filter.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuditController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(controller),
      body: Stack(
        children: [
          RepaintBoundary(child: _buildCelestialBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildFilterSection(controller),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value && controller.logs.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: KasbyColors.primaryGold,
                        ),
                      );
                    }

                    if (controller.logs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.logs.length,
                      itemBuilder: (context, index) {
                        final log = controller.logs[index];
                        return _buildEnhancedLogItem(context, log, index);
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

  PreferredSizeWidget _buildAppBar(AuditController controller) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.02),
            elevation: 0,
            title: const Text(
              'سجل النشاطات العمليات',
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
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => controller.fetchLogs(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(AuditController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          KasbyGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: BorderRadius.circular(15),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث في السجلات...',
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'كل التصنيفات',
                    isSelected: controller.selectedType.value == null,
                    onTap: () => controller.selectedType.value = null,
                  ),
                  ...AuditLogType.values.map((type) {
                    return _buildFilterChip(
                      label: _getTypeLabel(type),
                      isSelected: controller.selectedType.value == type,
                      onTap: () => controller.selectedType.value = type,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
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

  Widget _buildEnhancedLogItem(BuildContext context, AuditLog log, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child:
          KasbyGlassCard(
                onTap: () => _showLogDetails(context, log),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status Icon with Glow
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getTypeColor(log.type).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getTypeColor(log.type).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            log.icon,
                            color: _getTypeColor(log.type),
                            size: 22,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _getStatusColor(log.status),
                                shape: BoxShape.circle,
                                border: const Border.fromBorderSide(
                                  BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  log.action,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Directionality(
                                textDirection: ui.TextDirection.ltr,
                                child: Text(
                                  DateFormat(
                                    'HH:mm',
                                    'en',
                                  ).format(log.timestamp),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: KasbyColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.details,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                log.adminName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getTypeLabel(log.type),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getTypeColor(log.type),
                                  ),
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
              .animate(delay: Duration(milliseconds: 50 * index))
              .fadeIn()
              .slideX(begin: 0.1),
    );
  }

  void _showLogDetails(BuildContext context, AuditLog log) {
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getTypeColor(log.type).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      log.icon,
                      color: _getTypeColor(log.type),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.action,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _getTypeLabel(log.type),
                          style: TextStyle(color: _getTypeColor(log.type)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildDetailItem('التفاصيل الكاملة', log.details),
              _buildDetailItem('المسؤول', log.adminName),
              _buildDetailItem(
                'التاريخ والوقت',
                DateFormat('yyyy/MM/dd - HH:mm:ss', 'en').format(log.timestamp),
                isLtr: true,
              ),
              if (log.ipAddress != null)
                _buildDetailItem('عنوان IP', log.ipAddress!, isLtr: true),
              if (log.device != null) _buildDetailItem('الجهاز', log.device!),
              if (log.targetId != null)
                _buildDetailItem(
                  'المعرف المستهدف (${log.targetType ?? "Object"})',
                  log.targetId!,
                  isLtr: true,
                ),
              if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'البيانات الوصفية (Metadata)',
                  style: TextStyle(
                    color: KasbyColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: log.metadata!.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              '${e.key}: ',
                              style: const TextStyle(
                                color: KasbyColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

  Widget _buildDetailItem(String label, String value, {bool isLtr = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: isLtr ? ui.TextDirection.ltr : ui.TextDirection.rtl,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
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
            FontAwesomeIcons.magnifyingGlass,
            size: 60,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد سجلات تطابق بحثك',
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

  String _getTypeLabel(AuditLogType type) {
    switch (type) {
      case AuditLogType.security:
        return 'أمان';
      case AuditLogType.financial:
        return 'مالي';
      case AuditLogType.userManagement:
        return 'مستخدمين';
      case AuditLogType.investment:
        return 'استثمار';
      case AuditLogType.system:
        return 'نظام';
    }
  }

  Color _getTypeColor(AuditLogType type) {
    switch (type) {
      case AuditLogType.security:
        return KasbyColors.error;
      case AuditLogType.financial:
        return KasbyColors.success;
      case AuditLogType.userManagement:
        return KasbyColors.info;
      case AuditLogType.investment:
        return KasbyColors.primaryGold;
      case AuditLogType.system:
        return KasbyColors.warning;
    }
  }

  Color _getStatusColor(AuditLogStatus status) {
    switch (status) {
      case AuditLogStatus.success:
        return KasbyColors.success;
      case AuditLogStatus.warning:
        return KasbyColors.warning;
      case AuditLogStatus.failure:
        return KasbyColors.error;
    }
  }
}
