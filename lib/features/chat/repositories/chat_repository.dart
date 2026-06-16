import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/app_logger_service.dart';
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
            .select('*, profiles!chat_conversations_user_id_fkey(full_name, avatar_url, updated_at, role)')
            .order('last_message_at', ascending: false);

        return (response as List)
            .map((json) => ChatConversation.fromSupabase(json))
            .toList();
      },
      methodName: 'getConversations',
      controllerName: 'ChatRepository',
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
      controllerName: 'ChatRepository',
    );
  }

  /// Send a message via canonical RPC, with RLS direct-insert fallback.
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
    String? idempotencyKey,
    String? replyToId,
  }) async {
    await safeQuery(
      () async {
        final senderId = client.auth.currentUser?.id;
        if (senderId == null) {
          throw StateError('Authentication required to send messages');
        }

        final rpcParams = {
          'p_conversation_id': conversationId,
          'p_message_content': content,
          'p_message_type': messageType.name,
          'p_idempotency_key': idempotencyKey,
          'p_reply_to_id': replyToId,
        };

        try {
          // Canonical signature: fn_send_chat_message(uuid, text, text, text, uuid)
          await client.rpc('fn_send_chat_message', params: rpcParams);
          return;
        } on PostgrestException catch (e) {
          final missingRpc = e.code == 'PGRST202' ||
              e.code == 'PGRST203' ||
              e.code == '42883' ||
              e.message.contains('fn_send_chat_message');
          final blockedBySocialGate = e.code == 'P0001' &&
              e.message.contains('Messaging only allowed between friends');
          if (!missingRpc && !blockedBySocialGate) rethrow;
        }

        // Fallback: admin RLS insert path (works even before RPC migration is applied)
        await client.from('chat_messages').insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'sender_type': 'admin',
          'message_content': content,
          'message_type': messageType.name,
          if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
          if (replyToId != null) 'reply_to_id': replyToId,
        });
      },
      methodName: 'sendMessage',
      controllerName: 'ChatRepository',
    );
  }

  /// Stream messages for a conversation
  Stream<List<Map<String, dynamic>>> streamMessages(String conversationId) {
    AppLoggerService.debugTrace(
      className: 'ChatRepository',
      method: 'streamMessages',
      feature: 'Chat',
      status: 'INFO',
      params: {'conversationId': conversationId},
    );
    return client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false);
  }

  /// Stream conversations
  Stream<List<Map<String, dynamic>>> streamConversations() {
    AppLoggerService.debugTrace(
      className: 'ChatRepository',
      method: 'streamConversations',
      feature: 'Chat',
      status: 'INFO',
    );
    return client
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false);
  }

  /// Fetch a single conversation by id (with profile join).
  Future<ChatConversation?> fetchConversation(String conversationId) async {
    return safeQuery<ChatConversation?>(
      () async {
        final row = await client
            .from('chat_conversations')
            .select('*, profiles!chat_conversations_user_id_fkey(full_name, avatar_url, updated_at, role)')
            .eq('id', conversationId)
            .maybeSingle();

        if (row == null) return null;
        return ChatConversation.fromSupabase(row);
      },
      methodName: 'fetchConversation',
      controllerName: 'ChatRepository',
    );
  }

  /// Get or create a support conversation for a user/agent profile id.
  Future<ChatConversation> getOrCreateConversation(String userId) async {
    return safeQuery<ChatConversation>(
      () async {
        // Prefer an open support conversation (not social / not user↔agent P2P).
        final existing = await client
            .from('chat_conversations')
            .select('*, profiles!chat_conversations_user_id_fkey(full_name, avatar_url, updated_at, role)')
            .eq('user_id', userId)
            .eq('is_agent_chat', false)
            .neq('category', 'social')
            .order('last_message_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (existing != null) {
          return ChatConversation.fromSupabase(existing);
        }

        final created = await client
            .from('chat_conversations')
            .insert({
              'user_id': userId,
              'category': 'support',
              'is_agent_chat': false,
            })
            .select('*, profiles!chat_conversations_user_id_fkey(full_name, avatar_url, updated_at, role)')
            .single();

        return ChatConversation.fromSupabase(created);
      },
      methodName: 'getOrCreateConversation',
      controllerName: 'ChatRepository',
    );
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await safeQuery(
      () async {
        await client.from('chat_messages').update({'is_deleted': true}).eq('id', messageId);
      },
      methodName: 'deleteMessage',
      controllerName: 'ChatRepository',
    );
  }
}
