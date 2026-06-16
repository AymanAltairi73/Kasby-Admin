import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/admin_metric_chip.dart';

class QrController extends GetxController {
  final codes = <Map<String, String>>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final selectedCode = ''.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'QrController',
      method: 'onInit',
      feature: 'Qr',
      status: 'INFO',
    );
    super.onInit();
    loadCodes();
  }

  Future<void> loadCodes() async {
    AppLoggerService.debugTrace(
      className: 'QrController',
      method: 'loadCodes',
      feature: 'Qr',
      status: 'INFO',
    );
    isLoading.value = true;
    hasError.value = false;
    try {
      final agents = await SupabaseService.client
          .from('agents')
          .select(
            'id, user_id, profiles!agents_user_id_fkey(full_name, referral_code, role)',
          )
          .limit(100);

      final profiles = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, referral_code, role')
          .not('referral_code', 'is', null)
          .neq('role', 'admin')
          .limit(200);

      final merged = <Map<String, String>>[];
      final seenCodes = <String>{};

      for (final row in agents as List) {
        final profile = row['profiles'] as Map? ?? {};
        final code = (profile['referral_code'] as String? ?? '').trim();
        if (code.isEmpty || !seenCodes.add(code.toUpperCase())) continue;
        merged.add({
          'label': profile['full_name']?.toString() ?? 'وكيل',
          'code': code,
          'type': 'agent',
        });
      }

      for (final row in profiles as List) {
        if (row['role'] == 'agent') continue;
        final code = (row['referral_code'] as String? ?? '').trim();
        if (code.isEmpty || !seenCodes.add(code.toUpperCase())) continue;
        merged.add({
          'label': row['full_name']?.toString() ?? 'مستخدم',
          'code': code,
          'type': 'user',
        });
      }

      codes.assignAll(merged);
      if (codes.isNotEmpty &&
          !codes.any((c) => c['code'] == selectedCode.value)) {
        selectedCode.value = codes.first['code']!;
      }
      if (codes.isEmpty) selectedCode.value = '';

      AppLoggerService.debugTrace(
        className: 'QrController',
        method: 'loadCodes',
        feature: 'Qr',
        status: 'SUCCESS',
        params: {'count': codes.length},
      );
    } catch (e, stackTrace) {
      hasError.value = true;
      AppLoggerService.logError(
        controller: 'QrController',
        method: 'loadCodes',
        error: e,
        stackTrace: stackTrace,
      );
      Get.snackbar('خطأ', 'فشل تحميل أكواد QR');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, String>? get selectedEntry {
    if (selectedCode.value.isEmpty) return null;
    for (final c in codes) {
      if (c['code'] == selectedCode.value) return c;
    }
    return null;
  }

  String get selectedUrl {
    if (selectedCode.value.isEmpty) return '';
    return 'https://kasby.app/join?ref=${selectedCode.value}';
  }

  int get agentCount => codes.where((c) => c['type'] == 'agent').length;
  int get userCount => codes.where((c) => c['type'] == 'user').length;
}

class QrManagementScreen extends StatelessWidget {
  const QrManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QrController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadCodes,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.codes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: KasbyColors.primaryGold),
          );
        }

        if (controller.hasError.value && controller.codes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: KasbyColors.error, size: 48),
                const SizedBox(height: 12),
                const Text('تعذّر تحميل الأكواد'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.loadCodes,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (controller.codes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.qrcode,
                  size: 48,
                  color: KasbyColors.primaryGold.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text('لا توجد أكواد إحالة نشطة'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadCodes,
          color: KasbyColors.primaryGold,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                children: [
                  AdminMetricChip(
                    label: 'إجمالي الأكواد',
                    value: '${controller.codes.length}',
                    color: KasbyColors.primaryGold,
                    icon: FontAwesomeIcons.qrcode,
                  ),
                  const SizedBox(width: 10),
                  AdminMetricChip(
                    label: 'وكلاء',
                    value: '${controller.agentCount}',
                    color: KasbyColors.info,
                    icon: FontAwesomeIcons.userTie,
                  ),
                  const SizedBox(width: 10),
                  AdminMetricChip(
                    label: 'مستخدمون',
                    value: '${controller.userCount}',
                    color: KasbyColors.success,
                    icon: FontAwesomeIcons.users,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              KasbyGlassCard(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: controller.selectedCode.value.isEmpty
                      ? null
                      : controller.selectedCode.value,
                  decoration: const InputDecoration(
                    labelText: 'اختر كود الإحالة',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.codes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['code'],
                          child: Text(
                            '${c['label']} • ${c['code']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) => controller.codes
                      .map(
                        (c) => Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            '${c['label']} • ${c['code']}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => controller.selectedCode.value = v ?? '',
                ),
              ),
              const SizedBox(height: 24),
              if (controller.selectedUrl.isNotEmpty) ...[
                KasbyGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: controller.selectedUrl,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        controller.selectedUrl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: KasbyColors.primaryGold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: controller.selectedUrl),
                              );
                              Get.snackbar('تم', 'تم نسخ الرابط');
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('نسخ الرابط'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              final code = controller.selectedCode.value;
                              if (code.isNotEmpty) {
                                Clipboard.setData(ClipboardData(text: code));
                                Get.snackbar('تم', 'تم نسخ الكود');
                              }
                            },
                            icon: const Icon(Icons.tag_rounded, size: 18),
                            label: const Text('نسخ الكود'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}
