import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'مركز المحادثات',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Obx(() {
              final agentUnread = chatController.agentConversations
                  .fold<int>(0, (sum, c) => sum + c.unreadCount);
              final userUnread = chatController.userConversations
                  .fold<int>(0, (sum, c) => sum + c.unreadCount);

              return TabBar(
                indicatorColor: KasbyColors.primaryGold,
                indicatorWeight: 3,
                labelColor: KasbyColors.primaryGold,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('الوكلاء'),
                        if (agentUnread > 0) ...[
                          const SizedBox(width: 6),
                          _buildTabBadge(agentUnread),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('المستخدمين'),
                        if (userUnread > 0) ...[
                          const SizedBox(width: 6),
                          _buildTabBadge(userUnread),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        body: Stack(
          children: [
            _buildNebulaBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Obx(() => _buildStatsRow(chatController)),
                  ),
                  _buildSearchField(chatController),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildConversationList(chatController, isAgent: true),
                        _buildConversationList(chatController, isAgent: false),
                      ],
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

  Widget _buildTabBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: KasbyColors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsRow(ChatController chatController) {
    final agentCount = chatController.agentConversations.length;
    final userCount = chatController.userConversations.length;
    final onlineCount = chatController.conversations.where((c) => c.isOnline).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            icon: FontAwesomeIcons.comments,
            label: 'إجمالي المحادثات',
            value: '${agentCount + userCount}',
            color: KasbyColors.primaryGold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            icon: FontAwesomeIcons.circle,
            label: 'متصل الآن',
            value: '$onlineCount',
            color: KasbyColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            icon: FontAwesomeIcons.envelope,
            label: 'غير مقروء',
            value: '${chatController.unreadTotal.value}',
            color: KasbyColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return KasbyGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ChatController chatController) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: KasbyGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        opacity: 0.1,
        child: _ChatSearchField(chatController: chatController),
      ),
    );
  }

  Widget _buildConversationList(
    ChatController chatController, {
    required bool isAgent,
  }) {
    return Obx(() {
      if (chatController.isLoading.value && chatController.conversations.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: KasbyColors.primaryGold),
        );
      }

      var filteredList = isAgent
          ? chatController.agentConversations
          : chatController.userConversations;

      final query = chatController.conversationSearchQuery.value.trim().toLowerCase();
      if (query.isNotEmpty) {
        filteredList = filteredList
            .where(
              (c) =>
                  c.userName.toLowerCase().contains(query) ||
                  c.lastMessage.toLowerCase().contains(query),
            )
            .toList();
      }

      if (filteredList.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: Get.height * 0.15),
            Center(
              child: Column(
                children: [
                  Icon(
                    isAgent ? FontAwesomeIcons.userTie : FontAwesomeIcons.users,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    query.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد محادثات نشطة',
                    style: const TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: filteredList.length,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final conv = filteredList[index];
          return _buildConversationItem(conv);
        },
      );
    });
  }

  Widget _buildConversationItem(ChatConversation conv) {
    final hasUnread = conv.unreadCount > 0;
    final isImagePreview = conv.lastMessage.contains('📷') ||
        conv.lastMessage.endsWith('.jpg') ||
        conv.lastMessage.endsWith('.png');

    return KasbyGlassCard(
      onTap: () {
        Get.toNamed('/chat-details', arguments: conv);
        Get.find<ChatController>().markAsRead(conv.id);
      },
      padding: const EdgeInsets.all(14),
      opacity: hasUnread ? 0.12 : 0.07,
      borderColor: hasUnread
          ? KasbyColors.primaryGold.withValues(alpha: 0.25)
          : null,
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: conv.isOnline
                        ? KasbyColors.success.withValues(alpha: 0.6)
                        : KasbyColors.primaryGold.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  backgroundImage: (conv.userAvatar != null &&
                          conv.userAvatar!.isNotEmpty)
                      ? CachedNetworkImageProvider(conv.userAvatar!)
                      : null,
                  child: (conv.userAvatar == null || conv.userAvatar!.isEmpty)
                      ? Text(
                          conv.userName.isNotEmpty ? conv.userName[0] : '?',
                          style: const TextStyle(
                            color: KasbyColors.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
              ),
              if (conv.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: KasbyColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F172A), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conv.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: hasUnread ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      _formatListTime(conv.lastMessageTime),
                      style: TextStyle(
                        color: hasUnread
                            ? KasbyColors.primaryGold
                            : Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (conv.isAgent)
                      _buildMiniTag('وكيل', KasbyColors.glowOrange),
                    if (conv.isAgentChat)
                      _buildMiniTag('P2P', KasbyColors.info),
                    if (conv.isAgent || conv.isAgentChat) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isImagePreview ? '📷 صورة' : conv.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasUnread
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              KasbyColors.error,
                              KasbyColors.error.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${conv.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  conv.isOnline ? 'نشط الآن' : _formatLastSeenInList(conv.lastSeenAt),
                  style: TextStyle(
                    color: conv.isOnline
                        ? KasbyColors.success
                        : Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNebulaBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF0F172A)],
        ),
      ),
    );
  }

  String _formatListTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return DateFormat('HH:mm', 'ar').format(time);
    }
    if (now.difference(time).inDays < 7) {
      return DateFormat('EEEE', 'ar').format(time);
    }
    return DateFormat('d/M', 'ar').format(time);
  }

  String _formatLastSeenInList(DateTime? lastSeen) {
    if (lastSeen == null) return 'غير متصل';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 5) return 'نشط مؤخراً';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes}د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours}س';
    return DateFormat('d/M', 'ar').format(lastSeen);
  }
}

class _ChatSearchField extends StatefulWidget {
  final ChatController chatController;

  const _ChatSearchField({required this.chatController});

  @override
  State<_ChatSearchField> createState() => _ChatSearchFieldState();
}

class _ChatSearchFieldState extends State<_ChatSearchField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.chatController.conversationSearchQuery.value,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasQuery =
          widget.chatController.conversationSearchQuery.value.isNotEmpty;
      return TextField(
        controller: _textController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'البحث بالاسم أو آخر رسالة...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          icon: const Icon(
            Icons.search,
            color: KasbyColors.primaryGold,
          ),
          suffixIcon: hasQuery
              ? GestureDetector(
                  onTap: () {
                    _textController.clear();
                    widget.chatController.conversationSearchQuery.value = '';
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                )
              : null,
        ),
        onChanged: (value) {
          widget.chatController.conversationSearchQuery.value = value;
        },
      );
    });
  }
}
