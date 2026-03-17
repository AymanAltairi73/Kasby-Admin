-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHASE 10: Complete Database Fix — RLS, Policies, Triggers   ║
-- ║  Goal: Fix ALL data-fetching issues                         ║
-- ║  Fixes: Missing policies, duplicates, SECURITY DEFINER,    ║
-- ║         duplicate triggers, duplicate indexes               ║
-- ╚══════════════════════════════════════════════════════════════╝

BEGIN;

-- ══════════════════════════════════════════════════════════════
-- SECTION 1: ENABLE RLS + ADD MISSING SELECT POLICIES
-- These tables have RLS enabled but NO SELECT policy → returns 0 rows
-- ══════════════════════════════════════════════════════════════

-- ─── 1.1 admin_profiles ───
ALTER TABLE public.admin_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_admin_profiles_select" ON public.admin_profiles;
CREATE POLICY "p10_admin_profiles_select" ON public.admin_profiles
    FOR SELECT TO authenticated
    USING (
        auth.uid() = id
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "p10_admin_profiles_all" ON public.admin_profiles;
CREATE POLICY "p10_admin_profiles_all" ON public.admin_profiles
    FOR ALL TO authenticated
    USING (public.is_admin());

-- ─── 1.2 admin_sessions ───
ALTER TABLE public.admin_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_admin_sessions_select" ON public.admin_sessions;
CREATE POLICY "p10_admin_sessions_select" ON public.admin_sessions
    FOR SELECT TO authenticated
    USING (
        admin_id = auth.uid()
        OR public.is_admin()
    );

-- ─── 1.3 ads ───
ALTER TABLE public.ads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_ads_select" ON public.ads;
CREATE POLICY "p10_ads_select" ON public.ads
    FOR SELECT USING (true);  -- Public: anyone can view ads

DROP POLICY IF EXISTS "p10_ads_admin_all" ON public.ads;
CREATE POLICY "p10_ads_admin_all" ON public.ads
    FOR ALL TO authenticated
    USING (public.is_admin());

-- ─── 1.4 audit_logs (still exists in DB, used by audit_logger.dart) ───
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_audit_logs_select" ON public.audit_logs;
CREATE POLICY "p10_audit_logs_select" ON public.audit_logs
    FOR SELECT TO authenticated
    USING (public.is_admin());

DROP POLICY IF EXISTS "p10_audit_logs_insert" ON public.audit_logs;
CREATE POLICY "p10_audit_logs_insert" ON public.audit_logs
    FOR INSERT TO authenticated
    WITH CHECK (admin_id = auth.uid() OR public.is_admin());

-- ─── 1.5 countries ───
ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_countries_select" ON public.countries;
CREATE POLICY "p10_countries_select" ON public.countries
    FOR SELECT USING (true);  -- Public reference table

-- ─── 1.6 enum_translations ───
ALTER TABLE public.enum_translations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_enum_translations_select" ON public.enum_translations;
CREATE POLICY "p10_enum_translations_select" ON public.enum_translations
    FOR SELECT USING (true);  -- Public reference table

-- ─── 1.7 faqs ───
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_faqs_select" ON public.faqs;
CREATE POLICY "p10_faqs_select" ON public.faqs
    FOR SELECT USING (true);  -- Public content

-- ─── 1.8 point_rules ───
ALTER TABLE public.point_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_point_rules_select" ON public.point_rules;
CREATE POLICY "p10_point_rules_select" ON public.point_rules
    FOR SELECT USING (true);  -- Public: users need to see rules

-- ─── 1.9 prizes ───
ALTER TABLE public.prizes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_prizes_select" ON public.prizes;
CREATE POLICY "p10_prizes_select" ON public.prizes
    FOR SELECT USING (true);  -- Public: users can see available prizes

-- ─── 1.10 rewards ───
ALTER TABLE public.rewards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_rewards_select" ON public.rewards;
CREATE POLICY "p10_rewards_select" ON public.rewards
    FOR SELECT TO authenticated
    USING (true);  -- Authenticated users can see rewards

-- ─── 1.11 spin_wheel_rewards ───
ALTER TABLE public.spin_wheel_rewards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_spin_wheel_rewards_select" ON public.spin_wheel_rewards;
CREATE POLICY "p10_spin_wheel_rewards_select" ON public.spin_wheel_rewards
    FOR SELECT USING (true);  -- Public: spin wheel config

-- ─── 1.12 subscription_plans ───
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_subscription_plans_select" ON public.subscription_plans;
CREATE POLICY "p10_subscription_plans_select" ON public.subscription_plans
    FOR SELECT USING (true);  -- Public: users browse plans

-- ─── 1.13 support_conversations ───
ALTER TABLE public.support_conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_support_conversations_select" ON public.support_conversations;
CREATE POLICY "p10_support_conversations_select" ON public.support_conversations
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid()
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "p10_support_conversations_insert" ON public.support_conversations;
CREATE POLICY "p10_support_conversations_insert" ON public.support_conversations
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- ─── 1.14 support_messages ───
ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_support_messages_select" ON public.support_messages;
CREATE POLICY "p10_support_messages_select" ON public.support_messages
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.support_conversations sc
            WHERE sc.id = conversation_id
            AND (sc.user_id = auth.uid() OR public.is_admin())
        )
    );

