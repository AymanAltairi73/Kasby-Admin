import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../controllers/kyc_controller.dart';
import '../models/kyc_document_model.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';

class KycManagementScreen extends StatelessWidget {
  const KycManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(KycController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('توثيق الهوية'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.pendingDocuments.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: KasbyColors.primaryGold));
        }

        if (controller.pendingDocuments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.idCard, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text(
                  'لا توجد طلبات توثيق معلقة',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ],
            ),
          );
        }

        // Group by user
        final groupedDocs = <String, List<KycDocument>>{};
        for (var doc in controller.pendingDocuments) {
          groupedDocs.putIfAbsent(doc.userId, () => []).add(doc);
        }

        final userIds = groupedDocs.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: userIds.length,
          itemBuilder: (context, index) {
            final userId = userIds[index];
            final docs = groupedDocs[userId]!;
            final userName = docs.first.userName ?? 'مستخدم غير معروف';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KasbyGlassCard(
                onTap: () => Get.to(() => KycDetailsScreen(userId: userId, userName: userName, documents: docs)),
                padding: const EdgeInsets.all(16),
                opacity: 0.08,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: KasbyColors.primaryGold.withValues(alpha: 0.1),
                      child: const Icon(FontAwesomeIcons.user, color: KasbyColors.primaryGold, size: 16),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'لديه ${docs.length} مستندات بانتظار المراجعة',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class KycDetailsScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final List<KycDocument> documents;

  const KycDetailsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KycController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(userName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeLabel(doc.documentType),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    doc.documentUrl,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Center(child: CircularProgressIndicator(color: KasbyColors.primaryGold)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Center(child: Icon(Icons.error_outline, color: KasbyColors.error)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KasbyColors.success.withValues(alpha: 0.1),
                          foregroundColor: KasbyColors.success,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmApproval(context, controller, doc),
                        child: const Text('قبول المستند', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KasbyColors.error.withValues(alpha: 0.1),
                          foregroundColor: KasbyColors.error,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmRejection(context, controller, doc),
                        child: const Text('رفض المستند', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeLabel(String type) {
    String label = '';
    IconData icon = FontAwesomeIcons.file;
    
    switch (type) {
      case 'selfie':
        label = 'صورة سيلفي الشخصية';
        icon = FontAwesomeIcons.camera;
        break;
      case 'id_card_front':
        label = 'الهوية من الأمام';
        icon = FontAwesomeIcons.idCard;
        break;
      case 'id_card_back':
        label = 'الهوية من الخلف';
        icon = FontAwesomeIcons.idCard;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: KasbyColors.primaryGold, size: 14),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  void _confirmApproval(BuildContext context, KycController controller, KycDocument doc) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تأكيد القبول', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من قبول هذا المستند؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await controller.updateStatus(id: doc.id, status: 'verified');
              if (success) {
                Get.snackbar('تم', 'تم قبول المستند بنجاح', snackPosition: SnackPosition.BOTTOM, backgroundColor: KasbyColors.success.withValues(alpha: 0.8), colorText: Colors.white);
                if (documents.length <= 1) Get.back();
              }
            },
            child: const Text('نعم، قبول', style: TextStyle(color: KasbyColors.success)),
          ),
        ],
      ),
    );
  }

  void _confirmRejection(BuildContext context, KycController controller, KycDocument doc) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('رفض المستند', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى ذكر سبب الرفض ليتمكن المستخدم من تعديله:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'مثلاً: الصورة غير واضحة...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                Get.snackbar('خطأ', 'يرجى كتابة سبب الرفض', backgroundColor: KasbyColors.error);
                return;
              }
              Get.back();
              final success = await controller.updateStatus(
                id: doc.id, 
                status: 'rejected', 
                rejectionReason: reasonController.text,
              );
              if (success) {
                Get.snackbar('تم', 'تم رفض المستند بنجاح', snackPosition: SnackPosition.BOTTOM, backgroundColor: KasbyColors.error.withValues(alpha: 0.8), colorText: Colors.white);
                if (documents.length <= 1) Get.back();
              }
            },
            child: const Text('تأكيد الرفض', style: TextStyle(color: KasbyColors.error)),
          ),
        ],
      ),
    );
  }
}
