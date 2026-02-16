-- ═══════════════════════════════════════════════════════════════
-- Kasby Security Migration — Priority 1 & 2
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ─────────── V-03: System Settings Table ───────────
-- Drop and recreate to ensure id is TEXT (not UUID)
DROP TABLE IF EXISTS system_settings CASCADE;
CREATE TABLE system_settings (
  id TEXT PRIMARY KEY DEFAULT 'global',
  pause_withdrawals BOOLEAN NOT NULL DEFAULT false,
  pause_profits BOOLEAN NOT NULL DEFAULT false,
  system_freeze BOOLEAN NOT NULL DEFAULT false,
  maintenance_mode BOOLEAN NOT NULL DEFAULT false,
  maintenance_message TEXT DEFAULT '',
  updated_by TEXT DEFAULT 'System',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Insert default row
INSERT INTO system_settings (id) VALUES ('global')
ON CONFLICT (id) DO NOTHING;

-- ─────────── V-04: Fee Configuration Table ───────────
CREATE TABLE IF NOT EXISTS fee_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT NOT NULL,
  value TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Deposit',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─────────── V-04: Limit Configuration Table ───────────
CREATE TABLE IF NOT EXISTS limit_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT NOT NULL,
  value TEXT NOT NULL,
  tier TEXT NOT NULL DEFAULT 'Normal',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─────────── V-04: Currency Configuration Table ───────────
CREATE TABLE IF NOT EXISTS currency_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  rate TEXT NOT NULL DEFAULT '1.00',
  is_base BOOLEAN NOT NULL DEFAULT false,
  icon_code INT,
  icon_family TEXT,
  icon_package TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─────────── V-04: App FAQs Table ───────────
CREATE TABLE IF NOT EXISTS app_faqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─────────── V-04: App Terms Table ───────────
CREATE TABLE IF NOT EXISTS app_terms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─────────── V-08: Idempotency on Transaction RPCs ───────────
-- Update fn_process_deposit to check status before processing
CREATE OR REPLACE FUNCTION fn_process_deposit(
  p_txn_id UUID,
  p_admin_id UUID DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_txn RECORD;
BEGIN
  -- Lock the transaction row to prevent double-processing
  SELECT * INTO v_txn
  FROM transactions
  WHERE id = p_txn_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found: %', p_txn_id;
  END IF;

  -- Idempotency guard: only process Pending transactions
  IF v_txn.status != 'Pending' THEN
    RAISE EXCEPTION 'Transaction % is already %', p_txn_id, v_txn.status;
  END IF;

  -- Check system freeze
  IF EXISTS (SELECT 1 FROM system_settings WHERE id = 'global' AND system_freeze = true) THEN
    RAISE EXCEPTION 'System is frozen — operation blocked';
  END IF;

  -- Credit the wallet
  UPDATE wallets
  SET available_balance = available_balance + v_txn.amount,
      updated_at = now()
  WHERE user_id = v_txn.user_id;

  -- Mark transaction as approved
  UPDATE transactions
  SET status = 'Approved',
      processed_by = p_admin_id,
      processed_at = now(),
      updated_at = now()
  WHERE id = p_txn_id;
END;
$$;

-- Update fn_process_withdrawal with idempotency and balance check
CREATE OR REPLACE FUNCTION fn_process_withdrawal(
  p_txn_id UUID,
  p_admin_id UUID DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_txn RECORD;
  v_balance DECIMAL(18,2);
BEGIN
  -- Lock the transaction row
  SELECT * INTO v_txn
  FROM transactions
  WHERE id = p_txn_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found: %', p_txn_id;
  END IF;

  IF v_txn.status != 'Pending' THEN
    RAISE EXCEPTION 'Transaction % is already %', p_txn_id, v_txn.status;
  END IF;

  -- Check system freeze
  IF EXISTS (SELECT 1 FROM system_settings WHERE id = 'global' AND system_freeze = true) THEN
    RAISE EXCEPTION 'System is frozen — operation blocked';
  END IF;

  -- Check pause_withdrawals
  IF EXISTS (SELECT 1 FROM system_settings WHERE id = 'global' AND pause_withdrawals = true) THEN
    RAISE EXCEPTION 'Withdrawals are currently paused';
  END IF;

  -- Lock wallet and check balance
  SELECT available_balance INTO v_balance
  FROM wallets
  WHERE user_id = v_txn.user_id
  FOR UPDATE;

  IF v_balance < v_txn.amount THEN
    RAISE EXCEPTION 'Insufficient balance. Available: %, Requested: %', v_balance, v_txn.amount;
  END IF;

  -- Deduct from wallet
  UPDATE wallets
  SET available_balance = available_balance - v_txn.amount,
      updated_at = now()
  WHERE user_id = v_txn.user_id;

  -- Mark transaction as approved
  UPDATE transactions
  SET status = 'Approved',
      processed_by = p_admin_id,
      processed_at = now(),
      updated_at = now()
  WHERE id = p_txn_id;
END;
$$;

-- Reject transaction with idempotency
CREATE OR REPLACE FUNCTION fn_reject_transaction(
  p_txn_id UUID,
  p_admin_id UUID DEFAULT NULL,
  p_reason TEXT DEFAULT 'رفض بواسطة المدير'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_txn RECORD;
BEGIN
  SELECT * INTO v_txn
  FROM transactions
  WHERE id = p_txn_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found: %', p_txn_id;
  END IF;

  IF v_txn.status != 'Pending' THEN
    RAISE EXCEPTION 'Transaction % is already %', p_txn_id, v_txn.status;
  END IF;

  UPDATE transactions
  SET status = 'Rejected',
      rejection_reason = p_reason,
      processed_by = p_admin_id,
      processed_at = now(),
      updated_at = now()
  WHERE id = p_txn_id;
END;
$$;

-- Admin add balance (atomic)
CREATE OR REPLACE FUNCTION fn_admin_add_balance(
  p_user_id UUID,
  p_amount DECIMAL(18,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
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
END;
$$;

-- Admin deduct balance (atomic, with balance check)
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
END;
$$;

-- ─────────── Priority 2: fn_invest ───────────
CREATE OR REPLACE FUNCTION fn_invest(
  p_user_id UUID,
  p_plan_id UUID,
  p_amount DECIMAL(18,2)
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_balance DECIMAL(18,2);
  v_plan RECORD;
  v_investment_id UUID;
BEGIN
  -- Validate plan
  SELECT * INTO v_plan
  FROM investment_plans
  WHERE id = p_plan_id AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Investment plan not found or inactive';
  END IF;

  IF p_amount < v_plan.min_amount OR p_amount > v_plan.max_amount THEN
    RAISE EXCEPTION 'Amount must be between % and %', v_plan.min_amount, v_plan.max_amount;
  END IF;

  -- Check system state
  IF EXISTS (SELECT 1 FROM system_settings WHERE id = 'global' AND system_freeze = true) THEN
    RAISE EXCEPTION 'System is frozen — operation blocked';
  END IF;

  -- Lock wallet and check balance
  SELECT available_balance INTO v_balance
  FROM wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance. Available: %, Requested: %', v_balance, p_amount;
  END IF;

  -- Deduct from available balance, add to invested
  UPDATE wallets
  SET available_balance = available_balance - p_amount,
      invested_balance = COALESCE(invested_balance, 0) + p_amount,
      updated_at = now()
  WHERE user_id = p_user_id;

  -- Create investment record
  INSERT INTO user_investments (user_id, plan_id, amount, profit_percentage, expected_profit, status, created_at)
  VALUES (
    p_user_id,
    p_plan_id,
    p_amount,
    v_plan.profit_percentage,
    p_amount * v_plan.profit_percentage / 100.0,
    'active',
    now()
  )
  RETURNING id INTO v_investment_id;

  -- Log transaction
  INSERT INTO transactions (user_id, type, amount, status, description, created_at)
  VALUES (p_user_id, 'investment', p_amount, 'Approved', 'استثمار في خطة: ' || v_plan.name_ar, now());

  RETURN v_investment_id;
END;
$$;

-- ─────────── Priority 2: fn_credit_profit ───────────
CREATE OR REPLACE FUNCTION fn_credit_profit(
  p_investment_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_inv RECORD;
BEGIN
  SELECT * INTO v_inv
  FROM user_investments
  WHERE id = p_investment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Investment not found';
  END IF;

  IF v_inv.status != 'active' THEN
    RAISE EXCEPTION 'Investment is not active (status: %)', v_inv.status;
  END IF;

  -- Check if profits are paused
  IF EXISTS (SELECT 1 FROM system_settings WHERE id = 'global' AND pause_profits = true) THEN
    RAISE EXCEPTION 'Profit distribution is currently paused';
  END IF;

  -- Credit profit to wallet
  UPDATE wallets
  SET available_balance = available_balance + v_inv.expected_profit,
      invested_balance = GREATEST(COALESCE(invested_balance, 0) - v_inv.amount, 0),
      updated_at = now()
  WHERE user_id = v_inv.user_id;

  -- Mark investment as matured
  UPDATE user_investments
  SET status = 'matured',
      matured_at = now()
  WHERE id = p_investment_id;

  -- Log transaction
  INSERT INTO transactions (user_id, type, amount, status, description, created_at)
  VALUES (v_inv.user_id, 'profit', v_inv.expected_profit, 'Approved',
          'أرباح استثمار #' || p_investment_id::text, now());
END;
$$;

-- ─────────── Priority 2: fn_approve_loan ───────────
CREATE OR REPLACE FUNCTION fn_approve_loan(
  p_loan_id UUID,
  p_admin_id UUID DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_loan RECORD;
BEGIN
  SELECT * INTO v_loan
  FROM loans
  WHERE id = p_loan_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Loan not found';
  END IF;

  IF v_loan.status != 'pending' THEN
    RAISE EXCEPTION 'Loan is not pending (status: %)', v_loan.status;
  END IF;

  -- Credit loan amount to wallet
  UPDATE wallets
  SET available_balance = available_balance + v_loan.amount,
      updated_at = now()
  WHERE user_id = v_loan.user_id;

  -- Update loan status
  UPDATE loans
  SET status = 'current',
      approved_by = p_admin_id,
      approved_at = now()
  WHERE id = p_loan_id;

  -- Log transaction
  INSERT INTO transactions (user_id, type, amount, status, description, created_at)
  VALUES (v_loan.user_id, 'loan_disbursement', v_loan.amount, 'Approved',
          'صرف قرض #' || p_loan_id::text, now());
END;
$$;

-- ─────────── Priority 2: fn_repay_loan ───────────
CREATE OR REPLACE FUNCTION fn_repay_loan(
  p_loan_id UUID,
  p_amount DECIMAL(18,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_loan RECORD;
  v_balance DECIMAL(18,2);
BEGIN
  SELECT * INTO v_loan
  FROM loans
  WHERE id = p_loan_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Loan not found';
  END IF;

  IF v_loan.status NOT IN ('current', 'delayed') THEN
    RAISE EXCEPTION 'Loan is not repayable (status: %)', v_loan.status;
  END IF;

  -- Lock wallet and check balance
  SELECT available_balance INTO v_balance
  FROM wallets
  WHERE user_id = v_loan.user_id
  FOR UPDATE;

  IF v_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance for repayment';
  END IF;

  -- Deduct from wallet
  UPDATE wallets
  SET available_balance = available_balance - p_amount,
      updated_at = now()
  WHERE user_id = v_loan.user_id;

  -- Update loan remaining (if applicable)
  UPDATE loans
  SET remaining_amount = GREATEST(COALESCE(remaining_amount, amount) - p_amount, 0),
      status = CASE
        WHEN GREATEST(COALESCE(remaining_amount, amount) - p_amount, 0) = 0 THEN 'paid'
        ELSE status
      END,
      updated_at = now()
  WHERE id = p_loan_id;

  -- Log transaction
  INSERT INTO transactions (user_id, type, amount, status, description, created_at)
  VALUES (v_loan.user_id, 'loan_repayment', p_amount, 'Approved',
          'سداد قرض #' || p_loan_id::text, now());
END;
$$;

-- ─────────── Make transactions immutable ───────────
-- Revoke direct UPDATE/DELETE on transactions for the anon role
REVOKE UPDATE, DELETE ON transactions FROM anon;
REVOKE UPDATE, DELETE ON transactions FROM authenticated;

-- Only service_role (used by RPCs with SECURITY DEFINER) can modify
-- RLS: users can only read their own transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own transactions" ON transactions;
CREATE POLICY "Users read own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role full access on transactions" ON transactions;
CREATE POLICY "Service role full access on transactions"
  ON transactions FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────── RLS on wallets ───────────
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own wallet" ON wallets;
CREATE POLICY "Users read own wallet"
  ON wallets FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role full access on wallets" ON wallets;
CREATE POLICY "Service role full access on wallets"
  ON wallets FOR ALL
  USING (auth.role() = 'service_role');

-- Revoke direct UPDATE for non-service roles
REVOKE UPDATE ON wallets FROM anon;
REVOKE UPDATE ON wallets FROM authenticated;

-- ─────────── RLS on system_settings (admin-only) ───────────
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read system_settings" ON system_settings;
CREATE POLICY "Authenticated users can read system_settings"
  ON system_settings FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Service role full access on system_settings" ON system_settings;
CREATE POLICY "Service role full access on system_settings"
  ON system_settings FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────── V-06: Gamification Tables ───────────
CREATE TABLE IF NOT EXISTS gamification_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  points INT NOT NULL DEFAULT 0,
  icon TEXT DEFAULT 'calendar-check',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS gamification_prizes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT NOT NULL,
  value TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'Points',
  probability DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS gamification_point_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action TEXT NOT NULL,
  points TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'Earn',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─────────── V-07: Admin Notifications Table ───────────
CREATE TABLE IF NOT EXISTS admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  target TEXT NOT NULL DEFAULT 'all',
  sent_at TIMESTAMPTZ DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'Sent',
  sent_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════
-- END OF MIGRATION
-- ═══════════════════════════════════════════════════════════════
