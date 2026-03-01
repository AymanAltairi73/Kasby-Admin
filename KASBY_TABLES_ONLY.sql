-- ╔══════════════════════════════════════════════════════════════╗
-- ║  KASBY – TABLES ONLY SCHEMA                                ║
-- ║  Goal: Table Structures & Relationships Only                ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ============================================================
-- 1. IDENTITY & PROFILES
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

-- ============================================================
-- 2. FINANCIAL CORE
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

-- ============================================================
-- 3. AGENTS
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
-- 4. LOGS & AUDIT
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
-- 5. FEATURES
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
-- 6. SYSTEM CONFIG
-- ============================================================
CREATE TABLE IF NOT EXISTS public.system_settings (
    id                  TEXT PRIMARY KEY DEFAULT 'global',
    pause_withdrawals   BOOLEAN DEFAULT FALSE,
    pause_profits       BOOLEAN DEFAULT FALSE,
    system_freeze       BOOLEAN DEFAULT FALSE,
    maintenance_mode    BOOLEAN DEFAULT FALSE,
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);