DROP POLICY IF EXISTS "p10_support_messages_insert" ON public.support_messages;
CREATE POLICY "p10_support_messages_insert" ON public.support_messages
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.support_conversations sc
            WHERE sc.id = conversation_id
            AND (sc.user_id = auth.uid() OR public.is_admin())
        )
    );

-- ─── 1.15 terms_sections ───
ALTER TABLE public.terms_sections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_terms_sections_select" ON public.terms_sections;
CREATE POLICY "p10_terms_sections_select" ON public.terms_sections
    FOR SELECT USING (true);  -- Public legal content

-- ─── 1.16 transaction_limits ───
ALTER TABLE public.transaction_limits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_transaction_limits_select" ON public.transaction_limits;
CREATE POLICY "p10_transaction_limits_select" ON public.transaction_limits
    FOR SELECT USING (true);  -- Public: users need to know limits

-- ─── 1.17 user_activities ───
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_user_activities_select" ON public.user_activities;
CREATE POLICY "p10_user_activities_select" ON public.user_activities
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid()
        OR public.is_admin()
    );

-- ─── 1.18 otp_rate_limits (internal, admin only) ───
ALTER TABLE public.otp_rate_limits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_otp_rate_limits_select" ON public.otp_rate_limits;
CREATE POLICY "p10_otp_rate_limits_select" ON public.otp_rate_limits
    FOR SELECT TO authenticated
    USING (public.is_admin());

-- ─── 1.19 phone_otps (internal, admin only) ───
ALTER TABLE public.phone_otps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p10_phone_otps_select" ON public.phone_otps;
CREATE POLICY "p10_phone_otps_select" ON public.phone_otps
    FOR SELECT TO authenticated
    USING (public.is_admin());


-- ══════════════════════════════════════════════════════════════
-- SECTION 2: CLEAN UP DUPLICATE RLS POLICIES
-- Removes old/duplicate policies, keeps the p_* prefixed clean ones
-- ══════════════════════════════════════════════════════════════

-- ─── 2.1 profiles — Remove duplicates (keep: p_admin_profiles, p_user_select_profile, p_user_update_profile, "Anyone can view profiles of active agents") ───
DROP POLICY IF EXISTS "Admin full access" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users update own" ON public.profiles;
DROP POLICY IF EXISTS "Users view own" ON public.profiles;
-- Phase 6 policies (superseded by p_* policies):
DROP POLICY IF EXISTS "Admins can do everything on profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own basic info" ON public.profiles;

-- ─── 2.2 wallets — Remove duplicates (keep: p_admin_wallets, p_user_select_wallet) ───
DROP POLICY IF EXISTS "Admin scan wallets" ON public.wallets;
DROP POLICY IF EXISTS "User view wallet" ON public.wallets;
DROP POLICY IF EXISTS "Users can view own wallet" ON public.wallets;
DROP POLICY IF EXISTS "Users can view their own wallet" ON public.wallets;
-- Phase 6 policies:
DROP POLICY IF EXISTS "Admins can view all wallets" ON public.wallets;

-- ─── 2.3 transactions — Remove duplicates (keep: p_admin_txns_select, p_admin_txns_insert, p_user_select_txn, p_user_insert_txn) ───
DROP POLICY IF EXISTS "Admin scan txns" ON public.transactions;
DROP POLICY IF EXISTS "User insert requests" ON public.transactions;
DROP POLICY IF EXISTS "User view txns" ON public.transactions;
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
-- Phase 9 policy:
DROP POLICY IF EXISTS "Admins can manage all transactions" ON public.transactions;

-- ─── 2.4 notifications — Remove duplicates (keep: p_admin_notif, p_user_select_notif) ───
DROP POLICY IF EXISTS "Admin scan notifs" ON public.notifications;
DROP POLICY IF EXISTS "User view notifs" ON public.notifications;
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;

-- Add update policy for notifications (user marks as read)
DROP POLICY IF EXISTS "p10_notif_user_update" ON public.notifications;
CREATE POLICY "p10_notif_user_update" ON public.notifications
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR target_user_id = auth.uid())
    WITH CHECK (user_id = auth.uid() OR target_user_id = auth.uid());

