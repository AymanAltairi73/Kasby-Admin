import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';

class ChatDetailsScreen extends StatefulWidget {
  const ChatDetailsScreen({super.key});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatConversation conversation;
  late ChatController chatController;

  @override
  void initState() {
    super.initState();
    conversation = Get.arguments as ChatConversation;
    chatController = Get.find<ChatController>();

    // Jump to bottom on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
                // Messages Area
                Expanded(
                  child: Obx(() {
                    final messages =
                        chatController.messages[conversation.userId] ?? [];
                    final isTyping =
                        chatController.isTyping[conversation.userId] ?? false;

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return _buildTypingIndicator();
                        }

                        final msg = messages[index];
                        final showDateHeader =
                            index == 0 ||
                            !_isSameDay(
                              msg.timestamp,
                              messages[index - 1].timestamp,
                            );

                        return Column(
                          children: [
                            if (showDateHeader) _buildDateHeader(msg.timestamp),
                            _buildChatBubble(msg, index),
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
                    child: Text(
                      conversation.userName[0],
                      style: const TextStyle(
                        color: KasbyColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Obx(() {
                      final isTyping =
                          chatController.isTyping[conversation.userId] ?? false;
                      return Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isTyping || conversation.isOnline
                                  ? KasbyColors.success
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTyping
                                ? 'يكتب الآن...'
                                : (conversation.isOnline
                                      ? 'نشط الآن'
                                      : 'غير متصل'),
                            style: TextStyle(
                              fontSize: 10,
                              color: isTyping
                                  ? KasbyColors.success
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.call_rounded, color: Colors.white70),
                onPressed: () {
                  Get.snackbar(
                    'اتصال صوتي',
                    'جاري بدء اتصال صوتي مع ${conversation.userName}...',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.videocam_rounded, color: Colors.white70),
                onPressed: () {
                  Get.snackbar(
                    'اتصال مرئي',
                    'جاري بدء اتصال مرئي مع ${conversation.userName}...',
                  );
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Column(
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
                child: Text(
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
                      size: 12,
                      color: KasbyColors.primaryGold.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ],
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
            onPressed: () {},
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
      chatController.sendMessage(conversation.userId, _messageController.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Widget _buildNebulaBackground() {
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
}
