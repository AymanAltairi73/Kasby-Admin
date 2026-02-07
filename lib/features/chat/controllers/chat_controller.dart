import 'package:get/get.dart';
import '../models/chat_model.dart';
import '../../../core/services/audio_service.dart';

class ChatController extends GetxController {
  final conversations = <ChatConversation>[].obs;
  final messages =
      <String, List<ChatMessage>>{}.obs; // userId -> list of messages
  final unreadTotal = 0.obs;
  final isTyping = <String, bool>{}.obs; // userId -> isTyping

  late AudioService _audioService;

  @override
  void onInit() {
    super.onInit();
    _audioService = Get.find<AudioService>();
    _loadMockData();
  }

  void _loadMockData() {
    // Adding some mock conversations
    conversations.assignAll([
      ChatConversation(
        userId: 'u1',
        userName: 'أحمد علي',
        lastMessage: 'كيف يمكنني سحب أرباحي؟',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        isOnline: true,
      ),
      ChatConversation(
        userId: 'u2',
        userName: 'سارة محمد',
        lastMessage: 'تم استلام الحوالة، شكراً لكم',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        isOnline: false,
      ),
      ChatConversation(
        userId: 'u3',
        userName: 'محمد حسن',
        lastMessage: 'هل توجد خطط استثمارية جديدة؟',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
        isOnline: true,
      ),
    ]);

    // Mock messages for Ahmed
    messages['u1'] = [
      ChatMessage(
        id: '1',
        senderId: 'u1',
        content: 'مرحباً، لدي استفسار بخصوص السحب',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isMe: false,
      ),
      ChatMessage(
        id: '2',
        senderId: 'admin',
        content: 'أهلاً بك أحمد، كيف يمكنني مساعدتك؟',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isMe: true,
      ),
      ChatMessage(
        id: '3',
        senderId: 'u1',
        content: 'كيف يمكنني سحب أرباحي؟',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isMe: false,
      ),
    ];

    _calculateUnread();
  }

  void _calculateUnread() {
    unreadTotal.value = conversations.fold(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  }

  void sendMessage(String userId, String content) async {
    if (content.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().toString(),
      senderId: 'admin',
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
    );

    if (messages.containsKey(userId)) {
      messages[userId]!.add(newMessage);
      messages.refresh();
    } else {
      messages[userId] = [newMessage];
    }

    // Play sound
    _audioService.playMessageSent();

    // Update conversation last message
    final index = conversations.indexWhere((c) => c.userId == userId);
    if (index != -1) {
      final conv = conversations[index];
      conversations[index] = ChatConversation(
        userId: conv.userId,
        userName: conv.userName,
        userAvatar: conv.userAvatar,
        lastMessage: content,
        lastMessageTime: DateTime.now(),
        unreadCount: conv.unreadCount,
        isOnline: conv.isOnline,
      );
    }

    // Simulate reply
    _simulateReply(userId);
  }

  void _simulateReply(String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    isTyping[userId] = true;
    isTyping.refresh();

    await Future.delayed(const Duration(seconds: 3));
    isTyping[userId] = false;
    isTyping.refresh();

    final reply = ChatMessage(
      id: DateTime.now().toString(),
      senderId: userId,
      content: 'شكراً لردك السريع! سأقوم بمراجعة التعليمات.',
      timestamp: DateTime.now(),
      isMe: false,
    );

    if (messages.containsKey(userId)) {
      messages[userId]!.add(reply);
      messages.refresh();
    }

    _audioService.playNotification();

    final index = conversations.indexWhere((c) => c.userId == userId);
    if (index != -1) {
      final conv = conversations[index];
      conversations[index] = ChatConversation(
        userId: conv.userId,
        userName: conv.userName,
        userAvatar: conv.userAvatar,
        lastMessage: reply.content,
        lastMessageTime: DateTime.now(),
        unreadCount: conv.unreadCount + 1,
        isOnline: conv.isOnline,
      );
      _calculateUnread();
    }
  }

  void markAsRead(String userId) {
    final index = conversations.indexWhere((c) => c.userId == userId);
    if (index != -1 && conversations[index].unreadCount > 0) {
      final conv = conversations[index];
      conversations[index] = ChatConversation(
        userId: conv.userId,
        userName: conv.userName,
        userAvatar: conv.userAvatar,
        lastMessage: conv.lastMessage,
        lastMessageTime: conv.lastMessageTime,
        unreadCount: 0,
        isOnline: conv.isOnline,
      );
      _calculateUnread();
    }
  }
}
