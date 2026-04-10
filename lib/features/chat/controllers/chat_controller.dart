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
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  RealtimeChannel? _typingChannel;
  Timer? _reconnectTimer;
  Timer? _typingThrottleTimer;
  final Map<String, Timer> _typingTimers = {};

  @override
  void onInit() {
    super.onInit();
    _audioService = Get.find<AudioService>();
    _presenceService = Get.find<PresenceService>();
    _chatRepository = ChatRepository(SupabaseService.client);
    
    debugPrint('[ChatController] ▶ Initializing ChatController...');

    // Listen to presence changes to update online status
    ever(_presenceService.onlineUsers, (_) {
      _updateOnlineStatuses();
    });

    // Wait for authentication before starting real-time features
    final auth = Get.find<AuthController>();
    
    ever(auth.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        debugPrint('[ChatController] ▶ Authenticated. Starting streams...');
        loadConversations();
        _startConversationsStream();
        _setupTypingBroadcast();
      } else {
        debugPrint('[ChatController] ℹ Logged out. Stopping streams...');
        _stopAllStreams();
      }
    });

    if (auth.isLoggedIn.value) {
      loadConversations();
      _startConversationsStream();
      _setupTypingBroadcast();
    }
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
    
    _typingChannel?.unsubscribe();
    _typingChannel = null;
    
    for (var t in _typingTimers.values) {
      t.cancel();
    }
    _typingTimers.clear();
  }

  @override
  void onClose() {
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
      
      // Update with current online status
      final updatedData = data.map((c) => c.copyWith(
        isOnline: _presenceService.isUserOnline(c.userId)
      )).toList();
      
      conversations.assignAll(updatedData);
      _calculateUnread();
    } catch (e) {
      debugPrint('[ChatController] ✗ Error loading conversations: $e');
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
      Get.back(); // close loading dialog
      debugPrint('[ChatController] ✗ Error starting chat: $e');
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
        // Re-fetch to get profile data (stream doesn't support joins easily)
        loadConversations();
      },
      onError: (e) {
        debugPrint('[ChatController] ✗ Conversations stream error: $e');
        
        if (_reconnectTimer == null) {
          debugPrint('[ChatController] ℹ Connection issue. Scheduling retry in 5s...');
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            _reconnectTimer = null;
            if (Get.find<AuthController>().isLoggedIn.value) {
              _startConversationsStream();
            }
          });
        }
        
        AppLoggerService.logChatPerformance(
          conversationId: 'global',
          action: 'stream_error',
          latencyMs: 0,
          severity: 'error',
          details: {'error': e.toString()},
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TYPING INDICATORS (BROADCAST)
  // ═══════════════════════════════════════════════════════════

  void _setupTypingBroadcast() {
    final channelName = 'chat_typing';
    _typingChannel = SupabaseService.client.channel(channelName);

    _typingChannel!.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['user_id'] as String?;
        final conversationId = payload['conversation_id'] as String?;
        final currentUserId = SupabaseService.auth.currentUser?.id;

        if (userId != null &&
            conversationId != null &&
            userId != currentUserId) {
          _handleIncomingTyping(userId, conversationId);
        }
      },
    ).subscribe((status, error) {
      if (error != null || status == 'CLOSED' || status == 'CHANNEL_ERROR') {
        AppLoggerService.logChatPerformance(
          conversationId: 'global',
          action: 'typing_channel_status',
          latencyMs: 0,
          severity: error != null ? 'error' : 'warning',
          details: {
            'status': status,
            'error': error?.toString(),
          },
        );
      }
    });
  }

  void _handleIncomingTyping(String userId, String conversationId) {
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

    final currentUserId = SupabaseService.auth.currentUser?.id;
    if (currentUserId == null) return;

    _typingChannel?.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': currentUserId,
        'conversation_id': conversationId,
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
        debugPrint('[ChatController] ✗ Error fetching initial messages: $e');
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
                final lastMsg = newMessages.last;
                if (!lastMsg.isMe) {
                  _audioService.playNotification();
                }
              }
            }

            messages[conversationId] = newMessages;
            messages.refresh();
          },
          onError: (e) {
            debugPrint('[ChatController] ✗ Messages stream error ($conversationId): $e');
            AppLoggerService.logChatPerformance(
              conversationId: conversationId,
              action: 'message_stream_error',
              latencyMs: 0,
              severity: 'error',
              details: {'error': e.toString()},
            );
          },
        );
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

  Future<void> sendMessage(String conversationId, String content, {String? userId, MessageType messageType = MessageType.text}) async {
    if (content.trim().isEmpty) return;
    
    final senderId = SupabaseService.auth.currentUser?.id;
    if (senderId == null) return;

    String targetConvId = conversationId;

    try {
      // 1. If conversationId is empty, we must have a userId to find/create it
      if (targetConvId.isEmpty && userId != null) {
        final newId = await ensureConversation(userId);
        if (newId == null) throw Exception('Could not create conversation');
        targetConvId = newId;
        // Start listening to the new conversation
        listenToMessages(targetConvId);
      }

      if (targetConvId.isEmpty) return;

      // 2. Optimistic Update
      final optimisticMessage = ChatMessage(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: targetConvId,
        senderId: senderId,
        content: content.trim(),
        timestamp: DateTime.now(),
        type: messageType,
        isMe: true,
      );
      
      if (messages.containsKey(targetConvId)) {
        messages[targetConvId]!.add(optimisticMessage);
        messages.refresh();
      }

      _audioService.playMessageSent();

      final String idempotencyKey = 'msg-${DateTime.now().microsecondsSinceEpoch}-${senderId.substring(0, 5)}';
      final stopwatch = Stopwatch()..start();
      
      await _chatRepository.sendMessage(
        conversationId: targetConvId,
        senderId: senderId,
        content: content.trim(),
        messageType: messageType,
        idempotencyKey: idempotencyKey,
      );

      stopwatch.stop();
      AppLoggerService.logChatPerformance(
        conversationId: targetConvId,
        action: 'send_message_success',
        latencyMs: stopwatch.elapsedMilliseconds,
        details: {
          'message_type': messageType.name,
          'content_length': content.length,
        },
      );
    } catch (e) {
      debugPrint('[ChatController] ✗ Error sending message: $e');
      
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
    }
  }

  Future<void> pickAndSendImage(String conversationId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
      );

      if (image == null) return;

      isUploading.value = true;
      final File file = File(image.path);
      
      final String? imageUrl = await _uploadImage(file, conversationId);
      
      if (imageUrl != null) {
        await sendMessage(conversationId, imageUrl, messageType: MessageType.image);
      }
    } catch (e) {
      debugPrint('[ChatController] ✗ Error picking image: $e');
      Get.snackbar('خطأ', 'تعذر اختيار الصورة');
    } finally {
      isUploading.value = false;
    }
  }

  Future<String?> _uploadImage(File file, String conversationId) async {
    final stopwatch = Stopwatch()..start();
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final currentUser = SupabaseService.auth.currentUser;
      final String path = 'support/${currentUser?.id}/$fileName';

      await SupabaseService.client.storage
          .from('chat_attachments')
          .upload(path, file);

      stopwatch.stop();
      AppLoggerService.logChatPerformance(
        conversationId: conversationId,
        action: 'upload_image_success',
        latencyMs: stopwatch.elapsedMilliseconds,
        details: {'file_size': await file.length()},
      );

      return SupabaseService.client.storage
          .from('chat_attachments')
          .getPublicUrl(path);
    } catch (e) {
      stopwatch.stop();
      AppLoggerService.logChatPerformance(
        conversationId: conversationId,
        action: 'upload_image_failure',
        latencyMs: stopwatch.elapsedMilliseconds,
        severity: 'error',
        details: {'error': e.toString()},
      );
      debugPrint('[ChatController] ✗ Error uploading image: $e');
      Get.snackbar('خطأ الرفع', 'تعذر رفع الصورة للسيرفر');
      return null;
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

  Future<void> deleteMessage(String messageId, String conversationId) async {
    try {
      // Optimistic update
      if (messages.containsKey(conversationId)) {
        messages[conversationId]!.removeWhere((m) => m.id == messageId);
        messages.refresh();
      }

      await _chatRepository.deleteMessage(messageId);
    } catch (e) {
      debugPrint('[ChatController] ✗ Error deleting message: $e');
      Get.snackbar('خطأ', 'فشل حذف الرسالة');
      // Re-fetch messages to restore local state
      listenToMessages(conversationId);
    }
  }
}
