import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
          bottom: TabBar(
            indicatorColor: KasbyColors.primaryGold,
            indicatorWeight: 3,
            labelColor: KasbyColors.primaryGold,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: 'الوكلاء'),
              Tab(text: 'المستخدمين'),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background - Nebula Style
            _buildNebulaBackground(),

            SafeArea(
              child: Column(
                children: [
                  // Top Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: KasbyGlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      opacity: 0.1,
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'البحث عن محادثة...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          icon: const Icon(
                            Icons.search,
                            color: KasbyColors.primaryGold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Conversations Tabs
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

      final filteredList = isAgent
          ? chatController.agentConversations
          : chatController.userConversations;

      if (filteredList.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => chatController.loadConversations(),
          color: KasbyColors.primaryGold,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: Get.height * 0.2),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAgent ? FontAwesomeIcons.userTie : FontAwesomeIcons.users,
                      size: 60,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد محادثات نشطة',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => chatController.loadConversations(),
        color: KasbyColors.primaryGold,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: filteredList.length,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemBuilder: (context, index) {
            final conv = filteredList[index];
            return _buildConversationItem(conv, index);
          },
        ),
      );
    });
  }

  Widget _buildConversationItem(ChatConversation conv, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KasbyGlassCard(
        onTap: () {
          Get.toNamed('/chat-details', arguments: conv);
          Get.find<ChatController>().markAsRead(conv.id);
        },
        padding: const EdgeInsets.all(12),
        opacity: 0.08,
        child: Row(
          children: [
            // Avatar with Glow and Online Indicator
            Stack(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: conv.isOnline
                          ? KasbyColors.success.withValues(alpha: 0.5)
                          : KasbyColors.primaryGold.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (conv.isOnline
                                    ? KasbyColors.success
                                    : KasbyColors.primaryGold)
                                .withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: Text(
                      conv.userName[0],
                      style: const TextStyle(
                        color: KasbyColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                if (conv.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: KasbyColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Name and Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conv.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm', 'ar').format(conv.lastMessageTime),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: conv.unreadCount > 0
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: KasbyColors.error,
                            borderRadius: BorderRadius.circular(10),
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
                ],
              ),
            ),
          ],
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
}
