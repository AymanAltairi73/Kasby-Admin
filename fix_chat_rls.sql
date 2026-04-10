-- ============================================================
-- CHAT SYSTEM RLS FIX (إصلاح سياسات الوصول للمحادثات)
-- ============================================================

-- 1. التأكد من وجود وظيفة التحقق من الأدمن
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
        OR
        EXISTS (SELECT 1 FROM public.admin_profiles WHERE id = auth.uid() AND role = 'admin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 2. تفعيل السياسة لجدول المحادثات
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;

-- حذف السياسات القديمة لتجنب التعارض
DROP POLICY IF EXISTS "Admin scan chats" ON public.chat_conversations;
DROP POLICY IF EXISTS "Admin full access chats" ON public.chat_conversations;
DROP POLICY IF EXISTS "p_admin_convs" ON public.chat_conversations;

-- إنشاء سياسة تسمح للأدمن بكل العمليات
CREATE POLICY "Admin full access chats" 
ON public.chat_conversations 
FOR ALL 
TO authenticated 
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Users view own chats" ON public.chat_conversations;
CREATE POLICY "Users view own chats"
ON public.chat_conversations
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users update own chats" ON public.chat_conversations;
CREATE POLICY "Users update own chats"
ON public.chat_conversations
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 3. تفعيل السياسة لجدول الرسائل
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin scan messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Admin full access messages" ON public.chat_messages;
DROP POLICY IF EXISTS "p_admin_msgs" ON public.chat_messages;

CREATE POLICY "Admin full access messages" 
ON public.chat_messages 
FOR ALL 
TO authenticated 
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Users view own messages" ON public.chat_messages;
CREATE POLICY "Users view own messages"
ON public.chat_messages
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.chat_conversations
        WHERE id = conversation_id AND user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users insert own messages" ON public.chat_messages;
CREATE POLICY "Users insert own messages"
ON public.chat_messages
FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM public.chat_conversations
        WHERE id = conversation_id AND user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Anyone view profiles" ON public.profiles;
CREATE POLICY "Anyone view profiles" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (true);

-- 5. تفعيل ميزة الوقت الفعلي (Realtime)
ALTER TABLE public.chat_messages REPLICA IDENTITY FULL;
ALTER TABLE public.chat_conversations REPLICA IDENTITY FULL;

-- إضافة الجداول للنشر الخاص بالوقت الفعلي
-- ملاحظة: إذا كان هناك خطأ "already exists"، تجاهله.
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'chat_messages') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'chat_conversations') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_conversations;
    END IF;
END $$;
