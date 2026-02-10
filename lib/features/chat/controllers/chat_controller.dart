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

  List<ChatConversation> get agentConversations =>
      conversations.where((c) => c.isAgent).toList();
  List<ChatConversation> get userConversations =>
      conversations.where((c) => !c.isAgent).toList();

  void _loadMockData() {
    // Adding some mock conversations
    conversations.assignAll([
      ChatConversation(
        userId: 'u1',
        userName: 'الوكيل: أحمد علي',
        lastMessage: 'تم تحديث أسعار الصرف اليوم',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        isOnline: true,
        isAgent: true,
      ),
      ChatConversation(
        userId: 'u2',
        userName: 'المستخدم: سارة محمد',
        lastMessage: 'تم استلام الحوالة، شكراً لكم',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        isOnline: false,
        isAgent: false,
      ),
      ChatConversation(
        userId: 'u3',
        userName: 'الوكيل: محمد حسن',
        lastMessage: 'هل توجد عمولات خاصة لوكلاء VIP؟',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
        isOnline: true,
        isAgent: true,
      ),
      ChatConversation(
        userId: 'u4',
        userName: 'المستخدم: عبد الله عمر',
        lastMessage: 'متى سيتم تفعيل حسابي؟',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 45)),
        unreadCount: 1,
        isOnline: true,
        isAgent: false,
      ),
    ]);

    // Mock messages for Ahmed
    messages['u1'] = [
      ChatMessage(
        id: '1',
        senderId: 'u1',
        content: 'مرحباً، تم تحديث كشف الحساب الخاص بي',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isMe: false,
      ),
      ChatMessage(
        id: '1.1',
        senderId: 'admin',
        content: 'أهلاً بك يا أحمد، سأتحقق منه الآن',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isMe: true,
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
        isAgent: conv.isAgent,
      );
      conversations.refresh();
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
        isAgent: conv.isAgent,
      );
      conversations.refresh();
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
        isAgent: conv.isAgent,
      );
      conversations.refresh();
      _calculateUnread();
    }
  }
}
