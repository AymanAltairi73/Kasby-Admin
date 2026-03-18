-- ============================================================
-- CHAT SYSTEM RLS FIX (إصلاح سياسات الوصول للمحادثات)
-- ============================================================

-- 1. التأكد من وجود وظيفة التحقق من الأدمن
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    -- التحقق من دور المستخدم في جدول profiles
    RETURN EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
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

-- 4. التأكد من صلاحيات الوصول لجدول البروفايلات (لجبت البيانات الملحقة)
DROP POLICY IF EXISTS "Anyone view profiles" ON public.profiles;
CREATE POLICY "Anyone view profiles" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (true);

-- ملاحظة: إذا كنت لا ترى المستخدمين، تأكد أن حسابك في جدول profiles يحمل دور 'admin'
-- يمكنك تشغيل هذا الأمر لترقية حسابك (استبدل UUID بمعرف حسابك):
-- UPDATE public.profiles SET role = 'admin' WHERE id = 'YOUR_USER_ID';
