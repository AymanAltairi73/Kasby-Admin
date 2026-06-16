import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../core/services/app_logger_service.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/services/supabase_service.dart';

/// Full-page Notifications Viewer — shows all notifications from DB
class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  final _notifications = <Map<String, dynamic>>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await AppLoggerService.traceAsync(
      className: 'NotificationsListScreen',
      method: '_loadNotifications',
      feature: 'Notifications',
      operation: () async {
        setState(() => _isLoading = true);
        try {
          final response = await SupabaseService.client
              .from('notifications')
              .select('id, title, message, status, sent_at, target')
              .order('sent_at', ascending: false)
              .limit(100);

          setState(() {
            _notifications
              ..clear()
              ..addAll((response as List).cast<Map<String, dynamic>>());
          });
          return _notifications.length;
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      onSuccessParams: (count) => {'count': count},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.02),
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'الإشعارات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: KasbyColors.primaryGold),
                  tooltip: 'إضافة إشعار',
                  onPressed: () => Get.toNamed('/add-notification'),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              color: KasbyColors.primaryGold,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: KasbyColors.primaryGold),
                    )
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_outlined,
                  color: Colors.white.withValues(alpha: 0.15),
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'لا توجد إشعارات',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم عرض الإشعارات المرسلة هنا',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList() {
    // Group by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var n in _notifications) {
      final sentAt = DateTime.tryParse(n['sent_at'] ?? '') ?? DateTime.now();
      final dateKey = _getDateLabel(sentAt);
      grouped.putIfAbsent(dateKey, () => []).add(n);
    }

    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: dateKeys.length,
      itemBuilder: (context, sectionIndex) {
        final dateLabel = dateKeys[sectionIndex];
        final items = grouped[dateLabel]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                ],
              ),
            ),
            // Notification Items
            ...items.map((n) => _buildNotificationCard(n)),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final sentAt = DateTime.tryParse(n['sent_at'] ?? '') ?? DateTime.now();
    final isNew = n['status'] == 'sent' || n['status'] == 'unread';
    final target = n['target'] ?? 'all';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: KasbyGlassCard(
        padding: const EdgeInsets.all(14),
        opacity: isNew ? 0.12 : 0.06,
        borderColor: isNew ? KasbyColors.primaryGold.withValues(alpha: 0.15) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isNew
                    ? KasbyColors.primaryGold.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTargetIcon(target),
                color: isNew ? KasbyColors.primaryGold : Colors.white30,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n['title'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: isNew ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(sentAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['message'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Target badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getTargetColor(target).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTargetText(target),
                      style: TextStyle(
                        color: _getTargetColor(target),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTargetIcon(String target) {
    switch (target) {
      case 'all':
        return Icons.groups_rounded;
      case 'active':
        return Icons.person_rounded;
      case 'investors':
        return Icons.trending_up_rounded;
      case 'agents':
        return Icons.support_agent_rounded;
      case 'specific':
        return Icons.person_pin_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTargetColor(String target) {
    switch (target) {
      case 'all':
        return KasbyColors.primaryGold;
      case 'active':
        return KasbyColors.success;
      case 'investors':
        return KasbyColors.info;
      case 'agents':
        return Colors.orangeAccent;
      case 'specific':
        return Colors.purpleAccent;
      default:
        return KasbyColors.primaryGold;
    }
  }

  String _getTargetText(String target) {
    switch (target) {
      case 'all':
        return 'جميع المستخدمين';
      case 'active':
        return 'النشطون';
      case 'investors':
        return 'المستثمرون';
      case 'agents':
        return 'الوكلاء';
      case 'specific':
        return 'مستخدم محدد';
      default:
        return 'الجميع';
    }
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'اليوم';
    if (dateOnly == yesterday) return 'أمس';
    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF0F172A)),
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  KasbyColors.primaryGold.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}
