import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/base_repository.dart';
import '../models/chat_model.dart';

class ChatRepository extends BaseRepository {
  ChatRepository(SupabaseClient client) : super('chat_conversations', client);

  /// Fetch all conversations for the admin
  Future<List<ChatConversation>> getConversations() async {
    return safeQuery<List<ChatConversation>>(
      () async {
        final response = await client
            .from('chat_conversations')
            .select('*, profiles(full_name, avatar_url, updated_at, role)')
            .order('last_message_at', ascending: false);

        return (response as List)
            .map((json) => ChatConversation.fromSupabase(json))
            .toList();
      },
      methodName: 'getConversations',
    );
  }

  /// Fetch messages for a specific conversation
  Future<List<ChatMessage>> getMessages(String conversationId, String currentUserId) async {
    return safeQuery<List<ChatMessage>>(
      () async {
        final response = await client
            .from('chat_messages')
            .select('*')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => ChatMessage.fromSupabase(json, currentUserId))
            .toList();
      },
      methodName: 'getMessages',
    );
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String senderType = 'admin',
    MessageType messageType = MessageType.text,
    String? idempotencyKey,
  }) async {
    await safeQuery(
      () async {
        await client.rpc('fn_send_chat_message', params: {
          'p_conversation_id': conversationId,
          'p_sender_id': senderId,
          'p_sender_type': senderType,
          'p_message_content': content,
          'p_message_type': messageType.name,
          'p_idempotency_key': idempotencyKey,
        });
      },
      methodName: 'sendMessage',
    );
  }

  /// Stream messages for a conversation
  Stream<List<Map<String, dynamic>>> streamMessages(String conversationId) {
    return client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false);
  }

  /// Stream conversations
  Stream<List<Map<String, dynamic>>> streamConversations() {
    return client
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false);
  }

  /// Get or create a conversation for a user
  Future<ChatConversation> getOrCreateConversation(String userId) async {
    return safeQuery<ChatConversation>(
      () async {
        // Try to find existing
        final existing = await client
            .from('chat_conversations')
            .select('*, profiles(full_name, avatar_url, updated_at, role)')
            .eq('user_id', userId)
            .maybeSingle();

        if (existing != null) {
          return ChatConversation.fromSupabase(existing);
        }

        // Create new
        final created = await client
            .from('chat_conversations')
            .insert({'user_id': userId})
            .select('*, profiles(full_name, avatar_url, updated_at, role)')
            .single();

        return ChatConversation.fromSupabase(created);
      },
      methodName: 'getOrCreateConversation',
    );
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await safeQuery(
      () async {
        await client.from('chat_messages').update({'is_deleted': true}).eq('id', messageId);
      },
      methodName: 'deleteMessage',
    );
  }
}
