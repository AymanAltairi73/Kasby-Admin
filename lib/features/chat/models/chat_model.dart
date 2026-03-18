enum MessageType { text, image, file, system }

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    required this.isMe,
  });

  factory ChatMessage.fromSupabase(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      type: _parseMessageType(json['message_type']),
      isMe: json['sender_id'] == currentUserId,
    );
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
  final bool isAgent;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isAgent = false,
  });

  factory ChatConversation.fromSupabase(Map<String, dynamic> json) {
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
      isAgent: json['is_agent_chat'] ?? false,
    );
  }
}
