-- ═══════════════════════════════════════════════════════════════
-- Kasby FINAL Harmonization Script
-- Standardizes RPCs and ensures all required tables/columns exist.
-- Run this in the Supabase SQL Editor.
-- ═══════════════════════════════════════════════════════════════

DO $$ 
BEGIN
    -- 1. Standardize loan_status ENUM
    BEGIN
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'active';
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'overdue';
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'rejected';
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'approved';
        ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'partial_paid';
    EXCEPTION WHEN others THEN NULL;
    END;

    -- 2. Add remaining_amount to loans table if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'loans' AND column_name = 'remaining_amount') THEN
        ALTER TABLE public.loans ADD COLUMN remaining_amount NUMERIC(18, 4);
        UPDATE public.loans SET remaining_amount = total_due - paid_amount;
    END IF;

    -- 3. Create loan_repayments table if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loan_repayments') THEN
        CREATE TABLE public.loan_repayments (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            loan_id UUID REFERENCES public.loans(id) ON DELETE CASCADE,
            amount NUMERIC(18, 4) NOT NULL,
            payment_method TEXT DEFAULT 'cash',
            notes TEXT,
            receipt_id TEXT,
            type TEXT DEFAULT 'partial',
            recorded_by UUID REFERENCES auth.users(id),
            created_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

END $$;

-- 4. Standardized RPC for repayment
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
  v_new_paid NUMERIC;
  v_new_remaining NUMERIC;
BEGIN
  -- Update the loan record
  UPDATE public.loans
  SET 
    paid_amount = paid_amount + p_amount,
    updated_at = now()
  WHERE id = p_loan_id
  RETURNING paid_amount, total_due INTO v_new_paid, v_new_remaining;

  -- Update remaining_amount explicitly
  UPDATE public.loans
  SET remaining_amount = total_due - paid_amount,
      status = CASE 
                 WHEN (total_due - paid_amount) <= 0 THEN 'paid'::loan_status 
                 ELSE status 
               END
  WHERE id = p_loan_id;

  RETURN jsonb_build_object('success', true, 'new_paid', v_new_paid);
END;
$$;
