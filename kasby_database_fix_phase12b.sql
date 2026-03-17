-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHASE 12b: Fix is_admin() + fn_admin_dashboard             ║
-- ║  Problem: is_admin() only checks admin_profiles              ║
-- ║  but some admins are identified via raw_app_meta_data        ║
-- ╚══════════════════════════════════════════════════════════════╝

BEGIN;

-- ══════════════════════════════════════════════════════════════
-- FIX 1: is_admin() — Check BOTH admin_profiles AND app_metadata
-- This ensures admins are recognized regardless of how they were created
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  -- Check 1: Does this user have a row in admin_profiles?
  IF EXISTS (SELECT 1 FROM public.admin_profiles WHERE id = auth.uid()) THEN
    RETURN TRUE;
  END IF;
  
  -- Check 2: Does auth.users.raw_app_meta_data have is_admin = true?
  IF COALESCE(
    (SELECT (raw_app_meta_data ->> 'is_admin')::boolean 
     FROM auth.users WHERE id = auth.uid()),
    FALSE
  ) THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- ══════════════════════════════════════════════════════════════
-- FIX 2: fn_admin_dashboard — Already SECURITY DEFINER, just
-- ensure it works with the updated is_admin()
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION fn_admin_dashboard()
RETURNS TABLE (
    total_users BIGINT, active_users BIGINT, pending_kyc BIGINT,
    total_balance NUMERIC, total_invested NUMERIC,
    pending_txns BIGINT, active_loans BIGINT, delayed_loans BIGINT, active_agents BIGINT
) AS $$
BEGIN
    -- Guard: only admins can call this
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin access required';
    END IF;

    RETURN QUERY SELECT
        (SELECT COUNT(*) FROM profiles),
        (SELECT COUNT(*) FROM profiles WHERE status = 'active'),
        (SELECT COUNT(*) FROM profiles WHERE kyc_status = 'pending'),
        (SELECT COALESCE(SUM(available_balance),0) FROM wallets),
        (SELECT COALESCE(SUM(invested_balance),0) FROM wallets),
        (SELECT COUNT(*) FROM transactions WHERE status = 'pending'),
        (SELECT COUNT(*) FROM loans WHERE status = 'current'),
        (SELECT COUNT(*) FROM loans WHERE status = 'delayed'),
        (SELECT COUNT(*) FROM agents WHERE status = 'active');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- ══════════════════════════════════════════════════════════════
-- FIX 3: Ensure activity_logs.actor_id has a usable FK to profiles
-- Original FK goes to auth.users — PostgREST can't resolve cross-schema FKs
-- We add an additional FK to profiles for Supabase compatibility
-- ══════════════════════════════════════════════════════════════

-- Note: This may fail if actor_id values don't all exist in profiles.
-- That's OK — the Dart code now has a fallback manual lookup.
DO $$
BEGIN
  -- Only add if the constraint doesn't already exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_activity_logs_actor_profile'
    AND table_name = 'activity_logs'
  ) THEN
    BEGIN
      ALTER TABLE public.activity_logs
        ADD CONSTRAINT fk_activity_logs_actor_profile
        FOREIGN KEY (actor_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
    EXCEPTION WHEN OTHERS THEN
      -- If there are actor_ids not in profiles, skip the FK
      RAISE NOTICE 'Could not add FK to profiles — some actor_ids may not exist in profiles. Dart fallback will handle this.';
    END;
  END IF;
END $$;


COMMIT;

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  VERIFICATION                                                ║
-- ╚══════════════════════════════════════════════════════════════╝
/*
-- 1. Test is_admin() works:
SELECT public.is_admin();

-- 2. Test dashboard:
SELECT * FROM fn_admin_dashboard();

-- 3. Check activity_logs FKs:
SELECT conname, confrelid::regclass 
FROM pg_constraint 
WHERE conrelid = 'activity_logs'::regclass AND contype = 'f';
*/
