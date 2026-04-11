-- ╔══════════════════════════════════════════════════════════════╗
-- ║  KASBY – DATABASE REPAIR SCRIPT (v1.0)                     ║
-- ║  Fix: relation "public.system_logs" does not exist         ║
-- ║  Action: Redefine Admin RPCs to use "activity_logs"        ║
-- ╚══════════════════════════════════════════════════════════════╝

BEGIN;

-- 1. Ensure Activity Logs Table structure matches what functions expect
-- Note: 'activity_logs' is the standard table in KASBY MASTER V5
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    actor_role      TEXT, -- 'admin', 'user', 'agent'
    action          TEXT NOT NULL,
    entity_type     TEXT,
    entity_id       TEXT,
    details         JSONB DEFAULT '{}'::jsonb,
    severity        TEXT DEFAULT 'info',
    ip_address      TEXT,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Redefine ADD BALANCE Function (Using activity_logs)
CREATE OR REPLACE FUNCTION public.fn_admin_add_balance(
  p_user_id UUID,
  p_amount DECIMAL(18,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wallet_id UUID;
BEGIN
  -- Security Guard: Check if the caller is an admin
  -- We assume public.is_admin() exists. If not, we fall back to a manual check.
  IF NOT EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND (role::text = 'admin' OR role::text = 'agent')
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  -- Atomic wallet update
  UPDATE wallets
  SET available_balance = available_balance + p_amount,
      updated_at = now()
  WHERE user_id = p_user_id
  RETURNING id INTO v_wallet_id;
  
  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
  END IF;

  -- Log as transaction (Approved immediately as it is an admin action)
  INSERT INTO transactions (user_id, wallet_id, type, amount, status, description, created_at)
  VALUES (p_user_id, v_wallet_id, 'admin_credit', p_amount, 'approved', 'إضافة رصيد بواسطة المدير', now());

  -- Activity Log (CORRECT TABLE: activity_logs, NOT system_logs)
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details)
  VALUES (auth.uid(), 'Add Balance', 'wallet', p_user_id::text, jsonb_build_object('amount', p_amount));
END;
$$;

-- 3. Redefine DEDUCT BALANCE Function (Using activity_logs)
CREATE OR REPLACE FUNCTION public.fn_admin_deduct_balance(
  p_user_id UUID,
  p_amount DECIMAL(18,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wallet_id UUID;
  v_balance DECIMAL(18,2);
BEGIN
  -- Security Guard
  IF NOT EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND (role::text = 'admin' OR role::text = 'agent')
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  -- Fetch wallet_id and check balance
  SELECT id, available_balance INTO v_wallet_id, v_balance 
  FROM wallets 
  WHERE user_id = p_user_id
  FOR UPDATE;
  
  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
  END IF;
  
  IF v_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  -- Atomic wallet update
  UPDATE wallets
  SET available_balance = available_balance - p_amount,
      updated_at = now()
  WHERE id = v_wallet_id;

  -- Log as transaction
  INSERT INTO transactions (user_id, wallet_id, type, amount, status, description, created_at)
  VALUES (p_user_id, v_wallet_id, 'admin_debit', p_amount, 'approved', 'خصم رصيد بواسطة المدير', now());

  -- Activity Log (CORRECT TABLE: activity_logs)
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details)
  VALUES (auth.uid(), 'Deduct Balance', 'wallet', p_user_id::text, jsonb_build_object('amount', p_amount));
END;
$$;

COMMIT;

-- ══════════════════════════════════════════════════════════════
-- END OF REPAIR SCRIPT
-- ══════════════════════════════════════════════════════════════
