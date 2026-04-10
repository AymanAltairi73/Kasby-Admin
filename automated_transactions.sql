-- ═══════════════════════════════════════════════════════════════
-- SQL: Automated Transactions, Agent Processing & Notifications
-- ═══════════════════════════════════════════════════════════════

-- 1. Ensure Notifications Schema
ALTER TABLE IF EXISTS public.notifications 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'notification';

-- 2. Staff Helper (Includes Admin & Agent)
DROP FUNCTION IF EXISTS public.is_staff() CASCADE;
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN COALESCE(
        (SELECT role IN ('admin', 'agent') FROM public.profiles WHERE id = auth.uid()),
        (SELECT role = 'admin' FROM public.admin_profiles WHERE id = auth.uid()),
        FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- 3. Automated Transfers with Dual-Party Notifications
DROP FUNCTION IF EXISTS public.fn_transfer(UUID, UUID, NUMERIC, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.fn_transfer(
    p_sender_id UUID, p_receiver_id UUID, p_amount NUMERIC(18,4), p_idempotency_key TEXT
) RETURNS UUID AS $$
DECLARE
    v_sw UUID; v_rw UUID; v_sb NUMERIC(18,4);
    v_txn_out UUID; v_txn_in UUID;
    v_frozen_s BOOLEAN; v_frozen_r BOOLEAN;
    v_sender_name TEXT; v_receiver_name TEXT;
BEGIN
    IF p_sender_id = p_receiver_id THEN RAISE EXCEPTION 'Cannot transfer to self.'; END IF;
    IF p_amount <= 0 THEN RAISE EXCEPTION 'Amount must be positive.'; END IF;
    IF EXISTS (SELECT 1 FROM system_settings WHERE system_freeze LIMIT 1) THEN
        RAISE EXCEPTION 'System frozen.'; END IF;

    -- Lock wallets and get names
    SELECT p.full_name, w.id, w.available_balance, w.is_frozen 
    INTO v_sender_name, v_sw, v_sb, v_frozen_s
    FROM profiles p JOIN wallets w ON w.user_id = p.id WHERE p.id = p_sender_id FOR UPDATE;
    
    SELECT p.full_name, w.id, w.is_frozen 
    INTO v_receiver_name, v_rw, v_frozen_r
    FROM profiles p JOIN wallets w ON w.user_id = p.id WHERE p.id = p_receiver_id FOR UPDATE;

    IF v_frozen_s THEN RAISE EXCEPTION 'Sender wallet frozen.'; END IF;
    IF v_frozen_r THEN RAISE EXCEPTION 'Receiver wallet frozen.'; END IF;
    IF v_sb < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance. Available: %, Requested: %', v_sb, p_amount; END IF;

    -- Perform Transfer
    UPDATE wallets SET available_balance = available_balance - p_amount WHERE id = v_sw;
    v_txn_out := uuid_generate_v4();
    INSERT INTO transactions (id, idempotency_key, user_id, wallet_id, type, amount, currency, status, counterpart_user_id, running_balance)
    VALUES (v_txn_out, p_idempotency_key||'_out', p_sender_id, v_sw, 'transfer_out', p_amount, 'USD', 'completed', p_receiver_id,
            (SELECT available_balance FROM wallets WHERE id = v_sw));

    UPDATE wallets SET available_balance = available_balance + p_amount WHERE id = v_rw;
    v_txn_in := uuid_generate_v4();
    INSERT INTO transactions (id, idempotency_key, user_id, wallet_id, type, amount, currency, status, counterpart_user_id, running_balance)
    VALUES (v_txn_in, p_idempotency_key||'_in', p_receiver_id, v_rw, 'transfer_in', p_amount, 'USD', 'completed', p_sender_id,
            (SELECT available_balance FROM wallets WHERE id = v_rw));

    -- Automated Notifications
    -- For Sender
    INSERT INTO notifications (user_id, title, message, type)
    VALUES (p_sender_id, 'تم التحويل بنجاح', 'لقد قمت بتحويل ' || p_amount || ' إلى ' || v_receiver_name, 'financial');

    -- For Receiver
    INSERT INTO notifications (user_id, title, message, type)
    VALUES (p_receiver_id, 'استلام حوالة', 'لقد استلمت ' || p_amount || ' من ' || v_sender_name, 'financial');

    RETURN v_txn_out;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Agent-Led Processing (Withdrawals & Deposits)
CREATE OR REPLACE FUNCTION public.fn_process_deposit(p_txn_id UUID, p_admin_id UUID DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_wallet_id UUID; v_amount NUMERIC(18,4); v_net NUMERIC(18,4); v_new_bal NUMERIC(18,4);
BEGIN
    IF NOT public.is_staff() THEN RAISE EXCEPTION 'Unauthorized: Staff access required'; END IF;
    SELECT wallet_id, amount, (amount - COALESCE(fee, 0)) INTO v_wallet_id, v_amount, v_net
    FROM transactions WHERE id = p_txn_id AND type = 'deposit' AND (status ILIKE 'pending') FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Transaction not eligible'; END IF;
    UPDATE wallets SET available_balance = available_balance + v_net WHERE id = v_wallet_id;
    SELECT available_balance INTO v_new_bal FROM wallets WHERE id = v_wallet_id;
    UPDATE transactions SET status = 'Approved', running_balance = v_new_bal,
        processed_by = auth.uid(), processed_at = CURRENT_TIMESTAMP WHERE id = p_txn_id;
    INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details, severity)
    VALUES (auth.uid(), 'Approve Deposit', 'transaction', p_txn_id::text, json_build_object('amount', v_amount)::jsonb, 'info');
    INSERT INTO notifications (user_id, title, message, type)
    SELECT user_id, 'تم الموافقة على الإيداع', 'تمت إضافة ' || v_amount || ' إلى محفظتك', 'financial'
    FROM transactions WHERE id = p_txn_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.approve_withdrawal(p_txn_id UUID, p_admin_id UUID DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_wallet_id UUID; v_amount NUMERIC(18,4); v_available NUMERIC(18,4); v_new_bal NUMERIC(18,4);
BEGIN
    IF NOT public.is_staff() THEN RAISE EXCEPTION 'Unauthorized: Staff access required'; END IF;
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
    INSERT INTO notifications (user_id, title, message, type)
    SELECT user_id, 'تم الموافقة على السحب', 'تم خصم ' || v_amount || ' من محفظتك بنجاح', 'financial'
    FROM transactions WHERE id = p_txn_id;
END;
$$;

-- 5. Agent-Led Rejections
CREATE OR REPLACE FUNCTION public.reject_withdrawal(p_txn_id UUID, p_admin_id UUID, p_reason TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NOT public.is_staff() THEN RAISE EXCEPTION 'Unauthorized: Staff access required'; END IF;
    UPDATE transactions SET status = 'Rejected', rejection_reason = p_reason,
        processed_by = auth.uid(), processed_at = CURRENT_TIMESTAMP
    WHERE id = p_txn_id AND (status ILIKE 'pending');
    IF NOT FOUND THEN RAISE EXCEPTION 'Transaction not rejectable'; END IF;
    -- Notification for rejection
    INSERT INTO notifications (user_id, title, message, type)
    SELECT user_id, 'تم رفض طلب السحب', 'السبب: ' || p_reason, 'financial'
    FROM transactions WHERE id = p_txn_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_reject_transaction(p_txn_id UUID, p_admin_id UUID, p_reason TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NOT public.is_staff() THEN RAISE EXCEPTION 'Unauthorized: Staff access required'; END IF;
    UPDATE transactions SET status = 'Rejected', rejection_reason = p_reason,
        processed_by = auth.uid(), processed_at = CURRENT_TIMESTAMP
    WHERE id = p_txn_id AND (status ILIKE 'pending');
    IF NOT FOUND THEN RAISE EXCEPTION 'Transaction not rejectable'; END IF;
END;
$$;
