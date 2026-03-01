-- ╔══════════════════════════════════════════════════════════════╗
-- ║  KASBY – MASTER PRODUCTION SCHEMA V4.0                     ║
-- ║  Architecture: Single Source of Truth (SSOT)               ║
-- ║  Security: RBAC + Phase 9 Hardening                        ║
-- ║  Serves: Admin Panel + User Application                    ║
-- ╚══════════════════════════════════════════════════════════════╝

BEGIN;

-- ============================================================
-- 0. INFRASTRUCTURE & EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. CUSTOM TYPES (IDEMPOTENT)
-- ============================================================
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_type') THEN
        CREATE TYPE role_type AS ENUM ('user', 'admin', 'agent');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        CREATE TYPE user_status AS ENUM ('active', 'blocked', 'suspended');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_tier') THEN
        CREATE TYPE account_tier AS ENUM ('free', 'verified', 'vip');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'kyc_status') THEN
        CREATE TYPE kyc_status AS ENUM ('unverified', 'pending', 'verified', 'rejected');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'txn_type') THEN
        CREATE TYPE txn_type AS ENUM ('deposit', 'withdrawal', 'transfer_in', 'transfer_out', 'investment', 'investment_return', 'loan_disbursement', 'loan_repayment', 'reward', 'adjustment', 'profit', 'fee', 'admin_credit', 'admin_debit');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'txn_status') THEN
        CREATE TYPE txn_status AS ENUM ('pending', 'processing', 'completed', 'approved', 'rejected', 'cancelled', 'failed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'investment_status') THEN
        CREATE TYPE investment_status AS ENUM ('active', 'completed', 'cancelled', 'matured');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'loan_status') THEN
        CREATE TYPE loan_status AS ENUM ('pending', 'current', 'paid', 'delayed', 'defaulted');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'agent_status') THEN
        CREATE TYPE agent_status AS ENUM ('active', 'inactive', 'suspended');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'severity_type') THEN
        CREATE TYPE severity_type AS ENUM ('info', 'warning', 'critical');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'kyc_doc_type') THEN
        CREATE TYPE kyc_doc_type AS ENUM ('id_card_front', 'id_card_back', 'passport', 'selfie', 'proof_of_address', 'other');
    END IF;
END $$;

-- ============================================================
-- 2. SECURITY HELPERS
-- ============================================================

-- Function to get current user role
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS role_type AS $$
BEGIN
    RETURN (SELECT role FROM public.profiles WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- Helper: Is Admin?
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_my_role() = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- ============================================================
-- 3. IDENTITY & PROFILES (SSOT)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name       TEXT NOT NULL DEFAULT '',
    email           TEXT UNIQUE NOT NULL,
    phone           TEXT UNIQUE,
    role            role_type DEFAULT 'user',
    status          user_status DEFAULT 'active',
    account_tier    account_tier DEFAULT 'free',
    kyc_status      kyc_status DEFAULT 'unverified',
    avatar_url      TEXT,
    country_code    TEXT,
    province        TEXT DEFAULT '',
    city            TEXT DEFAULT '',
    address         TEXT DEFAULT '',
    referral_code   TEXT UNIQUE,
    referred_by_id  UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);