-- ─── 2.5 daily_check_ins — Remove duplicates (keep: "Admin scan checkins", "User insert checkin", "User view checkins") ───
DROP POLICY IF EXISTS "Public check-ins are viewable by owner" ON public.daily_check_ins;
DROP POLICY IF EXISTS "Users can view own check-ins" ON public.daily_check_ins;
-- Phase 9 policy:
DROP POLICY IF EXISTS "Admins can manage all daily_check_ins" ON public.daily_check_ins;

-- ─── 2.6 kyc_documents — Remove duplicates (keep: p_admin_kyc, p_user_select_kyc, p_user_insert_kyc) ───
DROP POLICY IF EXISTS "Admin scan kyc" ON public.kyc_documents;
DROP POLICY IF EXISTS "User upload kyc" ON public.kyc_documents;
DROP POLICY IF EXISTS "User view kyc" ON public.kyc_documents;
DROP POLICY IF EXISTS "Users can insert own KYC docs" ON public.kyc_documents;
DROP POLICY IF EXISTS "Users can view own KYC docs" ON public.kyc_documents;

-- ─── 2.7 user_investments — Remove duplicates (keep: p_admin_investments, p_user_select_inv) ───
DROP POLICY IF EXISTS "Admin scan investments" ON public.user_investments;
DROP POLICY IF EXISTS "User view investments" ON public.user_investments;
DROP POLICY IF EXISTS "Users can view own investments" ON public.user_investments;

-- ─── 2.8 loans — Remove duplicates (keep: p_admin_loans, p_user_select_loans) ───
DROP POLICY IF EXISTS "Admin scan loans" ON public.loans;
DROP POLICY IF EXISTS "User view loans" ON public.loans;
DROP POLICY IF EXISTS "Users can view own loans" ON public.loans;

-- ─── 2.9 subscriptions — Remove duplicates (keep: p_admin_sub, p_user_select_sub) ───
DROP POLICY IF EXISTS "Admin scan subs" ON public.subscriptions;
DROP POLICY IF EXISTS "User view subs" ON public.subscriptions;
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.subscriptions;

-- ─── 2.10 user_points — Remove duplicates (keep: p_admin_points, p_user_select_points) ───
DROP POLICY IF EXISTS "Admin scan points" ON public.user_points;
DROP POLICY IF EXISTS "User view points" ON public.user_points;
DROP POLICY IF EXISTS "Users can view own points" ON public.user_points;

-- ─── 2.11 point_history — Remove duplicates (keep two clean ones) ───
DROP POLICY IF EXISTS "Admin scan point_history" ON public.point_history;
DROP POLICY IF EXISTS "Users can view own point history" ON public.point_history;

-- ─── 2.12 chat_conversations — Remove duplicates (keep: p_admin_convs, p_user_select_conv) ───
DROP POLICY IF EXISTS "Admin scan chats" ON public.chat_conversations;
DROP POLICY IF EXISTS "User view own chats" ON public.chat_conversations;

-- ─── 2.13 chat_messages — Remove duplicates (keep: p_admin_msgs, p_user_select_msg, p_user_insert_msg) ───
DROP POLICY IF EXISTS "Admin scan messages" ON public.chat_messages;
DROP POLICY IF EXISTS "User view chat messages" ON public.chat_messages;

-- ─── 2.14 spin_results — Remove duplicates (keep: p_admin_spin, p_user_select_spin) ───
DROP POLICY IF EXISTS "Admin scan spins" ON public.spin_results;
DROP POLICY IF EXISTS "User view spins" ON public.spin_results;

-- ─── 2.15 agents — Remove duplicates (keep: "Anyone can view active agents", "Agents can view their own metadata") ───
DROP POLICY IF EXISTS "Admin scan agents" ON public.agents;
DROP POLICY IF EXISTS "Agent view self" ON public.agents;
-- Phase 6 policy:
DROP POLICY IF EXISTS "Admins can manage agents" ON public.agents;

-- Add back clean admin policy for agents
DROP POLICY IF EXISTS "p10_agents_admin_all" ON public.agents;
CREATE POLICY "p10_agents_admin_all" ON public.agents
    FOR ALL TO authenticated
    USING (public.is_admin());


-- ══════════════════════════════════════════════════════════════
-- SECTION 3: FIX fn_admin_dashboard — SECURITY DEFINER
-- Ensures the dashboard RPC can read across RLS-protected tables
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
-- SECTION 4: CLEAN UP DUPLICATE TRIGGERS
-- Each table should have ONE updated_at trigger, not two
-- ══════════════════════════════════════════════════════════════

-- agents: keep trg_agents_ts (fn_update_timestamp), drop trg_agents_updated (handle_updated_at)
DROP TRIGGER IF EXISTS trg_agents_updated ON public.agents;

