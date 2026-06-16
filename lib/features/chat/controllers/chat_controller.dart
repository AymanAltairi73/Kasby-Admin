import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/presence_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/services/app_logger_service.dart';


class ChatController extends GetxController {
  final conversations = <ChatConversation>[].obs;
  final messages = <String, List<ChatMessage>>{}.obs; // conversationId -> list of messages
  final unreadTotal = 0.obs;
  final isTyping = <String, bool>{}.obs; // userId -> isTyping
  final isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString conversationSearchQuery = ''.obs;
  final RxBool isUploading = false.obs;
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> getFilteredMessages(String conversationId) {
    if (searchQuery.isEmpty) return messages[conversationId] ?? [];
    return (messages[conversationId] ?? [])
        .where((m) =>
            m.content.toLowerCase().contains(searchQuery.value.toLowerCase()) &&
            m.type == MessageType.text)
        .toList();
  }

  late AudioService _audioService;
  late PresenceService _presenceService;
  late ChatRepository _chatRepository;
  
  StreamSubscription? _conversationsSubscription;
  final Map<String, RealtimeChannel> _typingChannels = {};
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  Timer? _reconnectTimer;
  Timer? _typingThrottleTimer;
  final Map<String, Timer> _typingTimers = {};

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'ChatController',
      method: 'onInit',
      feature: 'Chat',
      status: 'INFO',
    );
    super.onInit();
    _audioService = Get.find<AudioService>();
    _presenceService = Get.find<PresenceService>();
    _chatRepository = ChatRepository(SupabaseService.client);

    ever(_presenceService.onlineUsers, (_) {
      _updateOnlineStatuses();
    });

    final auth = Get.find<AuthController>();

    ever(auth.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        _initializeChatSystem();
      } else {
        _stopAllStreams();
      }
    });

    if (auth.isLoggedIn.value) {
      _initializeChatSystem();
    }
  }

  bool _isInitialized = false;
  void _initializeChatSystem() {
    if (_isInitialized) return;
    _isInitialized = true;

    AppLoggerService.debugTrace(
      className: 'ChatController',
      method: '_initializeChatSystem',
      feature: 'Chat',
      status: 'INFO',
    );
    loadConversations();
    _startConversationsStream();
  }

  void _stopAllStreams() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _conversationsSubscription?.cancel();
    _conversationsSubscription = null;
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    _messageSubscriptions.clear();
    
    for (var chan in _typingChannels.values) {
      chan.unsubscribe();
    }
    _typingChannels.clear();
    
    for (var t in _typingTimers.values) {
      t.cancel();
    }
    _typingTimers.clear();
    _isInitialized = false;
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'ChatController',
      method: 'onClose',
      feature: 'Chat',
      status: 'INFO',
    );
    _stopAllStreams();
    super.onClose();
  }

  void _updateOnlineStatuses() {
    bool changed = false;
    for (int i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      final isOnline = _presenceService.isUserOnline(conv.userId);
      if (conv.isOnline != isOnline) {
        conversations[i] = conv.copyWith(isOnline: isOnline);
        changed = true;
      }
    }
    if (changed) {
      conversations.refresh();
    }
  }

  List<ChatConversation> get _supportCenterConversations =>
      conversations.where((c) => !c.isSocialChat).toList();

  List<ChatConversation> get agentConversations => _supportCenterConversations
      .where((c) => c.isAgent || c.isAgentChat)
      .toList();

  List<ChatConversation> get userConversations => _supportCenterConversations
      .where((c) => !c.isAgent && !c.isAgentChat)
      .toList();

  Future<void> loadConversations() async {
    AppLoggerService.debugTrace(
      className: 'ChatController',
      method: 'loadConversations',
      feature: 'Chat',
      status: 'INFO',
    );
    try {
      isLoading.value = true;
      final currentUser = SupabaseService.client.auth.currentUser;

      final data = await _chatRepository.getConversations();

      final updatedData = data.map((c) => c.copyWith(
        isOnline: _presenceService.isUserOnline(c.userId)
      )).toList();

      conversations.assignAll(updatedData);
      _calculateUnread();
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'loadConversations',
        feature: 'Chat',
        status: 'SUCCESS',
        params: {'count': conversations.length, 'userId': currentUser?.id ?? ''},
      );
    } catch (e, stackTrace) {
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'loadConversations',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startChatWithUser(String userId) async {
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: KasbyColors.primaryGold),
        ),
        barrierDismissible: false,
      );
      
      final conv = await _chatRepository.getOrCreateConversation(userId);
      await loadConversations(); // Refresh list to include the new/found chat
      
      Get.back(); // close loading dialog
      Get.toNamed('/chat-details', arguments: conv);
      
    } catch (e) {
      Get.back();
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'startChatWithUser',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
      Get.snackbar(
        'خطأ في الاتصال',
        'لم نتمكن من بدء المحادثة، الرجاء المحاولة لاحقاً',
        backgroundColor: KasbyColors.error.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void _startConversationsStream() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _conversationsSubscription?.cancel();
    
    _conversationsSubscription = _chatRepository.streamConversations().listen(
      (event) {
        AppLoggerService.debugTrace(
          className: 'ChatController',
          method: '_startConversationsStream',
          feature: 'Chat',
          status: 'INFO',
          params: {'eventCount': event.length},
        );
        
        // Strategy: Instead of re-fetching EVERYTHING, we update our local list
        // with the new data from the stream, while preserving joined profile data.
        final List<ChatConversation> currentList = List.from(conversations);
        
        for (var row in event) {
          final String id = row['id'] as String;
          final int index = currentList.indexWhere((c) => c.id == id);
          
          if (index != -1) {
            // Update existing conversation PRESERVING profile data (as stream doesn't join)
            final oldConv = currentList[index];
            currentList[index] = oldConv.copyWith(
              lastMessage: row['last_message'],
              lastMessageTime: row['last_message_at'] != null 
                  ? DateTime.parse(row['last_message_at']) 
                  : oldConv.lastMessageTime,
              unreadCount: row['unread_admin_count'] ?? 0,
            );
          } else {
            // New conversation appeared or first load — here we stick to full fetch once
            // to ensure we get the profile data correctly.
            loadConversations();
            return;
          }
        }
        
        // Re-sort current list if needed (since stream is ordered, but copyWith might break visual order if not careful)
        currentList.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        conversations.assignAll(currentList);
        _calculateUnread();
        _updateOnlineStatuses();
      },
      onError: (e) {
        AppLoggerService.debugTrace(
          className: 'ChatController',
          method: '_startConversationsStream',
          feature: 'Chat',
          status: 'FAILED',
          error: e,
        );
        
        if (_reconnectTimer == null) {
          AppLoggerService.debugTrace(
            className: 'ChatController',
            method: '_startConversationsStream',
            feature: 'Chat',
            status: 'WARNING',
            message: 'Connection issue — scheduling retry in 5s',
          );
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            _reconnectTimer = null;
            if (Get.find<AuthController>().isLoggedIn.value) {
              _startConversationsStream();
            }
          });
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TYPING INDICATORS (BROADCAST)
  // ═══════════════════════════════════════════════════════════

  void _setupTypingBroadcast(String conversationId) {
    if (_typingChannels.containsKey(conversationId)) return;

    final channelName = 'typing:$conversationId';
    final channel = SupabaseService.client.channel(channelName);

    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['user_id'] as String?;
        final currentUserId = SupabaseService.auth.currentUser?.id;

        if (userId != null && userId != currentUserId) {
          _handleIncomingTyping(userId);
        }
      },
    ).subscribe((status, error) {
      if (error != null) {
        AppLoggerService.logChatPerformance(
          conversationId: conversationId,
          action: 'typing_channel_error',
          latencyMs: 0,
          severity: 'error',
          details: {'error': error.toString()},
        );
      }
    });

    _typingChannels[conversationId] = channel;
  }

  void _handleIncomingTyping(String userId) {
    // Only show typing if it's for an active conversation or globally relevant
    isTyping[userId] = true;
    isTyping.refresh();

    // Reset timer to auto-clear typing status after 3 seconds of silence
    _typingTimers[userId]?.cancel();
    _typingTimers[userId] = Timer(const Duration(seconds: 3), () {
      isTyping[userId] = false;
      isTyping.refresh();
    });
  }

  /// Call this whenever the admin types in a chat
  void sendTypingEvent(String conversationId) {
    if (_typingThrottleTimer?.isActive ?? false) return;

    final channel = _typingChannels[conversationId];
    if (channel == null) {
      _setupTypingBroadcast(conversationId);
      return;
    }

    channel.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': SupabaseService.auth.currentUser?.id,
      },
    );

    // Throttle broadcast to once every 2 seconds
    _typingThrottleTimer = Timer(const Duration(seconds: 2), () {});
  }

  void listenToMessages(String conversationId) async {
    if (conversationId.isEmpty) return;

    final currentUserId = SupabaseService.auth.currentUser?.id ?? '';
    
    // 1. Fetch initial messages if not already present
    if (!messages.containsKey(conversationId) || messages[conversationId]!.isEmpty) {
      try {
        final initialMessages = await _chatRepository.getMessages(conversationId, currentUserId);
        messages[conversationId] = initialMessages;
        messages.refresh();
      } catch (e) {
        AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'fetchInitialMessages',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
      }
    }

    // 2. Start subscription if not already active
    if (_messageSubscriptions.containsKey(conversationId)) return;
    
    _messageSubscriptions[conversationId] = _chatRepository
        .streamMessages(conversationId)
        .listen(
          (data) {
            final newMessages = data.map((json) => ChatMessage.fromSupabase(json, currentUserId)).toList();
            
            // Check if a new message was received (to play sound)
            if (messages.containsKey(conversationId)) {
              final oldLen = messages[conversationId]!.length;
              if (newMessages.length > oldLen) {
                final lastMsg = newMessages.first;
                if (!lastMsg.isMe) {
                  _audioService.playNotification();
                }
              }
            }

            messages[conversationId] = newMessages;
            messages.refresh();
            _markMessagesDelivered(conversationId);
          },
          onError: (e) {
            AppLoggerService.debugTrace(
              className: 'ChatController',
              method: 'subscribeToMessages',
              feature: 'Chat',
              status: 'FAILED',
              params: {'conversationId': conversationId},
              error: e,
            );
          },
        );
    
    // Also start typing broadcast for this specific conversation
    _setupTypingBroadcast(conversationId);
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
      final index = conversations.indexWhere((c) => c.id == conv.id);
      if (index == -1) {
        conversations.insert(0, conv.copyWith(
          isOnline: _presenceService.isUserOnline(conv.userId),
        ));
      } else {
        conversations[index] = conv.copyWith(
          isOnline: _presenceService.isUserOnline(conv.userId),
        );
      }
      conversations.refresh();
      _calculateUnread();
      return conv.id;
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'ensureConversation',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
      return null;
    }
  }

  /// Routes admin replies to the correct support channel (not social P2P).
  Future<String?> _resolveSupportConversationId(
    String conversationId,
    String? userId,
  ) async {
    if (userId == null || userId.isEmpty) return conversationId;

    if (conversationId.isEmpty) {
      return ensureConversation(userId);
    }

    ChatConversation? conv = conversations.firstWhereOrNull(
      (c) => c.id == conversationId,
    );

    conv ??= await _chatRepository.fetchConversation(conversationId);
    if (conv == null) return ensureConversation(userId);

    if (conv.isSocialChat) {
      return ensureConversation(userId);
    }

    return conversationId;
  }

  Future<String?> sendMessage(String conversationId, String content, {String? userId, MessageType messageType = MessageType.text}) async {
    if (content.trim().isEmpty) return null;
    
    final senderId = SupabaseService.auth.currentUser?.id;
    if (senderId == null) return null;

    String targetConvId = conversationId;

    try {
      final resolvedId = await _resolveSupportConversationId(
        targetConvId,
        userId,
      );
      if (resolvedId == null) throw Exception('Could not resolve support conversation');
      targetConvId = resolvedId;

      if (!messages.containsKey(targetConvId)) {
        listenToMessages(targetConvId);
      }

      if (targetConvId.isEmpty) return null;

      final optimisticMessage = ChatMessage(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: targetConvId,
        senderId: senderId,
        content: content.trim(),
        timestamp: DateTime.now(),
        type: messageType,
        isMe: true,
      );
      
      messages.putIfAbsent(targetConvId, () => []);
      messages[targetConvId]!.insert(0, optimisticMessage);
      messages.refresh();

      _updateLocalConversationPreview(
        targetConvId,
        content.trim(),
        messageType,
      );

      _audioService.playMessageSent();

      final String idempotencyKey = 'msg-${DateTime.now().microsecondsSinceEpoch}-${senderId.substring(0, 5)}';
      
      await _chatRepository.sendMessage(
        conversationId: targetConvId,
        content: content.trim(),
        messageType: messageType,
        idempotencyKey: idempotencyKey,
      );

      return targetConvId;
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'sendMessage',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
      
      AppLoggerService.logChatPerformance(
        conversationId: targetConvId,
        action: 'send_message_failure',
        latencyMs: 0,
        severity: 'critical',
        details: {'error': e.toString()},
      );
      // 4. Rollback Optimistic Update
      if (targetConvId.isNotEmpty && messages.containsKey(targetConvId)) {
        messages[targetConvId]!.removeWhere((m) => m.id.startsWith('temp-'));
        messages.refresh();
      }
      Get.snackbar('خطأ', 'فشل إرسال الرسالة، يرجى المحاولة مرة أخرى.');
      return null;
    }
  }

  void _updateLocalConversationPreview(
    String conversationId,
    String content,
    MessageType messageType,
  ) {
    final preview = messageType == MessageType.image
        ? '📷 صورة'
        : (messageType == MessageType.file ? '📎 ملف' : content);
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    conversations[index] = conversations[index].copyWith(
      lastMessage: preview.length > 100 ? preview.substring(0, 100) : preview,
      lastMessageTime: DateTime.now(),
    );
    conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    conversations.refresh();
  }

  Future<String?> pickAndSendImage(
    String conversationId,
    ImageSource source, {
    String? userId,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
      );

      if (image == null) return null;

      isUploading.value = true;

      final targetConvId = await _resolveSupportConversationId(
        conversationId,
        userId,
      );
      if (targetConvId == null || targetConvId.isEmpty) {
        throw Exception('Could not resolve support conversation');
      }

      if (!messages.containsKey(targetConvId)) {
        listenToMessages(targetConvId);
      }

      final File file = File(image.path);
      final String? imagePath = await _uploadImage(file, targetConvId);

      if (imagePath != null) {
        return sendMessage(
          targetConvId,
          imagePath,
          userId: userId,
          messageType: MessageType.image,
        );
      }
      return null;
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'pickImage',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
      Get.snackbar('خطأ', 'تعذر اختيار الصورة');
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  Future<String?> _uploadImage(File file, String conversationId) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final currentUser = SupabaseService.auth.currentUser;
      final conv = conversations.firstWhereOrNull((c) => c.id == conversationId);
      final folder = conv?.isAgent == true ? 'agents' : 'support';
      final String path = '${currentUser?.id}/$folder/$fileName';

      await SupabaseService.client.storage
          .from('chat_attachments')
          .upload(path, file);
      
      return path;
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'uploadImage',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
      Get.snackbar('خطأ الرفع', 'تعذر رفع الصورة للسيرفر');
      return null;
    }
  }

  void markAsRead(String conversationId) async {
    try {
      await _chatRepository.update(conversationId, {
        'unread_admin_count': 0,
      });
      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        conversations[index] = conversations[index].copyWith(unreadCount: 0);
        conversations.refresh();
      }
      _calculateUnread();
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'markAsRead',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
    }
  }

  Future<void> deleteMessage(String messageId, String conversationId) async {
    try {
      // Optimistic update
      if (messages.containsKey(conversationId)) {
        messages[conversationId]!.removeWhere((m) => m.id == messageId);
        messages.refresh();
      }

      await _chatRepository.deleteMessage(messageId);
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'deleteMessage',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
      Get.snackbar('خطأ', 'فشل حذف الرسالة');
      // Re-fetch messages to restore local state
      listenToMessages(conversationId);
    }
  }

  Future<void> _markMessagesDelivered(String conversationId) async {
    try {
      await SupabaseService.client.rpc(
        'fn_mark_messages_delivered',
        params: {'p_conversation_id': conversationId},
      );
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'markMessagesAsDelivered',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
    }
  }

  Future<void> addReaction(String conversationId, String messageId, String emoji) async {
    try {
      final messageList = messages[conversationId] ?? [];
      final index = messageList.indexWhere((m) => m.id == messageId);
      if (index == -1) return;
      
      final message = messageList[index];
      final newReactions = List<String>.from(message.reactions);

      if (newReactions.contains(emoji)) {
        newReactions.remove(emoji);
      } else {
        newReactions.add(emoji);
      }

      await SupabaseService.client
          .from('chat_messages')
          .update({'reactions': newReactions})
          .eq('id', messageId);
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'ChatController',
        method: 'addReaction',
        feature: 'Chat',
        status: 'FAILED',
        error: e,
      );
      Get.snackbar('خطأ', 'تعذر إضافة التفاعل');
    }
  }
}
