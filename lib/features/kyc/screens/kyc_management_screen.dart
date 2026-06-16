import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import '../controllers/kyc_controller.dart';
import '../models/kyc_document_model.dart';
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';

/// Simple full-screen image viewer with Zoom
class ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String title;

  const ImageViewerScreen({super.key, required this.imageUrl, required this.title});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  @override
  void initState() {
    super.initState();
    AppLoggerService.debugTrace(
      className: 'ImageViewerScreen',
      method: 'initState',
      feature: 'KYC',
      status: 'INFO',
      message: 'Screen mounted',
    );
  }

  @override
  void dispose() {
    AppLoggerService.debugTrace(
      className: 'ImageViewerScreen',
      method: 'dispose',
      feature: 'KYC',
      status: 'INFO',
      message: 'Screen unmounted',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(color: KasbyColors.primaryGold));
            },
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}

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

class KycDetailsScreen extends StatefulWidget {
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
  State<KycDetailsScreen> createState() => _KycDetailsScreenState();
}

class _KycDetailsScreenState extends State<KycDetailsScreen> {
  @override
  void initState() {
    super.initState();
    AppLoggerService.debugTrace(
      className: 'KycDetailsScreen',
      method: 'initState',
      feature: 'KYC',
      status: 'INFO',
      message: 'Screen mounted',
      params: {
        'userId': widget.userId.length > 8
            ? '${widget.userId.substring(0, 8)}...'
            : widget.userId,
        'documentCount': widget.documents.length,
      },
    );
  }

  @override
  void dispose() {
    AppLoggerService.debugTrace(
      className: 'KycDetailsScreen',
      method: 'dispose',
      feature: 'KYC',
      status: 'INFO',
      message: 'Screen unmounted',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    final userName = widget.userName;
    final documents = widget.documents;
    final controller = Get.find<KycController>();
    final firstDoc = documents.first;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(userName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Details Section
          _buildSectionHeader('بيانات المستخدم'),
          _buildInfoCard([
            _buildInfoRow('الاسم الكامل', userName, Icons.person),
            _buildInfoRow('رقم الهاتف', firstDoc.userPhone ?? 'غير متوفر', Icons.phone, canCopy: true),
            _buildInfoRow('البريد الإلكتروني', firstDoc.userEmail ?? 'غير متوفر', Icons.email, canCopy: true),
          ]),
          
          const SizedBox(height: 32),
          
          _buildSectionHeader('المستندات المرفقة'),
          ...documents.map((doc) => _buildDocumentItem(context, controller, doc)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KasbyColors.primaryGold),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return KasbyGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      opacity: 0.1,
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KasbyColors.primaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: KasbyColors.primaryGold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              ],
            ),
          ),
          if (canCopy && value != 'غير متوفر')
            IconButton(
              icon: Icon(Icons.copy, size: 16, color: Colors.white.withValues(alpha: 0.3)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                Get.snackbar('تم النسخ', 'تم نسخ $label', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(BuildContext context, KycController controller, KycDocument doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeLabel(doc.documentType),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Get.to(() => ImageViewerScreen(imageUrl: doc.documentUrl, title: _docTypeLabel(doc.documentType))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    doc.documentUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Center(child: CircularProgressIndicator(color: KasbyColors.primaryGold)),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('اضغط للتكبير', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
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
  }

  Widget _buildTypeLabel(String type) {
    String label = _docTypeLabel(type);
    IconData icon = FontAwesomeIcons.file;
    
    switch (type) {
      case 'selfie':
        icon = FontAwesomeIcons.camera;
        break;
      case 'id_card_front':
      case 'id_card_back':
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

  String _docTypeLabel(String type) {
    switch (type) {
      case 'selfie': return 'صورة سيلفي الشخصية';
      case 'id_card_front': return 'الهوية من الأمام';
      case 'id_card_back': return 'الهوية من الخلف';
      default: return 'مستند توثيق';
    }
  }

  void _confirmApproval(BuildContext context, KycController controller, KycDocument doc) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تأكيد القبول', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من قبول هذا المستند؟ سيتم تحديث حالة المستخدم تلقائياً.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await controller.updateStatus(
                id: doc.id, 
                status: 'verified',
                userId: doc.userId,
              );
              if (success) {
                Get.snackbar('تم', 'تم قبول المستند وتوثيق الحساب ✅', snackPosition: SnackPosition.BOTTOM, backgroundColor: KasbyColors.success.withValues(alpha: 0.8), colorText: Colors.white);
                if (controller.pendingDocuments.where((d) => d.userId == doc.userId).isEmpty) {
                  Get.back();
                }
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
                userId: doc.userId,
                rejectionReason: reasonController.text,
              );
              if (success) {
                Get.snackbar('تم', 'تم رفض المستند بنجاح ❌', snackPosition: SnackPosition.BOTTOM, backgroundColor: KasbyColors.error.withValues(alpha: 0.8), colorText: Colors.white);
                if (controller.pendingDocuments.where((d) => d.userId == doc.userId).isEmpty) {
                  Get.back();
                }
              }
            },
            child: const Text('تأكيد الرفض', style: TextStyle(color: KasbyColors.error)),
          ),
        ],
      ),
    );
  }
}
