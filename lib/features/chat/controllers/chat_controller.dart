import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/supabase_service.dart';

class ChatController extends GetxController {
  final conversations = <ChatConversation>[].obs;
  final messages = <String, List<ChatMessage>>{}.obs; // conversationId -> list of messages
  final unreadTotal = 0.obs;
  final isTyping = <String, bool>{}.obs; // userId -> isTyping
  final isLoading = false.obs;

  late AudioService _audioService;
  late ChatRepository _chatRepository;
  
  StreamSubscription? _conversationsSubscription;
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  @override
  void onInit() {
    super.onInit();
    _audioService = Get.find<AudioService>();
    _chatRepository = ChatRepository(SupabaseService.client);
    
    debugPrint('[ChatController] ▶ Initializing real-time chat...');
    loadConversations();
    _startConversationsStream();
  }

  @override
  void onClose() {
    _conversationsSubscription?.cancel();
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    super.onClose();
  }

  List<ChatConversation> get agentConversations =>
      conversations.where((c) => c.isAgent).toList();
  List<ChatConversation> get userConversations =>
      conversations.where((c) => !c.isAgent).toList();

  Future<void> loadConversations() async {
    try {
      isLoading.value = true;
      final currentUser = SupabaseService.client.auth.currentUser;
      debugPrint('[ChatController] ▶ Fetching conversations for user: ${currentUser?.id}');
      
      final data = await _chatRepository.getConversations();
      debugPrint('[ChatController] √ Fetched ${data.length} conversations.');
      for (var c in data) {
        debugPrint('  - Conv ID: ${c.id}, User: ${c.userName}, isAgent: ${c.isAgent}');
      }
      conversations.assignAll(data);
      _calculateUnread();
    } catch (e) {
      debugPrint('[ChatController] ✗ Error loading conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _startConversationsStream() {
    _conversationsSubscription?.cancel();
    _conversationsSubscription = _chatRepository.streamConversations().listen((event) {
      // Re-fetch to get profile data (stream doesn't support joins easily)
      loadConversations();
    });
  }

  void listenToMessages(String conversationId) {
    if (conversationId.isEmpty || _messageSubscriptions.containsKey(conversationId)) return;

    final currentUserId = SupabaseService.auth.currentUser?.id ?? '';
    
    _messageSubscriptions[conversationId] = _chatRepository
        .streamMessages(conversationId)
        .listen((data) {
          final newMessages = data.map((json) => ChatMessage.fromSupabase(json, currentUserId)).toList();
          
          // Check if a new message was received (to play sound)
          if (messages.containsKey(conversationId)) {
            final oldLen = messages[conversationId]!.length;
            if (newMessages.length > oldLen) {
              final lastMsg = newMessages.last;
              if (!lastMsg.isMe) {
                _audioService.playNotification();
              }
            }
          }

          messages[conversationId] = newMessages;
          messages.refresh();
        });
  }

  void _calculateUnread() {
    unreadTotal.value = conversations.fold(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  }

  Future<String?> ensureConversation(String userId) async {
    try {
      final conv = await _chatRepository.getOrCreateConversation(userId);
      // Update local list if not present
      if (!conversations.any((c) => c.id == conv.id)) {
        conversations.insert(0, conv);
      }
      return conv.id;
    } catch (e) {
      debugPrint('[ChatController] ✗ Error ensuring conversation: $e');
      return null;
    }
  }

  Future<void> sendMessage(String conversationId, String content, {String? userId}) async {
    if (content.trim().isEmpty) return;
    
    final senderId = SupabaseService.auth.currentUser?.id;
    if (senderId == null) return;

    String targetConvId = conversationId;

    try {
      // If conversationId is empty, we must have a userId to find/create it
      if (targetConvId.isEmpty && userId != null) {
        final newId = await ensureConversation(userId);
        if (newId == null) throw Exception('Could not create conversation');
        targetConvId = newId;
        // Start listening to the new conversation
        listenToMessages(targetConvId);
      }

      if (targetConvId.isEmpty) return;

      // Play sound immediately for UX
      _audioService.playMessageSent();

      await _chatRepository.sendMessage(
        conversationId: targetConvId,
        senderId: senderId,
        content: content,
      );
    } catch (e) {
      debugPrint('[ChatController] ✗ Error sending message: $e');
      Get.snackbar('خطأ', 'فشل إرسال الرسالة');
    }
  }

  void markAsRead(String conversationId) async {
    try {
      await _chatRepository.update(conversationId, {
        'unread_admin_count': 0,
      });
      _calculateUnread();
    } catch (e) {
      debugPrint('[ChatController] ✗ Error marking as read: $e');
    }
  }
}
