-- ═══════════════════════════════════════════════════════════════
-- Kasby Admin Loan RPC Bridge
-- This script adds missing stored procedures for loan management.
-- Run this in the Supabase SQL Editor.
-- ═══════════════════════════════════════════════════════════════

-- 1. REJECT LOAN
-- Handles loan rejection with a reason and activity logging.
CREATE OR REPLACE FUNCTION fn_reject_loan(
  p_loan_id UUID,
  p_admin_id UUID,
  p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Security Guard: Only admins can reject loans
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Update loan status
  UPDATE loans
  SET status = 'rejected',
      rejection_reason = p_reason,
      updated_at = now()
  WHERE id = p_loan_id;

  -- Guard: Ensure loan exists and was updateable
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Loan not found: %', p_loan_id;
  END IF;

  -- Activity Log
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details)
  VALUES (p_admin_id, 'Reject Loan', 'loan', p_loan_id::text, 'Reason: ' || p_reason);
END;
$$;

-- 2. UPDATE LOAN STATUS
-- Handles general status updates (e.g., manual corrections) and activity logging.
CREATE OR REPLACE FUNCTION fn_update_loan_status(
  p_loan_id UUID,
  p_admin_id UUID,
  p_new_status TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_old_status TEXT;
BEGIN
  -- Security Guard
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Get old status for logging
  SELECT status INTO v_old_status FROM loans WHERE id = p_loan_id;

  -- Update loan status
  UPDATE loans
  SET status = p_new_status,
      updated_at = now()
  WHERE id = p_loan_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Loan not found';
  END IF;

  -- Activity Log
  INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, details)
  VALUES (p_admin_id, 'Update Loan Status', 'loan', p_loan_id::text, 'Status changed from ' || v_old_status || ' to ' || p_new_status);
END;
$$;