-- ============================================================
-- 4. FINANCIAL CORE (WALLETS & TRANSACTIONS)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.wallets (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    available_balance   NUMERIC(18, 4) NOT NULL DEFAULT 0.00 CHECK (available_balance >= 0),
    invested_balance    NUMERIC(18, 4) NOT NULL DEFAULT 0.00 CHECK (invested_balance >= 0),
    profit_balance      NUMERIC(18, 4) NOT NULL DEFAULT 0.00 CHECK (profit_balance >= 0),
    currency            TEXT NOT NULL DEFAULT 'USD',
    is_frozen           BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.transactions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    type            txn_type NOT NULL,
    amount          NUMERIC(18, 4) NOT NULL CHECK (amount > 0),
    status          txn_status DEFAULT 'pending',
    running_balance NUMERIC(18, 4),
    description     TEXT,
    proof_url       TEXT,
    rejection_reason TEXT,
    processed_by    UUID REFERENCES auth.users(id),
    processed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Indexing for ledger analysis
CREATE INDEX IF NOT EXISTS idx_txn_user_created ON transactions(user_id, created_at DESC);

-- ============================================================
-- 5. AGENTS (NO DATA DUPLICATION)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.agents (
    id                  UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_available        BOOLEAN DEFAULT TRUE,
    supported_methods   JSONB DEFAULT '[]',
    success_rate        NUMERIC(5, 2) DEFAULT 100.00,
    total_txns          INTEGER DEFAULT 0,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. UNIFIED ACTIVITY LOGS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.activity_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    actor_role      role_type,
    action          TEXT NOT NULL,
    entity_type     TEXT,
    entity_id       TEXT,
    details         JSONB DEFAULT '{}'::jsonb,
    severity        severity_type DEFAULT 'info',
    ip_address      TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. FEATURES (INVESTMENTS, LOANS, CHECK-INS)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.investment_plans (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_ar             TEXT NOT NULL,
    name_en             TEXT,
    profit_percentage   NUMERIC(6, 3) NOT NULL,
    duration_days       INTEGER DEFAULT 30,
    min_amount          NUMERIC(18, 4) NOT NULL,
    max_amount          NUMERIC(18, 4),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_investments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES public.profiles(id),
    plan_id             UUID NOT NULL REFERENCES public.investment_plans(id),
    amount              NUMERIC(18, 4) NOT NULL,
    expected_profit     NUMERIC(18, 4) NOT NULL,
    status              investment_status DEFAULT 'active',
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    matured_at          TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.daily_check_ins (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    streak          INTEGER DEFAULT 1,
    points_awarded  INTEGER DEFAULT 10,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 8. SYSTEM CONFIGURATION
-- ============================================================

CREATE TABLE IF NOT EXISTS public.system_settings (
    id                  TEXT PRIMARY KEY DEFAULT 'global',
    pause_withdrawals   BOOLEAN DEFAULT FALSE,
    pause_profits       BOOLEAN DEFAULT FALSE,
    system_freeze       BOOLEAN DEFAULT FALSE,
    maintenance_mode    BOOLEAN DEFAULT FALSE,
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 9. TRIGGERS & AUTOMATION
-- ============================================================

-- Function to sync updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Apply to all major tables
CREATE TRIGGER trg_p_updated BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
CREATE TRIGGER trg_w_updated BEFORE UPDATE ON wallets FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
CREATE TRIGGER trg_t_updated BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Auto-provision Profile on Auth.User Signup
CREATE OR REPLACE FUNCTION public.handle_new_user_master()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), 'user');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_on_auth_signup AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user_master();

-- Auto-provision Wallet on Profile Create
CREATE OR REPLACE FUNCTION public.handle_new_profile_master()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.wallets (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_on_profile_created AFTER INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION handle_new_profile_master();

-- ============================================================
-- 10. RPC BUSINESS LOGIC (SECURITY DEFINER)
-- ============================================================

-- Process Deposit
CREATE OR REPLACE FUNCTION public.fn_process_deposit_v4(p_txn_id UUID, p_admin_id UUID)
RETURNS VOID AS $$
DECLARE
    v_txn RECORD;
BEGIN
    SELECT * INTO v_txn FROM transactions WHERE id = p_txn_id FOR UPDATE;
    IF v_txn.status != 'pending' THEN RAISE EXCEPTION 'Already processed'; END IF;
    
    UPDATE wallets SET available_balance = available_balance + v_txn.amount WHERE user_id = v_txn.user_id;
    UPDATE transactions SET status = 'approved', processed_by = p_admin_id, processed_at = NOW() WHERE id = p_txn_id;
    
    INSERT INTO activity_logs (actor_id, action, entity_type, entity_id, severity) 
    VALUES (p_admin_id, 'approve_deposit', 'transaction', p_txn_id::TEXT, 'info');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 10.2 DAILY CHECK-IN
CREATE OR REPLACE FUNCTION public.daily_check_in()
RETURNS json 
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_last_checkin TIMESTAMPTZ;
    v_current_streak INTEGER := 1;
    v_points_to_award INTEGER := 10; 
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', FALSE, 'error', 'Unauthorized');
    END IF;

    SELECT created_at INTO v_last_checkin
    FROM daily_check_ins
    WHERE user_id = v_user_id
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_last_checkin IS NOT NULL AND v_last_checkin::date = CURRENT_DATE THEN
        RETURN json_build_object('success', FALSE, 'error', 'Already checked in today');
    END IF;

    IF v_last_checkin IS NOT NULL AND v_last_checkin::date = CURRENT_DATE - INTERVAL '1 day' THEN
        SELECT streak INTO v_current_streak
        FROM daily_check_ins
        WHERE user_id = v_user_id
        ORDER BY created_at DESC
        LIMIT 1;
        v_current_streak := v_current_streak + 1;
    ELSE
        v_current_streak := 1;
    END IF;

    v_points_to_award := 10;
    IF v_current_streak % 7 = 0 THEN
        v_points_to_award := 50;
    END IF;

    INSERT INTO daily_check_ins (user_id, streak, points_awarded)
    VALUES (v_user_id, v_current_streak, v_points_to_award);

    RETURN json_build_object(
        'success', TRUE,
        'streak', v_current_streak,
        'points', v_points_to_award
    );
END;
$$;

-- ============================================================
-- 11. SECURITY & RLS POLICIES (PHASE 9 HARDENING)
-- ============================================================

-- Enable RLS everywhere
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_check_ins ENABLE ROW LEVEL SECURITY;

-- 11.1 PROFILES POLICIES
CREATE POLICY "Admin full access" ON profiles FOR ALL USING (public.is_admin());
CREATE POLICY "Users view own" ON profiles FOR SELECT USING (id = auth.uid());
CREATE POLICY "Users update own" ON profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid() AND role = (SELECT role FROM profiles WHERE id = auth.uid()));

-- 11.2 TRANSACTIONS POLICIES (Hardened)
CREATE POLICY "Admin scan txns" ON transactions FOR ALL USING (public.is_admin());
CREATE POLICY "User view txns" ON transactions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "User insert requests" ON transactions FOR INSERT WITH CHECK (user_id = auth.uid() AND type IN ('deposit', 'withdrawal'));

-- 11.3 WALLETS POLICIES
CREATE POLICY "Admin scan wallets" ON wallets FOR ALL USING (public.is_admin());
CREATE POLICY "User view wallet" ON wallets FOR SELECT USING (user_id = auth.uid());

-- 11.4 CHECK-INS POLICIES (Hardened)
CREATE POLICY "Admin scan checkins" ON daily_check_ins FOR ALL USING (public.is_admin());
CREATE POLICY "User view checkins" ON daily_check_ins FOR SELECT USING (user_id = auth.uid());

-- ============================================================
-- 12. VIEWS (PERFORMANCE & SECURITY)
-- ============================================================

DROP VIEW IF EXISTS public.v_user_dashboard CASCADE;
CREATE VIEW public.v_user_dashboard 
WITH (security_invoker = true) AS
SELECT 
    p.id, p.full_name, p.role, p.status,
    w.available_balance, w.invested_balance, w.profit_balance
FROM profiles p
JOIN wallets w ON p.id = w.user_id;

COMMIT;
