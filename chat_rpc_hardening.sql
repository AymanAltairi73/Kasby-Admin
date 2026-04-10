-- ═══════════════════════════════════════════════════════════════
-- Kasby Chat Hardening — SECURE Atomic Messaging
-- ═══════════════════════════════════════════════════════════════

-- This version includes a security layer to ensure that messages
-- can only be sent by authorized participants (the User or an Admin).

CREATE OR REPLACE FUNCTION fn_send_chat_message(
  p_conversation_id UUID,
  p_sender_id UUID,
  p_sender_type TEXT, -- 'admin' or 'user'
  p_content TEXT,
  p_message_type TEXT DEFAULT 'text',
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_target_user_id UUID;
BEGIN
  -- 1. SECURITY CHECK
  -- Fetch the conversation to verify ownership
  SELECT user_id INTO v_target_user_id 
  FROM chat_conversations 
  WHERE id = p_conversation_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المحادثة غير موجودة (Conversation not found)';
  END IF;

  -- If sender is a 'user', they MUST be the owner of the conversation
  IF p_sender_type = 'user' AND p_sender_id != v_target_user_id THEN
    RAISE EXCEPTION 'غير مصرح لك بالإرسال في هذه المحادثة (Unauthorized)';
  END IF;

  -- If sender is 'admin', verify that they actually have an admin role
  -- (Assuming public.is_admin exists based on previous system logic)
  IF p_sender_type = 'admin' AND NOT public.is_admin(p_sender_id) THEN
    RAISE EXCEPTION 'عفواً، لا تملك صلاحيات إدارة المحادثات (Admin Access Required)';
  END IF;

  -- 2. ATOMIC INSERT
  INSERT INTO chat_messages (
    conversation_id,
    sender_id,
    sender_type,
    content,
    message_type,
    idempotency_key
  ) VALUES (
    p_conversation_id,
    p_sender_id,
    p_sender_type,
    p_content,
    p_message_type,
    p_idempotency_key
  )
  ON CONFLICT (idempotency_key) DO NOTHING;

  -- 3. METADATA SYNC (Atomic unread increment)
  UPDATE chat_conversations
  SET 
    last_message = CASE 
      WHEN p_message_type = 'image' THEN '📷 صورة'
      WHEN p_message_type = 'file' THEN '📄 ملف'
      ELSE p_content 
    END,
    last_message_at = now(),
    unread_user_count = CASE WHEN p_sender_type = 'admin' THEN unread_user_count + 1 ELSE unread_user_count END,
    unread_admin_count = CASE WHEN p_sender_type = 'user' THEN unread_admin_count + 1 ELSE unread_admin_count END
  WHERE id = p_conversation_id;

END;
$$;
