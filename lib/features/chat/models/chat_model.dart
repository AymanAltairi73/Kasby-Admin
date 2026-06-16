import '../../../core/services/app_logger_service.dart';

enum MessageType { text, image, file, system }
enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final bool isMe;
  final bool isDeleted;
  final String? idempotencyKey;
  final List<String> reactions;
  final Map<String, dynamic>? attachmentMetadata;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.readAt,
    this.deliveredAt,
    required this.isMe,
    this.isDeleted = false,
    this.idempotencyKey,
    this.reactions = const [],
    this.attachmentMetadata,
  });

  MessageStatus get status {
    if (id.startsWith('temp-')) return MessageStatus.sending;
    if (readAt != null) return MessageStatus.read;
    if (deliveredAt != null) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  factory ChatMessage.fromSupabase(Map<String, dynamic> json, String currentUserId) {
    try {
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: (json['message_content'] ?? json['content']) ?? '',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      type: _parseMessageType(json['message_type']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      isMe: json['sender_id'] == currentUserId,
      isDeleted: json['is_deleted'] ?? false,
      idempotencyKey: json['idempotency_key'],
      reactions: (json['reactions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      attachmentMetadata: json['attachment_metadata'] as Map<String, dynamic>?,
    );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'ChatMessage',
        method: 'fromSupabase',
        feature: 'Chat',
        status: 'FAILED',
        params: {'id': json['id']?.toString()},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image': return MessageType.image;
      case 'file': return MessageType.file;
      case 'system': return MessageType.system;
      default: return MessageType.text;
    }
  }
}

class ChatConversation {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final bool isAgent;
  /// True when this is a user↔agent P2P chat (not agent↔support).
  final bool isAgentChat;
  final String category;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeenAt,
    this.isAgent = false,
    this.isAgentChat = false,
    this.category = 'support',
  });

  bool get isSocialChat => category == 'social';
  bool get isSupportChat => !isSocialChat && !isAgentChat;

  ChatConversation copyWith({
    bool? isOnline,
    DateTime? lastSeenAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatConversation(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isAgent: isAgent,
      isAgentChat: isAgentChat,
      category: category,
    );
  }

  factory ChatConversation.fromSupabase(Map<String, dynamic> json) {
    try {
    var profileData = json['profiles'];
    Map<String, dynamic>? profile;
    
    if (profileData is List && profileData.isNotEmpty) {
      profile = profileData.first as Map<String, dynamic>;
    } else if (profileData is Map) {
      profile = profileData as Map<String, dynamic>;
    }

    return ChatConversation(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: profile != null ? (profile['full_name'] ?? 'Unknown User') : 'Unknown User',
      userAvatar: profile != null ? profile['avatar_url'] : null,
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at']) 
          : DateTime.now(),
      unreadCount: json['unread_admin_count'] ?? 0,
      isOnline: false,
      lastSeenAt: profile != null 
          ? (profile['last_seen_at'] != null 
              ? DateTime.parse(profile['last_seen_at']) 
              : (profile['updated_at'] != null ? DateTime.parse(profile['updated_at']) : null))
          : null,
      isAgentChat: json['is_agent_chat'] ?? false,
      isAgent: profile != null && profile['role'] == 'agent',
      category: (json['category'] as String?) ?? 'support',
    );
    } catch (e, stack) {
      AppLoggerService.debugTrace(
        className: 'ChatConversation',
        method: 'fromSupabase',
        feature: 'Chat',
        status: 'FAILED',
        params: {'id': json['id']?.toString()},
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
