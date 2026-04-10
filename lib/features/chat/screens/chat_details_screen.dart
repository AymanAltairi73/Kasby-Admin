import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/chat_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/chat_model.dart';
import 'package:flutter/services.dart';

class ChatDetailsScreen extends StatefulWidget {
  const ChatDetailsScreen({super.key});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatConversation conversation;
  late ChatController chatController;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    conversation = Get.arguments as ChatConversation;
    chatController = Get.find<ChatController>();

    if (conversation.id.isNotEmpty) {
      chatController.listenToMessages(conversation.id);
    } else {
      // Fallback for new conversations: try to find/create it
      _initializeNewConversation();
    }
  }

  Future<void> _initializeNewConversation() async {
    final newId = await chatController.ensureConversation(conversation.userId);
    if (newId != null) {
      setState(() {
        conversation = chatController.conversations.firstWhere((c) => c.id == newId);
      });
      chatController.listenToMessages(newId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildMagicalAppBar(),
      body: Stack(
        children: [
          // Background
          _buildNebulaBackground(),

          SafeArea(
            child: Column(
              children: [
                if (_showSearch) _buildSearchBar(),
                // Messages Area
                Expanded(
                  child: Obx(() {
                    final messages = chatController.getFilteredMessages(conversation.id);
                    final isTyping =
                        chatController.isTyping[conversation.userId] ?? false;

                    return ListView.builder(
                      reverse: true, // Newest at bottom
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        // In reverse mode, index 0 is at the bottom
                        if (isTyping && index == 0) {
                          return _buildTypingIndicator();
                        }

                        final msgIndex = isTyping ? index - 1 : index;
                        final msg = messages[msgIndex];
                        
                        // Date header logic: show if it's the TOP-MOST message of the list
                        // or the first message of a new day (looking top-to-bottom)
                        // Note: index N is Top, index 0 is Bottom.
                        final bool showDateHeader = msgIndex == messages.length - 1 || 
                          !_isSameDay(msg.timestamp, messages[msgIndex + 1].timestamp);

                        return Column(
                          children: [
                            if (showDateHeader) _buildDateHeader(msg.timestamp),
                            _buildChatBubble(msg, msgIndex),
                          ],
                        );
                      },
                    );
                  }),
                ),

                // Input Area
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: KasbyGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        opacity: 0.05,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ابحث في الرسائل...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white30),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white30),
              onPressed: () {
                _searchController.clear();
                chatController.searchQuery.value = '';
                setState(() => _showSearch = false);
              },
            ),
          ),
          onChanged: (value) => chatController.searchQuery.value = value,
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.5, end: 0);
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    String label = DateFormat('yMMMMd', 'ar').format(date);
    final now = DateTime.now();
    if (_isSameDay(date, now)) label = 'اليوم';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) label = 'أمس';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: KasbyColors.primaryGold,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMagicalAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.02),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Get.back(),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: KasbyColors.primaryGold.withValues(
                      alpha: 0.2,
                    ),
                    backgroundImage: (conversation.userAvatar != null && conversation.userAvatar!.isNotEmpty)
                        ? CachedNetworkImageProvider(conversation.userAvatar!)
                        : null,
                    child: (conversation.userAvatar == null || conversation.userAvatar!.isEmpty)
                        ? Text(
                            conversation.userName[0],
                            style: const TextStyle(
                              color: KasbyColors.primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          conversation.userName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() {
                        final currentConv = chatController.conversations.firstWhere(
                          (c) => c.id == conversation.id,
                          orElse: () => conversation,
                        );
                        final isTyping = chatController.isTyping[conversation.userId] ?? false;
                        
                        return _buildStatusBadge(
                          isOnline: currentConv.isOnline,
                          isTyping: isTyping,
                          lastSeen: currentConv.lastSeenAt,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // IconButton(
              //   icon: const Icon(Icons.call_rounded, color: Colors.white70),
              //   onPressed: () {
              //     Get.snackbar(
              //       'اتصال صوتي',
              //       'جاري بدء اتصال صوتي مع ${conversation.userName}...',
              //     );
              //   },
              // ),
              IconButton(
                icon: Icon(
                  _showSearch ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() => _showSearch = !_showSearch);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white70,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, int index) {
    if (msg.isDeleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_flipped, size: 12, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(width: 8),
                Text(
                  'message_deleted'.tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _showMessageActions(msg),
            child: Column(
              crossAxisAlignment: msg.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isMe
                        ? KasbyColors.primaryGold.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(msg.isMe ? 20 : 5),
                      bottomRight: Radius.circular(msg.isMe ? 5 : 20),
                    ),
                    border: Border.all(
                      color: msg.isMe
                          ? KasbyColors.primaryGold.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: msg.type == MessageType.image
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: msg.content,
                            placeholder: (context, url) => Container(
                              width: 150,
                              height: 150,
                              color: Colors.white.withValues(alpha: 0.05),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, e) => const Icon(Icons.error_outline),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          msg.content,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('HH:mm', 'ar').format(msg.timestamp),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    if (msg.isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: msg.readAt != null
                            ? KasbyColors.primaryGold
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(ChatMessage msg) {
    Get.bottomSheet(
      KasbyGlassCard(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                title: const Text('نسخ النص', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.content));
                  Get.back();
                  Get.snackbar('تم النسخ', 'تم نسخ الرسالة إلى الحافظة');
                },
              ),
            // Allow admin to delete ANY message for moderation, not just their own
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('حذف الرسالة', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Get.back();
                Get.dialog(
                  AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1E),
                    title: const Text('حذف الرسالة', style: TextStyle(color: Colors.white)),
                    content: const Text('هل أنت متأكد من حذف هذه الرسالة؟ لا يمكن التراجع عن هذا الإجراء.', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.white30)),
                      ),
                      TextButton(
                        onPressed: () {
                          chatController.deleteMessage(msg.id, conversation.id);
                          Get.back();
                        },
                        child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _showImageSourceSheet() {
    Get.bottomSheet(
      KasbyGlassCard(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'إرفاق صورة',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'الكاميرا',
                  onTap: () {
                    Get.back();
                    chatController.pickAndSendImage(conversation.id, ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'المعرض',
                  onTap: () {
                    Get.back();
                    chatController.pickAndSendImage(conversation.id, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KasbyColors.primaryGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: KasbyColors.primaryGold.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: KasbyColors.primaryGold, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }


  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add_photo_alternate_rounded,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            onPressed: _showImageSourceSheet,
          ),
          Expanded(
            child: KasbyGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              opacity: 0.1,
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      chatController.sendTypingEvent(conversation.id);
                    }
                  },
                  onSubmitted: (_) => _handleSend(),
                ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: KasbyColors.primaryGold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.black),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    if (_messageController.text.isNotEmpty) {
      chatController.sendMessage(
        conversation.id,
        _messageController.text,
        userId: conversation.userId,
      );
      _messageController.clear();
    }
  }

  Widget _buildNebulaBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0E0E11),
            const Color(0xFF0E0E11).withValues(alpha: 0.8),
            KasbyColors.primaryGold.withValues(alpha: 0.05),
            const Color(0xFF0E0E11),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle dots pattern
          Opacity(
            opacity: 0.03,
            child: CustomPaint(
              size: Size.infinite,
              painter: GridPainter(),
            ),
          ),
        ],
      ),
    );
  }
  String _formatLastSeen(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return 'غير متصل';
    final now = DateTime.now();
    final diff = now.difference(lastSeenAt);

    if (diff.inMinutes < 1) return 'منذ قليل';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';

    return 'في ${DateFormat('MMM d', 'ar').format(lastSeenAt)}';
  }

  Widget _buildStatusBadge({
    required bool isOnline,
    required bool isTyping,
    DateTime? lastSeen,
  }) {
    final color = (isOnline || isTyping) ? KasbyColors.success : Colors.white24;
    final text = isTyping 
        ? 'يكتب الآن...' 
        : (isOnline ? 'نشط الآن' : 'آخر ظهور ${_formatLastSeen(lastSeen)}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                if (isOnline || isTyping)
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KasbyColors.primaryGold
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
