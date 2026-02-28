-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHASE 6: Professional Security & RLS Refinement              ║
-- ║  Goal: Role-Based Access Control (RBAC) via Profiles.role     ║
-- ║  Architecture: Single Source of Truth Security                ║
-- ╚══════════════════════════════════════════════════════════════╝

BEGIN;

-- ══════════════════════════════════════════════
-- 0. PREREQUISITES (IDEMPOTENT TYPE CREATION)
-- ══════════════════════════════════════════════

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_type') THEN
        CREATE TYPE role_type AS ENUM ('user', 'admin', 'agent');
    END IF;
END $$;

-- Also ensure the role column exists in profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role role_type DEFAULT 'user';

-- ══════════════════════════════════════════════
-- 0.1 INFRASTRUCTURE (TABLES & LOGS)
-- ══════════════════════════════════════════════

-- Create activity_logs if missing
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    actor_role      role_type,
    action          TEXT NOT NULL,
    entity_type     TEXT,
    entity_id       TEXT,
    details         JSONB DEFAULT '{}'::jsonb,
    severity        TEXT DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
    ip_address      TEXT,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Indices for logs
CREATE INDEX IF NOT EXISTS idx_activity_logs_actor ON activity_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON activity_logs(created_at DESC);

-- Migrate old audit_logs if they still exist (prevents data loss)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'audit_logs' AND table_schema = 'public') THEN
        INSERT INTO activity_logs (actor_id, action, details, entity_type, entity_id, severity, created_at)
        SELECT admin_id, action, 
               jsonb_build_object('details', details, 'old_value', old_value, 'new_value', new_value),
               target_type, target_id, 
               CASE WHEN status = 'failure' THEN 'critical' WHEN status = 'warning' THEN 'warning' ELSE 'info' END,
               created_at
        FROM audit_logs;
        DROP TABLE audit_logs CASCADE;
    END IF;
END $$;

-- ══════════════════════════════════════════════
-- 1. SECURITY HELPERS (STABLE & SECURE)
-- ══════════════════════════════════════════════

-- Function to get the current user's role efficiently
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

-- Helper: Is Agent?
CREATE OR REPLACE FUNCTION public.is_agent()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_my_role() = 'agent';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- ══════════════════════════════════════════════
-- 2. ENABLE RLS ON CORE TABLES
-- ══════════════════════════════════════════════

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

-- ══════════════════════════════════════════════
-- 3. PROFILES POLICIES
-- ══════════════════════════════════════════════

DROP POLICY IF EXISTS "Admins can do everything on profiles" ON profiles;
CREATE POLICY "Admins can do everything on profiles" ON profiles
    FOR ALL TO authenticated
    USING (public.is_admin());

DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own basic info" ON profiles;
CREATE POLICY "Users can update their own basic info" ON profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id 
        -- Prevent users from upgrading their own role or changing their ID
        AND (public.is_admin() OR (role = (SELECT role FROM profiles WHERE id = auth.uid())))
    );

-- ══════════════════════════════════════════════
-- 4. ACTIVITY LOGS POLICIES
-- ══════════════════════════════════════════════

DROP POLICY IF EXISTS "Admins can view all logs" ON activity_logs;
CREATE POLICY "Admins can view all logs" ON activity_logs
    FOR SELECT TO authenticated
    USING (public.is_admin());

DROP POLICY IF EXISTS "System can insert logs" ON activity_logs;
CREATE POLICY "System can insert logs" ON activity_logs
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = actor_id);

-- ══════════════════════════════════════════════
-- 5. AGENTS POLICIES
-- ══════════════════════════════════════════════

DROP POLICY IF EXISTS "Admins can manage agents" ON agents;
CREATE POLICY "Admins can manage agents" ON agents
    FOR ALL TO authenticated
    USING (public.is_admin());

DROP POLICY IF EXISTS "Agents can view their own metadata" ON agents;
CREATE POLICY "Agents can view their own metadata" ON agents
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

-- ══════════════════════════════════════════════
-- 6. WALLETS POLICIES
-- ══════════════════════════════════════════════

DROP POLICY IF EXISTS "Admins can view all wallets" ON wallets;
CREATE POLICY "Admins can view all wallets" ON wallets
    FOR SELECT TO authenticated
    USING (public.is_admin());

DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
CREATE POLICY "Users can view their own wallet" ON wallets
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

COMMIT;
