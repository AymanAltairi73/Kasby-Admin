-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHASE 12: Missing Admin Policies + Duplicate Cleanup       ║
-- ║  Fixes: Tables admins WRITE TO but have NO admin policy     ║
-- ║  CRITICAL: investment_plans, fees, currencies, system_settings║
-- ╚══════════════════════════════════════════════════════════════╝

BEGIN;

-- ══════════════════════════════════════════════════════════════
-- SECTION 1: ADD MISSING ADMIN MANAGEMENT POLICIES
-- These tables are actively used by admin panel but have
-- NO admin-level INSERT/UPDATE/DELETE policy!
-- ══════════════════════════════════════════════════════════════

-- ─── 1.1 investment_plans ───
-- PROBLEM: Only has "Anyone can view active plans" → 
--   1) Admins CANNOT insert/update/delete plans
--   2) If policy filters by is_active=true, admins can't see inactive plans
ALTER TABLE public.investment_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p12_investment_plans_admin_all" ON public.investment_plans;
CREATE POLICY "p12_investment_plans_admin_all" ON public.investment_plans
    FOR ALL TO authenticated
    USING (public.is_admin());

-- Keep the public read policy for active plans (users need this)
-- "Anyone can view active plans" → stays as-is

-- ─── 1.2 fees ───
-- PROBLEM: Only has "Anyone can view fees" → admins CANNOT insert/update/delete
ALTER TABLE public.fees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p12_fees_admin_all" ON public.fees;
CREATE POLICY "p12_fees_admin_all" ON public.fees
    FOR ALL TO authenticated
    USING (public.is_admin());

-- ─── 1.3 currencies ───
-- PROBLEM: Only has "Anyone can view currencies" → admins CANNOT insert/delete
ALTER TABLE public.currencies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p12_currencies_admin_all" ON public.currencies;
CREATE POLICY "p12_currencies_admin_all" ON public.currencies
    FOR ALL TO authenticated
    USING (public.is_admin());

-- ─── 1.4 system_settings ───
-- PROBLEM: Only has "Anyone can view system settings" → admins CANNOT update
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p12_system_settings_admin_all" ON public.system_settings;
CREATE POLICY "p12_system_settings_admin_all" ON public.system_settings
    FOR ALL TO authenticated
    USING (public.is_admin());

-- ─── 1.5 activity_logs ───
-- Has "Admin scan activity" for SELECT, but no INSERT for admin dashboard logging
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p12_activity_logs_admin_all" ON public.activity_logs;
CREATE POLICY "p12_activity_logs_admin_all" ON public.activity_logs
    FOR ALL TO authenticated
    USING (public.is_admin());

-- ─── 1.6 point_history ───
-- Has user-level policies but no admin management policy
DROP POLICY IF EXISTS "p12_point_history_admin_all" ON public.point_history;
CREATE POLICY "p12_point_history_admin_all" ON public.point_history
    FOR ALL TO authenticated
    USING (public.is_admin());


-- ══════════════════════════════════════════════════════════════
-- SECTION 2: CLEANUP REMAINING DUPLICATE POLICIES
-- Phase 10 was executed but the DB dump was taken BEFORE it.
-- These drops are safe (IF EXISTS) — they do nothing if already gone.
-- ══════════════════════════════════════════════════════════════

-- profiles duplicates
DROP POLICY IF EXISTS "Admin full access" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users update own" ON public.profiles;
DROP POLICY IF EXISTS "Users view own" ON public.profiles;

-- wallets duplicates
DROP POLICY IF EXISTS "Admin scan wallets" ON public.wallets;
DROP POLICY IF EXISTS "User view wallet" ON public.wallets;
DROP POLICY IF EXISTS "Users can view own wallet" ON public.wallets;
DROP POLICY IF EXISTS "Users can view their own wallet" ON public.wallets;

-- transactions duplicates
DROP POLICY IF EXISTS "Admin scan txns" ON public.transactions;
DROP POLICY IF EXISTS "Admins can manage all transactions" ON public.transactions;
DROP POLICY IF EXISTS "User insert requests" ON public.transactions;
DROP POLICY IF EXISTS "User view txns" ON public.transactions;
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;

-- notifications duplicates
DROP POLICY IF EXISTS "Admin scan notifs" ON public.notifications;
DROP POLICY IF EXISTS "User view notifs" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;

-- agents duplicates
DROP POLICY IF EXISTS "Admin scan agents" ON public.agents;
DROP POLICY IF EXISTS "Agent view self" ON public.agents;

-- user_investments duplicates
DROP POLICY IF EXISTS "Admin scan investments" ON public.user_investments;
DROP POLICY IF EXISTS "User view investments" ON public.user_investments;
DROP POLICY IF EXISTS "Users can view own investments" ON public.user_investments;

-- loans duplicates
DROP POLICY IF EXISTS "Admin scan loans" ON public.loans;
DROP POLICY IF EXISTS "User view loans" ON public.loans;
DROP POLICY IF EXISTS "Users can view own loans" ON public.loans;

