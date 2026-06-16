import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/agent_controller.dart';
import '../models/agent_model.dart';
import '../../chat/screens/chat_details_screen.dart';
import '../../chat/models/chat_model.dart';

class AgentDetailsScreen extends StatefulWidget {
  const AgentDetailsScreen({super.key});

  @override
  State<AgentDetailsScreen> createState() => _AgentDetailsScreenState();
}

class _AgentDetailsScreenState extends State<AgentDetailsScreen> {
  late Agent _agent;
  bool _isLoading = true;
  String _referralCode = '';

  @override
  void initState() {
    super.initState();
    _agent = Get.arguments as Agent;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final controller = Get.isRegistered<AgentController>()
        ? Get.find<AgentController>()
        : Get.put(AgentController());

    final fresh = await controller.fetchAgentDetails(_agent.id);
    String referral = '';
    if (fresh != null) {
      try {
        final profile = await SupabaseService.client
            .from('profiles')
            .select('referral_code')
            .eq('id', fresh.userId)
            .maybeSingle();
        referral = profile?['referral_code']?.toString() ?? '';
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      if (fresh != null) _agent = fresh;
      _referralCode = referral;
      _isLoading = false;
    });
  }

  bool _isActive(String status) =>
      status.toLowerCase() == 'active' || status == 'Active';

  @override
  Widget build(BuildContext context) {
    final agent = _agent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => safePop(null, context),
        ),
        title: const Text(
          'تفاصيل الوكيل',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: KasbyColors.primaryGold),
            onPressed: () => Get.toNamed('/edit-agent', arguments: agent),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildCelestialBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: KasbyColors.primaryGold),
                  )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  KasbyGlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: KasbyColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    agent.name.isNotEmpty ? agent.name[0] : '؟',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E293B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isActive(agent.status)
                                        ? Icons.check_circle_rounded
                                        : Icons.block_rounded,
                                    color: _isActive(agent.status)
                                        ? KasbyColors.success
                                        : KasbyColors.error,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: KasbyColors.primaryGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${agent.city}, ${agent.country}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatusBadge(agent.status),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Overview
                  const Text(
                    'نظرة عامة على الأداء',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: KasbyColors.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    label: 'إجمالي المعاملات المكتملة',
                    value: agent.totalTransactions.toString(),
                    icon: FontAwesomeIcons.arrowRightArrowLeft,
                    color: KasbyColors.info,
                  ),

                  const SizedBox(height: 24),

                  // Contact & Details Section
                  const Text(
                    'معلومات التواصل والبيانات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: KasbyColors.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  KasbyGlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow('البريد الإلكتروني', agent.email, Icons.alternate_email_rounded),
                        if (_referralCode.isNotEmpty) ...[
                          const Divider(color: Colors.white10, height: 24),
                          _buildInfoRow('كود الإحالة', _referralCode, Icons.qr_code_rounded),
                        ],
                        if (agent.supportedMethods.isNotEmpty) ...[
                          const Divider(color: Colors.white10, height: 24),
                          _buildInfoRow(
                            'قنوات الدعم',
                            agent.supportedMethods.join(' • '),
                            Icons.headset_mic_rounded,
                          ),
                        ],
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow('رقم الهاتف', agent.phone, Icons.phone_android_rounded),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow('المحافظة', agent.province.isNotEmpty ? agent.province : 'غير محدد', Icons.map_rounded),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow('العنوان', agent.address.isNotEmpty ? agent.address : 'غير محدد', Icons.location_on_rounded),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(
                          'تاريخ الانضمام',
                          DateFormat('dd MMMM yyyy', 'ar').format(agent.createdAt),
                          Icons.calendar_month_rounded,
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 24),

                  // Quick Communication Section
                  const Text(
                    'قنوات التواصل المباشر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: KasbyColors.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  KasbyGlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCommAction(
                              icon: FontAwesomeIcons.whatsapp,
                              color: const Color(0xFF25D366),
                              label: 'واتساب',
                              onPressed: () => _launchService(
                                'https://wa.me/${agent.whatsapp.replaceAll('+', '')}',
                                'يرجى التأكد من تثبيت واتساب',
                              ),
                            ),
                            _buildCommAction(
                              icon: FontAwesomeIcons.telegram,
                              color: const Color(0xFF24A1DE),
                              label: 'تليجرام',
                              onPressed: () => _launchService(
                                agent.telegram.startsWith('http')
                                    ? agent.telegram
                                    : 'https://t.me/${agent.telegram.replaceAll('@', '')}',
                                'يرجى التأكد من تثبيت تليجرام',
                              ),
                            ),
                            _buildCommAction(
                              icon: Icons.phone_forwarded_rounded,
                              color: KasbyColors.info,
                              label: 'اتصال',
                              onPressed: () => _launchService('tel:${agent.phone}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  KasbyColors.primaryGold.withValues(alpha: 0.2),
                                  KasbyColors.primaryGold.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                // Navigate to instant chat
                                Get.to(
                                  () => const ChatDetailsScreen(),
                                  arguments: ChatConversation(
                                    id: '', // Empty ID signifies a potentially new conversation
                                    userId: agent.userId, // UPDATED: Using userId corresponding to profiles.id
                                    userName: agent.name,
                                    lastMessage: 'بدء محادثة جديدة',
                                    lastMessageTime: DateTime.now(),
                                    isOnline: true,
                                    isAgent: true,
                                  ),
                                );
                              },
                              icon: const Icon(
                                FontAwesomeIcons.commentDots,
                                color: KasbyColors.primaryGold,
                              ),
                              label: const Text(
                                'بدء دردشة فورية',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStatusBadge(String status) {
    final isActive = _isActive(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? KasbyColors.success.withValues(alpha: 0.1)
            : KasbyColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? KasbyColors.success.withValues(alpha: 0.3)
              : KasbyColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isActive ? 'نشط' : 'معطل',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isActive ? KasbyColors.success : KasbyColors.error,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: KasbyColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: KasbyColors.primaryGold),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '---',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  Widget _buildCommAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchService(String url, [String? errorMsg]) async {
    final uri = Uri.parse(url);
    try {
      // Try launching first as externalApplication
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback or error snackbar
        Get.snackbar('تنبيه', errorMsg ?? 'لا يمكن فتح الرابط وتأكد من تثبيت التطبيق المطلوب');
      }
    } catch (e) {
      debugPrint('Launch error: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء محاولة الاتصال، تأكد من تثبيت التطبيق');
    }
  }

  Widget _buildCelestialBackground() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: _buildOrb(400, KasbyColors.primaryGold.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: _buildOrb(500, KasbyColors.info.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
        ],
      ),
    );
  }
}
