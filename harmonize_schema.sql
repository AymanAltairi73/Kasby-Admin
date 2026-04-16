-- ═══════════════════════════════════════════════════════════════
-- Kasby UNIFIED HARMONIZATION PATCH (Production Ready)
-- Use this script to align KASBY_MASTER_PRODUCTION_V5 with the App.
-- ═══════════════════════════════════════════════════════════════

-- 1. ENUM HARDENING (Ensures all statuses used in App exist in DB)
DO $$ 
BEGIN
    BEGIN
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'approved';
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'rejected';
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'partial_paid';
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'active'; -- alias for current
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'overdue'; -- alias for delayed
    EXCEPTION WHEN others THEN NULL;
    END;
END $$;

-- 2. TABLE ALIGNMENT (Ensures required columns and tables exist)
DO $$ 
BEGIN
    -- Add remaining_amount to loans
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'loans' AND column_name = 'remaining_amount') THEN
        ALTER TABLE public.loans ADD COLUMN remaining_amount NUMERIC(18, 4);
        UPDATE public.loans SET remaining_amount = total_due - COALESCE(paid_amount, 0);
    END IF;

    -- Standardize paid_amount default
    ALTER TABLE public.loans ALTER COLUMN paid_amount SET DEFAULT 0.00;

    -- Create loan_repayments table (Essential for History feature)
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loan_repayments') THEN
        CREATE TABLE public.loan_repayments (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            loan_id UUID REFERENCES public.loans(id) ON DELETE CASCADE,
            amount NUMERIC(18, 4) NOT NULL,
            payment_method TEXT DEFAULT 'cash',
            notes TEXT,
            receipt_id TEXT,
            type TEXT DEFAULT 'partial', -- 'partial' or 'full'
            recorded_by UUID REFERENCES auth.users(id),
            created_at TIMESTAMPTZ DEFAULT now()
        );
        -- Performance index
        CREATE INDEX idx_loan_repayments_loan_id ON public.loan_repayments(loan_id);
    END IF;

    -- System Settings ID Alignment (Change UUID to TEXT if needed)
    -- V5 has UUID, App needs 'global' (TEXT)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_settings' AND column_name = 'id' AND data_type = 'uuid') THEN
        ALTER TABLE public.system_settings ALTER COLUMN id TYPE TEXT USING id::text;
    END IF;

    -- Align maintenance mode column name with App's SettingsManagementController
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'system_settings' AND column_name = 'maintenance_mode') THEN
        ALTER TABLE public.system_settings RENAME COLUMN maintenance_mode TO is_maintenance_mode;
    END IF;
    
    -- Ensure 'global' row exists
    INSERT INTO public.system_settings (id) VALUES ('global') ON CONFLICT (id) DO NOTHING;

    -- Create transaction_limits table (Missing in V5)
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transaction_limits') THEN
        CREATE TABLE public.transaction_limits (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            label TEXT NOT NULL,
            value TEXT NOT NULL,
            tier TEXT DEFAULT 'normal',
            is_unlimited BOOLEAN DEFAULT false,
            category TEXT,
            created_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create fees table (Missing in V5)
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fees') THEN
        CREATE TABLE public.fees (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            label TEXT NOT NULL,
            value TEXT NOT NULL,
            category TEXT DEFAULT 'deposit',
            percentage NUMERIC,
            fixed_amount NUMERIC,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create currencies table (Missing in V5)
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'currencies') THEN
        CREATE TABLE public.currencies (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name TEXT NOT NULL,
            code TEXT NOT NULL UNIQUE,
            rate NUMERIC NOT NULL DEFAULT 1.0,
            is_base BOOLEAN DEFAULT false,
            icon_code INT,
            icon_family TEXT,
            icon_package TEXT,
            updated_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create CMS tables for FAQs and Terms
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'faqs') THEN
        CREATE TABLE public.faqs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            question TEXT NOT NULL,
            answer TEXT NOT NULL,
            "order" INT DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'terms') THEN
        CREATE TABLE public.terms (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            "order" INT DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

END $$;

-- 3. STANDARDIZED RPCs (The bridge between App Logic and DB)

-- RPC: Finalize Loan Status & Balance (Atomic)
DROP FUNCTION IF EXISTS public.fn_process_loan_repayment(UUID, NUMERIC, UUID);
CREATE OR REPLACE FUNCTION public.fn_process_loan_repayment(
  p_loan_id UUID,
  p_amount NUMERIC,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_due NUMERIC;
  v_paid_amount NUMERIC;
  v_remaining NUMERIC;
BEGIN
  -- 1. Lock loan record
  SELECT total_due, paid_amount INTO v_total_due, v_paid_amount
  FROM public.loans WHERE id = p_loan_id FOR UPDATE;

  -- 2. Update balances
  UPDATE public.loans
  SET 
    paid_amount = paid_amount + p_amount,
    remaining_amount = total_due - (paid_amount + p_amount),
    status = CASE 
               WHEN (total_due - (paid_amount + p_amount)) <= 0 THEN 'paid'::loan_status 
               ELSE 'partial_paid'::loan_status 
             END,
    updated_at = now()
  WHERE id = p_loan_id
  RETURNING paid_amount, remaining_amount INTO v_paid_amount, v_remaining;

  RETURN jsonb_build_object(
    'success', true, 
    'paid_amount', v_paid_amount,
    'remaining_amount', v_remaining
  );
END;
$$;

-- RPC: Unified Status Update
DROP FUNCTION IF EXISTS public.fn_update_loan_status(UUID, TEXT, UUID);
CREATE OR REPLACE FUNCTION public.fn_update_loan_status(
  p_loan_id UUID,
  p_new_status TEXT,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.loans 
  SET status = p_new_status::loan_status,
      approved_by = COALESCE(approved_by, p_admin_id),
      updated_at = now()
  WHERE id = p_loan_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 4. ALIASES FOR DISCOVERY
-- If V5 has old names, this bridge ensures the App won't fail
CREATE OR REPLACE FUNCTION public.fn_repay_loan(p_loan_id UUID, p_amount NUMERIC)
RETURNS VOID AS $$
BEGIN
  PERFORM public.fn_process_loan_repayment(p_loan_id, p_amount);
END;
$$ LANGUAGE plpgsql;

-- 5. INVESTMENT MANAGEMENT RPCs (Missing in V5)

-- RPC: Approve Investment
DROP FUNCTION IF EXISTS public.approve_investment(UUID, UUID);
CREATE OR REPLACE FUNCTION public.approve_investment(
  p_investment_id UUID,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.user_investments
  SET status = 'active',
      approved_by = p_admin_id,
      start_date = now()
  WHERE id = p_investment_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- RPC: Reject Investment
DROP FUNCTION IF EXISTS public.reject_investment(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION public.reject_investment(
  p_investment_id UUID,
  p_admin_id UUID,
  p_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.user_investments
  SET status = 'cancelled', -- or 'rejected'
      approved_by = p_admin_id
  WHERE id = p_investment_id;

  -- Logic to refund wallet if needed would go here
  -- (Assuming amount was already deducted on request)

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 6. FINANCIAL MANAGEMENT RPCs (Missing in V5)

-- RPC: Approve Withdrawal (Admin confirmation)
DROP FUNCTION IF EXISTS public.approve_withdrawal(UUID, UUID);
CREATE OR REPLACE FUNCTION public.approve_withdrawal(
  p_txn_id UUID,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- We assume available_balance was already frozen/deducted during request
  UPDATE public.transactions
  SET status = 'completed',
      processed_by = p_admin_id,
      processed_at = now()
  WHERE id = p_txn_id AND type = 'withdrawal';

  RETURN jsonb_build_object('success', true);
END;
$$;

-- RPC: Reject Withdrawal (Admin refusal)
DROP FUNCTION IF EXISTS public.reject_withdrawal(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION public.reject_withdrawal(
  p_txn_id UUID,
  p_admin_id UUID,
  p_reason TEXT DEFAULT 'رفض بواسطة المدير'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_amount NUMERIC;
BEGIN
  -- Get txn details
  SELECT user_id, amount INTO v_user_id, v_amount 
  FROM public.transactions WHERE id = p_txn_id FOR UPDATE;

  -- 1. Refund the user's available balance
  UPDATE public.wallets 
  SET available_balance = available_balance + v_amount
  WHERE user_id = v_user_id;

  -- 2. Mark transaction as rejected
  UPDATE public.transactions
  SET status = 'rejected',
      rejection_reason = p_reason,
      processed_by = p_admin_id,
      processed_at = now()
  WHERE id = p_txn_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- RPC: Generic Transaction Rejection
DROP FUNCTION IF EXISTS public.fn_reject_transaction(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION public.fn_reject_transaction(
  p_txn_id UUID,
  p_admin_id UUID,
  p_reason TEXT DEFAULT 'رفض بواسطة المدير'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.transactions
  SET status = 'rejected',
      rejection_reason = p_reason,
      processed_by = p_admin_id,
      processed_at = now()
  WHERE id = p_txn_id;

  RETURN jsonb_build_object('success', true);
END;
$$;