-- daily_check_ins duplicates
DROP POLICY IF EXISTS "Admin scan checkins" ON public.daily_check_ins;
DROP POLICY IF EXISTS "Admins can manage all daily_check_ins" ON public.daily_check_ins;
DROP POLICY IF EXISTS "Public check-ins are viewable by owner" ON public.daily_check_ins;
DROP POLICY IF EXISTS "User insert checkin" ON public.daily_check_ins;
DROP POLICY IF EXISTS "User view checkins" ON public.daily_check_ins;
DROP POLICY IF EXISTS "Users can view own check-ins" ON public.daily_check_ins;

-- user_points duplicates
DROP POLICY IF EXISTS "Admin scan points" ON public.user_points;
DROP POLICY IF EXISTS "User view points" ON public.user_points;
DROP POLICY IF EXISTS "Users can view own points" ON public.user_points;

-- point_history duplicates
DROP POLICY IF EXISTS "Admin scan point_history" ON public.point_history;
DROP POLICY IF EXISTS "User view point_history" ON public.point_history;
DROP POLICY IF EXISTS "Users can view own point history" ON public.point_history;

-- subscriptions duplicates
DROP POLICY IF EXISTS "Admin scan subs" ON public.subscriptions;
DROP POLICY IF EXISTS "User view subs" ON public.subscriptions;
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.subscriptions;

-- kyc_documents duplicates
DROP POLICY IF EXISTS "Admin scan kyc" ON public.kyc_documents;
DROP POLICY IF EXISTS "User upload kyc" ON public.kyc_documents;
DROP POLICY IF EXISTS "User view kyc" ON public.kyc_documents;
DROP POLICY IF EXISTS "Users can insert own KYC docs" ON public.kyc_documents;
DROP POLICY IF EXISTS "Users can view own KYC docs" ON public.kyc_documents;

-- chat duplicates
DROP POLICY IF EXISTS "Admin scan chats" ON public.chat_conversations;
DROP POLICY IF EXISTS "User view own chats" ON public.chat_conversations;
DROP POLICY IF EXISTS "Admin scan messages" ON public.chat_messages;
DROP POLICY IF EXISTS "User view chat messages" ON public.chat_messages;

-- spin_results duplicates
DROP POLICY IF EXISTS "Admin scan spins" ON public.spin_results;
DROP POLICY IF EXISTS "User view spins" ON public.spin_results;

-- activity_logs duplicates
DROP POLICY IF EXISTS "Admin scan activity" ON public.activity_logs;


-- ══════════════════════════════════════════════════════════════
-- SECTION 3: ADD MISSING USER-LEVEL POLICIES FOR daily_check_ins
-- After cleanup, ensure users can still insert and view their check-ins
-- ══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "p12_checkins_user_select" ON public.daily_check_ins;
CREATE POLICY "p12_checkins_user_select" ON public.daily_check_ins
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "p12_checkins_user_insert" ON public.daily_check_ins;
CREATE POLICY "p12_checkins_user_insert" ON public.daily_check_ins
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Admin management for daily_check_ins
DROP POLICY IF EXISTS "p12_checkins_admin_all" ON public.daily_check_ins;
CREATE POLICY "p12_checkins_admin_all" ON public.daily_check_ins
    FOR ALL TO authenticated
    USING (public.is_admin());

-- ══════════════════════════════════════════════════════════════
-- SECTION 4: FIX NOTIFICATION USER POLICY (Dual user columns)
-- notifications has both user_id and target_user_id
-- Current p_user_select_notif may only check user_id
-- ══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "p_user_select_notif" ON public.notifications;
CREATE POLICY "p_user_select_notif" ON public.notifications
    FOR SELECT TO authenticated
    USING (
      user_id = auth.uid() 
      OR target_user_id = auth.uid()
      OR target = 'all'
    );

-- Ensure admin can manage all notifications
DROP POLICY IF EXISTS "p12_notif_admin_all" ON public.notifications;
CREATE POLICY "p12_notif_admin_all" ON public.notifications
    FOR ALL TO authenticated
    USING (public.is_admin());


-- ══════════════════════════════════════════════════════════════
-- SECTION 5: ADMIN POLICIES FOR admin_profiles, admin_sessions, audit_logs
-- ══════════════════════════════════════════════════════════════

-- audit_logs: admin needs full access for dashboard
DROP POLICY IF EXISTS "p12_audit_logs_admin_all" ON public.audit_logs;
CREATE POLICY "p12_audit_logs_admin_all" ON public.audit_logs
    FOR ALL TO authenticated
    USING (public.is_admin());

-- admin_sessions: admin needs to view sessions
DROP POLICY IF EXISTS "p12_admin_sessions_admin_all" ON public.admin_sessions;
CREATE POLICY "p12_admin_sessions_admin_all" ON public.admin_sessions
    FOR ALL TO authenticated
    USING (public.is_admin());


COMMIT;

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  VERIFICATION (Run after migration)                          ║
-- ╚══════════════════════════════════════════════════════════════╝

/*
-- 1. Count policies per table (should be 2-4 each, no duplicates):
SELECT tablename, COUNT(*) as policy_count 
FROM pg_policies WHERE schemaname = 'public' 
GROUP BY tablename ORDER BY policy_count DESC;

-- 2. Test admin can read/write investment_plans:
-- Run as admin user:
SELECT * FROM investment_plans; -- Should show ALL plans (active + inactive)

-- 3. Test admin can manage fees:
SELECT * FROM fees;

-- 4. Test admin can manage system_settings:
SELECT * FROM system_settings;
*/
