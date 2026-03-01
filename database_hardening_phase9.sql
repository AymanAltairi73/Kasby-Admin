-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHASE 9: Professional Database Security Hardening            ║
-- ║  Goal: Full Admin Oversight on Transactions & Check-ins     ║
-- ║  Architecture: Role-Based Access Control (RBAC)             ║
-- ╚══════════════════════════════════════════════════════════════╝

BEGIN;

-- ══════════════════════════════════════════════
-- 1. TRANSACTIONS SECURITY
-- ══════════════════════════════════════════════

-- Ensure RLS is enabled
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Add Admin policy for transactions
DROP POLICY IF EXISTS "Admins can manage all transactions" ON public.transactions;
CREATE POLICY "Admins can manage all transactions" ON public.transactions
    FOR ALL TO authenticated
    USING (public.is_admin());

-- ══════════════════════════════════════════════
-- 2. DAILY CHECK-INS SECURITY
-- ══════════════════════════════════════════════

-- Ensure RLS is enabled
ALTER TABLE public.daily_check_ins ENABLE ROW LEVEL SECURITY;

-- Add Admin policy for daily_check_ins
DROP POLICY IF EXISTS "Admins can manage all daily_check_ins" ON public.daily_check_ins;
CREATE POLICY "Admins can manage all daily_check_ins" ON public.daily_check_ins
    FOR ALL TO authenticated
    USING (public.is_admin());

-- ══════════════════════════════════════════════
-- 3. FINAL VERIFICATION OF PROFILES
-- ══════════════════════════════════════════════
-- Just a safety check to ensure profiles RLS is consistent with Phase 6
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

COMMIT;
