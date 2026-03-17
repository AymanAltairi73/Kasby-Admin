-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHASE 11: Ultimate Database Fix - SECURITY DEFINER         ║
-- ║  Goal: Fix remaining data-fetching issues and JOIN losses    ║
-- ║  NOTE: admin_profiles does NOT have full_name column         ║
-- ║        (it was dropped in professional_restructure_phase1)   ║
-- ╚══════════════════════════════════════════════════════════════╝

BEGIN;

-- ══════════════════════════════════════════════════════════════
-- SECTION 1: FIX ROLE-CHECKING FUNCTIONS (SECURITY DEFINER)
-- ══════════════════════════════════════════════════════════════

-- Drop get_my_role because its return type may differ
DROP FUNCTION IF EXISTS public.get_my_role();

-- No DROP for is_admin() or is_agent() — they have RLS policy dependencies.
-- CREATE OR REPLACE works because their return type (boolean) is unchanged.

-- Fix is_admin to bypass RLS
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_profiles 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Fix is_agent to bypass RLS
CREATE OR REPLACE FUNCTION public.is_agent()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.agents 
    WHERE user_id = auth.uid() 
    AND status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Recreate get_my_role with text return type
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text AS $$
BEGIN
  IF public.is_admin() THEN
    RETURN 'admin';
  END IF;
  IF public.is_agent() THEN
    RETURN 'agent';
  END IF;
  RETURN 'user';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- ══════════════════════════════════════════════════════════════
-- SECTION 2: THE "SPLIT PROFILE" BRIDGE FIX
-- admin_profiles does NOT have full_name (it was dropped).
-- We only need to ensure admins have a row in profiles.
-- If they already have a row, we just mark role = 'admin'.
-- If they don't, we create a minimal profile with empty name.
-- ══════════════════════════════════════════════════════════════

-- Bridge existing admins into profiles table
-- admin_profiles only has: id, role, is_active, last_login_at, last_login_ip, created_at, updated_at
INSERT INTO public.profiles (id, full_name, email, role, status, created_at)
SELECT 
  ap.id, 
  COALESCE(u.raw_user_meta_data ->> 'full_name', ''),
  COALESCE(u.email, ap.id::text || '@admin.kasby'),
  'admin',
  'active',
  ap.created_at
FROM public.admin_profiles ap
JOIN auth.users u ON u.id = ap.id
ON CONFLICT (id) DO UPDATE 
SET role = 'admin', status = 'active';

-- Sync trigger: when a new admin_profiles row is inserted,
-- ensure they also have a profiles row
CREATE OR REPLACE FUNCTION public.fn_sync_admin_to_profile()
RETURNS trigger AS $$
DECLARE
  v_email TEXT;
  v_name TEXT;
BEGIN
  -- Get email and name from auth.users
  SELECT email, COALESCE(raw_user_meta_data ->> 'full_name', '')
  INTO v_email, v_name
  FROM auth.users WHERE id = NEW.id;

  INSERT INTO public.profiles (id, full_name, email, role, status)
  VALUES (NEW.id, v_name, COALESCE(v_email, NEW.id::text || '@admin.kasby'), 'admin', 'active')
  ON CONFLICT (id) DO UPDATE SET role = 'admin';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_sync_admin_to_profile ON public.admin_profiles;
CREATE TRIGGER trg_sync_admin_to_profile
AFTER INSERT ON public.admin_profiles
FOR EACH ROW EXECUTE FUNCTION public.fn_sync_admin_to_profile();


-- ══════════════════════════════════════════════════════════════
-- SECTION 3: RE-APPLY CLEAN RLS POLICIES
-- Uses the now-fixed SECURITY DEFINER is_admin()
-- ══════════════════════════════════════════════════════════════

-- Standardizing profiles access
DROP POLICY IF EXISTS "p_admin_profiles" ON public.profiles;
CREATE POLICY "p_admin_profiles" ON public.profiles
    FOR ALL TO authenticated
    USING (public.is_admin());

-- Standardizing wallets access
DROP POLICY IF EXISTS "p_admin_wallets" ON public.wallets;
CREATE POLICY "p_admin_wallets" ON public.wallets
    FOR ALL TO authenticated
    USING (public.is_admin());

-- Standardizing transactions access
DROP POLICY IF EXISTS "p_admin_txns_select" ON public.transactions;
CREATE POLICY "p_admin_txns_select" ON public.transactions
    FOR ALL TO authenticated
    USING (public.is_admin());

COMMIT;

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  VERIFICATION QUERIES (Run after migration)                  ║
-- ╚══════════════════════════════════════════════════════════════╝

/*
-- 1. Check if admins are bridged:
SELECT id, full_name, role FROM public.profiles WHERE role = 'admin';

-- 2. Check if is_admin() works correctly:
SELECT public.is_admin();

-- 3. Check if JOINs now work:
SELECT t.*, p.full_name 
FROM transactions t
LEFT JOIN profiles p ON t.user_id = p.id
LIMIT 5;
*/
