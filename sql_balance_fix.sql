-- Fix fn_admin_add_balance and fn_admin_deduct_balance 
-- 1. Handle UUID id in system_settings by avoiding direct comparison
-- 2. Fetch and include wallet_id in transactions to satisfy NOT NULL constraint

CREATE OR REPLACE FUNCTION fn_admin_add_balance(
  p_user_id UUID,
  p_amount DECIMAL(18,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_wallet_id UUID;
BEGIN
  -- Security Guard
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  -- Check system freeze — using LIMIT 1 to avoid UUID vs Text comparison on ID
  IF EXISTS (SELECT 1 FROM system_settings WHERE system_freeze = true LIMIT 1) THEN
    RAISE EXCEPTION 'System is frozen — operation blocked';
  END IF;

  -- Fetch wallet_id for the user
  SELECT id INTO v_wallet_id FROM wallets WHERE user_id = p_user_id;
  
  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
  END IF;

  -- Atomic wallet update
  UPDATE wallets
  SET available_balance = available_balance + p_amount,
      updated_at = now()
  WHERE id = v_wallet_id;

  -- Log as transaction (Include wallet_id)
  INSERT INTO transactions (user_id, wallet_id, type, amount, status, description, created_at)
  VALUES (p_user_id, v_wallet_id, 'admin_credit', p_amount, 'Approved', 'إضافة رصيد بواسطة المدير', now());

  -- Activity Log
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details)
  VALUES (auth.uid(), 'Add Balance', 'wallet', p_user_id::text, 'Added ' || p_amount || ' to balance');
END;
$$;

CREATE OR REPLACE FUNCTION fn_admin_deduct_balance(
  p_user_id UUID,
  p_amount DECIMAL(18,2)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_wallet_id UUID;
  v_balance DECIMAL(18,2);
BEGIN
  -- Security Guard
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  -- Check system freeze
  IF EXISTS (SELECT 1 FROM system_settings WHERE system_freeze = true LIMIT 1) THEN
    RAISE EXCEPTION 'System is frozen — operation blocked';
  END IF;

  -- Fetch wallet_id and balance
  SELECT id, available_balance INTO v_wallet_id, v_balance 
  FROM wallets 
  WHERE user_id = p_user_id;
  
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

  -- Log as transaction (Include wallet_id)
  INSERT INTO transactions (user_id, wallet_id, type, amount, status, description, created_at)
  VALUES (p_user_id, v_wallet_id, 'admin_debit', p_amount, 'Approved', 'خصم رصيد بواسطة المدير', now());

  -- Activity Log
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details)
  VALUES (auth.uid(), 'Deduct Balance', 'wallet', p_user_id::text, 'Deducted ' || p_amount || ' from balance');
END;
$$;
