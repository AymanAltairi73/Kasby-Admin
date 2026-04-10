-- ═══════════════════════════════════════════════════════════════
-- SQL FIX: Final Comprehensive Repair (Case-Insensitive & Unique)
-- ═══════════════════════════════════════════════════════════════

-- 1. Fix Notifications Table
ALTER TABLE IF EXISTS public.notifications 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'notification';

-- 2. Core Admin Helper (Checks both profiles and admin_profiles)
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN COALESCE(
        (SELECT role = 'admin' FROM public.profiles WHERE id = auth.uid()),
        (SELECT role = 'admin' FROM public.admin_profiles WHERE id = auth.uid()),
        FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 3. Balance Functions
DROP FUNCTION IF EXISTS public.fn_admin_add_balance(UUID, DECIMAL) CASCADE;
CREATE OR REPLACE FUNCTION public.fn_admin_add_balance(p_user_id UUID, p_amount DECIMAL(18,2))
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized: Admin access required'; END IF;
  UPDATE wallets SET available_balance = available_balance + p_amount, updated_at = now() WHERE user_id = p_user_id;
  INSERT INTO transactions (user_id, type, amount, status, description, created_at)
  VALUES (p_user_id, 'admin_credit', p_amount, 'Approved', 'إضافة إدارية', now());
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details, severity)
  VALUES (auth.uid(), 'Add Balance', 'wallet', p_user_id::text, jsonb_build_object('amount', p_amount), 'info');
END;
$$;

DROP FUNCTION IF EXISTS public.fn_admin_deduct_balance(UUID, DECIMAL) CASCADE;
CREATE OR REPLACE FUNCTION public.fn_admin_deduct_balance(p_user_id UUID, p_amount DECIMAL(18,2))
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_balance DECIMAL(18,2);
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized: Admin access required'; END IF;
  SELECT available_balance INTO v_balance FROM wallets WHERE user_id = p_user_id FOR UPDATE;
  IF v_balance < p_amount THEN RAISE EXCEPTION 'Insufficient balance'; END IF;
  UPDATE wallets SET available_balance = available_balance - p_amount, updated_at = now() WHERE user_id = p_user_id;
  INSERT INTO transactions (user_id, type, amount, status, description, created_at)
  VALUES (p_user_id, 'admin_debit', p_amount, 'Approved', 'خصم إداري', now());
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details, severity)
  VALUES (auth.uid(), 'Deduct Balance', 'wallet', p_user_id::text, jsonb_build_object('amount', p_amount), 'info');
END;
$$;

-- 4. Transaction Functions (Case-Insensitive Status Checks)
DROP FUNCTION IF EXISTS public.fn_process_deposit(UUID, UUID) CASCADE;
CREATE OR REPLACE FUNCTION public.fn_process_deposit(p_txn_id UUID, p_admin_id UUID DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_wallet_id UUID; v_amount NUMERIC(18,4); v_net NUMERIC(18,4); v_new_bal NUMERIC(18,4);
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
    SELECT wallet_id, amount, (amount - COALESCE(fee, 0)) INTO v_wallet_id, v_amount, v_net
    FROM transactions WHERE id = p_txn_id AND type = 'deposit' AND (status ILIKE 'pending') FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Transaction not eligible'; END IF;
    UPDATE wallets SET available_balance = available_balance + v_net WHERE id = v_wallet_id;
    SELECT available_balance INTO v_new_bal FROM wallets WHERE id = v_wallet_id;
    UPDATE transactions SET status = 'Approved', running_balance = v_new_bal,
        processed_by = auth.uid(), processed_at = CURRENT_TIMESTAMP WHERE id = p_txn_id;
    INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details, severity)
    VALUES (auth.uid(), 'Approve Deposit', 'transaction', p_txn_id::text, json_build_object('amount', v_amount)::jsonb, 'info');
    INSERT INTO notifications (target_user_id, title, message, type)
    SELECT user_id, 'تم الموافقة على الإيداع', 'تمت إضافة ' || v_amount || ' إلى محفظتك', 'financial'
    FROM transactions WHERE id = p_txn_id;
END;
$$;

