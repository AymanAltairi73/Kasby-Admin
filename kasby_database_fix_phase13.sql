-- ═══════════════════════════════════════════════════════════════
-- Kasby Database Fix Phase 13: Settings RLS & RPC Security
-- ═══════════════════════════════════════════════════════════════

-- 1. Ensure RLS is enabled on all settings and content tables
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE terms_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;

-- 2. Add full access policies for Admins on these tables
-- We use public.is_admin() which we improved in Phase 12b

-- Subscription Plans
DROP POLICY IF EXISTS "Admins full access subscription_plans" ON subscription_plans;
CREATE POLICY "Admins full access subscription_plans"
ON subscription_plans FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Terms Sections
DROP POLICY IF EXISTS "Admins full access terms_sections" ON terms_sections;
CREATE POLICY "Admins full access terms_sections"
ON terms_sections FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Transaction Limits
DROP POLICY IF EXISTS "Admins full access transaction_limits" ON transaction_limits;
CREATE POLICY "Admins full access transaction_limits"
ON transaction_limits FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- FAQs
DROP POLICY IF EXISTS "Admins full access faqs" ON faqs;
CREATE POLICY "Admins full access faqs"
ON faqs FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- 3. Public/Authenticated read policies (if needed for client app)
-- Users need to see these to use the app

DROP POLICY IF EXISTS "Anyone can read subscription_plans" ON subscription_plans;
CREATE POLICY "Anyone can read subscription_plans"
ON subscription_plans FOR SELECT
TO authenticated, anon
USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS "Anyone can read terms_sections" ON terms_sections;
CREATE POLICY "Anyone can read terms_sections"
ON terms_sections FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS "Anyone can read faqs" ON faqs;
CREATE POLICY "Anyone can read faqs"
ON faqs FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS "Anyone can read transaction_limits" ON transaction_limits;
CREATE POLICY "Anyone can read transaction_limits"
ON transaction_limits FOR SELECT
TO authenticated, anon
USING (true);

-- 4. Add explicit Admin Checks to sensitive RPCs (Security Hardening)
-- These were previously definer-only without internal checks

-- Admin add balance
CREATE OR REPLACE FUNCTION fn_admin_add_balance(
  p_user_id UUID,
  p_amount DECIMAL(18,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Security Guard
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  -- Check system freeze
  IF EXISTS (SELECT 1 FROM system_settings WHERE id = 'global' AND system_freeze = true) THEN
    RAISE EXCEPTION 'System is frozen — operation blocked';
  END IF;

  -- Atomic wallet update
  UPDATE wallets
  SET available_balance = available_balance + p_amount,
      updated_at = now()
  WHERE user_id = p_user_id;

  -- Log as transaction
  INSERT INTO transactions (user_id, type, amount, status, description, created_at)
  VALUES (p_user_id, 'admin_credit', p_amount, 'Approved', 'إضافة رصيد بواسطة المدير', now());

  -- Activity Log
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details)
  VALUES (auth.uid(), 'Add Balance', 'wallet', p_user_id::text, 'Added ' || p_amount || ' to balance');
END;
$$;

-- Admin deduct balance
CREATE OR REPLACE FUNCTION fn_admin_deduct_balance(
  p_user_id UUID,
  p_amount DECIMAL(18,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_balance DECIMAL(18,2);
BEGIN
  -- Security Guard
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  IF EXISTS (SELECT 1 FROM system_settings WHERE id = 'global' AND system_freeze = true) THEN
    RAISE EXCEPTION 'System is frozen — operation blocked';
  END IF;

  -- Lock and check
  SELECT available_balance INTO v_balance
  FROM wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance. Available: %, Requested: %', v_balance, p_amount;
  END IF;

  UPDATE wallets
  SET available_balance = available_balance - p_amount,
      updated_at = now()
  WHERE user_id = p_user_id;

  INSERT INTO transactions (user_id, type, amount, status, description, created_at)
  VALUES (p_user_id, 'admin_debit', p_amount, 'Approved', 'خصم رصيد بواسطة المدير', now());

  -- Activity Log
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details)
  VALUES (auth.uid(), 'Deduct Balance', 'wallet', p_user_id::text, 'Deducted ' || p_amount || ' from balance');
END;
$$;