-- profiles: keep trg_profiles_ts (fn_update_timestamp), drop duplicates
DROP TRIGGER IF EXISTS trg_profiles_updated ON public.profiles;
DROP TRIGGER IF EXISTS trg_p_updated ON public.profiles;

-- wallets: keep trg_wallets_ts (fn_update_timestamp), drop duplicates
DROP TRIGGER IF EXISTS trg_wallets_updated ON public.wallets;
DROP TRIGGER IF EXISTS trg_w_updated ON public.wallets;

-- transactions: keep trg_t_updated only if there's no other ts trigger
-- Looking at the schema, transactions only has trg_t_updated → keep it
-- (no trg_transactions_ts exists)


-- ══════════════════════════════════════════════════════════════
-- SECTION 5: CLEAN UP DUPLICATE INDEXES
-- ══════════════════════════════════════════════════════════════

-- kyc_documents: idx_kyc_user and idx_kyc_documents_user_id are identical
DROP INDEX IF EXISTS idx_kyc_documents_user_id;

-- loans: idx_loans_user and idx_loans_user_id are identical
DROP INDEX IF EXISTS idx_loans_user_id;


-- ══════════════════════════════════════════════════════════════
-- SECTION 6: ADMIN MANAGEMENT POLICIES FOR REFERENCE TABLES
-- Ensure admins can manage the public reference tables
-- ══════════════════════════════════════════════════════════════

-- countries: admin can manage
DROP POLICY IF EXISTS "p10_countries_admin_all" ON public.countries;
CREATE POLICY "p10_countries_admin_all" ON public.countries
    FOR ALL TO authenticated
    USING (public.is_admin());

-- enum_translations: admin can manage
DROP POLICY IF EXISTS "p10_enum_translations_admin_all" ON public.enum_translations;
CREATE POLICY "p10_enum_translations_admin_all" ON public.enum_translations
    FOR ALL TO authenticated
    USING (public.is_admin());

-- faqs: admin can manage
DROP POLICY IF EXISTS "p10_faqs_admin_all" ON public.faqs;
CREATE POLICY "p10_faqs_admin_all" ON public.faqs
    FOR ALL TO authenticated
    USING (public.is_admin());

-- point_rules: admin can manage
DROP POLICY IF EXISTS "p10_point_rules_admin_all" ON public.point_rules;
CREATE POLICY "p10_point_rules_admin_all" ON public.point_rules
    FOR ALL TO authenticated
    USING (public.is_admin());

-- prizes: admin can manage
DROP POLICY IF EXISTS "p10_prizes_admin_all" ON public.prizes;
CREATE POLICY "p10_prizes_admin_all" ON public.prizes
    FOR ALL TO authenticated
    USING (public.is_admin());

-- rewards: admin can manage
DROP POLICY IF EXISTS "p10_rewards_admin_all" ON public.rewards;
CREATE POLICY "p10_rewards_admin_all" ON public.rewards
    FOR ALL TO authenticated
    USING (public.is_admin());

-- spin_wheel_rewards: admin can manage
DROP POLICY IF EXISTS "p10_spin_wheel_rewards_admin_all" ON public.spin_wheel_rewards;
CREATE POLICY "p10_spin_wheel_rewards_admin_all" ON public.spin_wheel_rewards
    FOR ALL TO authenticated
    USING (public.is_admin());

-- subscription_plans: admin can manage
DROP POLICY IF EXISTS "p10_subscription_plans_admin_all" ON public.subscription_plans;
CREATE POLICY "p10_subscription_plans_admin_all" ON public.subscription_plans
    FOR ALL TO authenticated
    USING (public.is_admin());

-- terms_sections: admin can manage
DROP POLICY IF EXISTS "p10_terms_sections_admin_all" ON public.terms_sections;
CREATE POLICY "p10_terms_sections_admin_all" ON public.terms_sections
    FOR ALL TO authenticated
    USING (public.is_admin());

-- transaction_limits: admin can manage
DROP POLICY IF EXISTS "p10_transaction_limits_admin_all" ON public.transaction_limits;
CREATE POLICY "p10_transaction_limits_admin_all" ON public.transaction_limits
    FOR ALL TO authenticated
    USING (public.is_admin());


COMMIT;

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  VERIFICATION QUERIES — Run after migration                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- 1. Check all tables have RLS enabled:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- 2. Check all policies per table:
-- SELECT schemaname, tablename, policyname, cmd FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;

-- 3. Verify fn_admin_dashboard is SECURITY DEFINER:
-- SELECT proname, prosecdef FROM pg_proc WHERE proname = 'fn_admin_dashboard';
-- Expected: prosecdef = true

-- 4. Count policies per table (should be reasonable, 2-4 per table):
-- SELECT tablename, COUNT(*) as policy_count FROM pg_policies WHERE schemaname = 'public' GROUP BY tablename ORDER BY policy_count DESC;