DROP FUNCTION IF EXISTS public.approve_withdrawal(UUID, UUID) CASCADE;
CREATE OR REPLACE FUNCTION public.approve_withdrawal(p_txn_id UUID, p_admin_id UUID DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_wallet_id UUID; v_amount NUMERIC(18,4); v_available NUMERIC(18,4); v_new_bal NUMERIC(18,4);
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
    SELECT wallet_id, amount INTO v_wallet_id, v_amount
    FROM transactions WHERE id = p_txn_id AND type = 'withdrawal' AND (status ILIKE 'pending') FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Transaction not eligible'; END IF;
    SELECT available_balance INTO v_available FROM wallets WHERE id = v_wallet_id FOR UPDATE;
    IF v_available < v_amount THEN RAISE EXCEPTION 'Insufficient balance'; END IF;
    UPDATE wallets SET available_balance = available_balance - v_amount WHERE id = v_wallet_id;
    SELECT available_balance INTO v_new_bal FROM wallets WHERE id = v_wallet_id;
    UPDATE transactions SET status = 'Approved', running_balance = v_new_bal,
        processed_by = auth.uid(), processed_at = CURRENT_TIMESTAMP WHERE id = p_txn_id;
    INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details, severity)
    VALUES (auth.uid(), 'Approve Withdrawal', 'transaction', p_txn_id::text, json_build_object('amount', v_amount)::jsonb, 'info');
    INSERT INTO notifications (target_user_id, title, message, type)
    SELECT user_id, 'تم الموافقة على السحب', 'تم خصم ' || v_amount || ' من محفظتك بنجاح', 'financial'
    FROM transactions WHERE id = p_txn_id;
END;
$$;

DROP FUNCTION IF EXISTS public.reject_withdrawal(UUID, UUID, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.reject_withdrawal(p_txn_id UUID, p_admin_id UUID, p_reason TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
    UPDATE transactions SET status = 'Rejected', rejection_reason = p_reason,
        processed_by = auth.uid(), processed_at = CURRENT_TIMESTAMP
    WHERE id = p_txn_id AND (status ILIKE 'pending');
    IF NOT FOUND THEN RAISE EXCEPTION 'Transaction not rejectable'; END IF;
    INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details, severity)
    VALUES (auth.uid(), 'Reject Withdrawal', 'transaction', p_txn_id::text, json_build_object('reason', p_reason)::jsonb, 'warning');
END;
$$;

DROP FUNCTION IF EXISTS public.fn_reject_transaction(UUID, UUID, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.fn_reject_transaction(p_txn_id UUID, p_admin_id UUID, p_reason TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
    UPDATE transactions SET status = 'Rejected', rejection_reason = p_reason,
        processed_by = auth.uid(), processed_at = CURRENT_TIMESTAMP
    WHERE id = p_txn_id AND (status ILIKE 'pending');
    IF NOT FOUND THEN RAISE EXCEPTION 'Transaction not rejectable'; END IF;
    INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details, severity)
    VALUES (auth.uid(), 'Reject Transaction', 'transaction', p_txn_id::text, json_build_object('reason', p_reason)::jsonb, 'warning');
END;
$$;

-- 5. Agent Application Functions (Fix Ambiguity and Constraints)
-- Fix constraint for ON CONFLICT to work
ALTER TABLE IF EXISTS public.agents DROP CONSTRAINT IF EXISTS agents_user_id_key;
ALTER TABLE IF EXISTS public.agents ADD CONSTRAINT agents_user_id_key UNIQUE (user_id);

-- Drop ALL variations first
DROP FUNCTION IF EXISTS public.admin_approve_agent_application(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.admin_approve_agent_application(UUID, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION public.admin_approve_agent_application(p_application_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_user_id UUID; v_full_name TEXT; v_phone TEXT; v_city TEXT;
BEGIN
    IF NOT public.is_admin() THEN RETURN jsonb_build_object('success', false, 'message', 'Unauthorized'); END IF;

    -- 1. Get Application Details
    SELECT user_id, full_name, phone, city INTO v_user_id, v_full_name, v_phone, v_city
    FROM agent_applications WHERE id = p_application_id AND (status ILIKE 'pending');
    IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'message', 'Application not found or already processed'); END IF;

    -- 2. Update Profile Role
    UPDATE profiles SET role = 'agent'::role_type WHERE id = v_user_id;

    -- 3. Create/Update Agent record
    INSERT INTO agents (user_id, status, is_available_now)
    VALUES (v_user_id, 'active', true)
    ON CONFLICT (user_id) DO UPDATE SET status = 'active', updated_at = now();

    -- 4. Mark Application as Approved
    UPDATE agent_applications SET status = 'approved', updated_at = now() WHERE id = p_application_id;

    -- 5. Activity Log
    INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details, severity)
    VALUES (auth.uid(), 'Approve Agent', 'user', v_user_id::text, jsonb_build_object('app_id', p_application_id), 'info');

    RETURN jsonb_build_object('success', true);
END;
$$;
