-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHASE 1: Professional Schema Optimization (SQL Migration)   ║
-- ║  Goal: Zero Redundancy + Unified Identity + Unified Logs    ║
-- ║  Safety: Backup FIRST, then Drop.                            ║
-- ╚══════════════════════════════════════════════════════════════╝

BEGIN;

-- ══════════════════════════════════════════════
-- 1. IDENTITY RESTRUCTURE
-- ══════════════════════════════════════════════

-- Create role_type enum if not exists
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_type') THEN
        CREATE TYPE role_type AS ENUM ('user', 'admin', 'agent');
    END IF;
END $$;

-- Add role to profiles (default 'user')
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role role_type DEFAULT 'user';
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- ══════════════════════════════════════════════
-- 2. DATA MIGRATION (SAFETY SYNCHRONIZATION)
-- ══════════════════════════════════════════════

-- A. Move Agent names/phones to Profiles before dropping them
UPDATE profiles p
SET 
    full_name = COALESCE(NULLIF(p.full_name, ''), a.name),
    phone = COALESCE(p.phone, a.phone)
FROM agents a
WHERE a.user_id = p.id;

-- B. Move Admin names to Profiles
UPDATE profiles p
SET 
    full_name = COALESCE(NULLIF(p.full_name, ''), ap.full_name)
FROM admin_profiles ap
WHERE ap.id = p.id;

-- C. Identify existing Admins and Agents in profiles.role
UPDATE profiles SET role = 'admin' WHERE id IN (SELECT id FROM admin_profiles);
UPDATE profiles SET role = 'agent' WHERE id IN (SELECT user_id FROM agents);
UPDATE profiles SET role = 'admin' WHERE id IN (SELECT id FROM auth.users WHERE (raw_app_meta_data->>'is_admin')::boolean = true);

-- ══════════════════════════════════════════════
-- 3. SCHEMA CLEANING (DROPPING REDUNDANCY)
-- ══════════════════════════════════════════════

-- Remove redundant columns from Agents
ALTER TABLE agents 
    DROP COLUMN IF EXISTS name,
    DROP COLUMN IF EXISTS country,
    DROP COLUMN IF EXISTS province,
    DROP COLUMN IF EXISTS city,
    DROP COLUMN IF EXISTS address,
    DROP COLUMN IF EXISTS phone,
    DROP COLUMN IF EXISTS whatsapp,
    DROP COLUMN IF EXISTS telegram,
    DROP COLUMN IF EXISTS email;

-- Remove redundant columns from Admin Profiles
ALTER TABLE admin_profiles 
    DROP COLUMN IF EXISTS full_name,
    DROP COLUMN IF EXISTS last_login_at,
    DROP COLUMN IF EXISTS last_login_ip;

-- Drop useless tables
DROP TABLE IF EXISTS admin_sessions CASCADE;

-- ══════════════════════════════════════════════
-- 4. UNIFIED LOGGING SYSTEM
-- ══════════════════════════════════════════════

-- Create the professional Unified Log table
CREATE TABLE IF NOT EXISTS activity_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    actor_role      role_type,
    action          TEXT NOT NULL,
    entity_type     TEXT, -- 'transaction', 'investment', 'auth', 'user_management', etc.
    entity_id       TEXT,
    details         JSONB DEFAULT '{}'::jsonb,
    severity        TEXT DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
    ip_address      TEXT,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_actor ON activity_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON activity_logs(created_at DESC);

-- Migrate old audit_logs if they exist
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'audit_logs') THEN
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

-- Migrate old user_activities if they exist
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_activities') THEN
        INSERT INTO activity_logs (actor_id, action, details, entity_type, severity, created_at)
        SELECT user_id, action, jsonb_build_object('details', details), 'user_action', 'info', created_at
        FROM user_activities;
        DROP TABLE user_activities CASCADE;
    END IF;
END $$;

-- ══════════════════════════════════════════════
-- 5. FUNCTION & TRIGGER UPDATES
-- ══════════════════════════════════════════════

-- Update is_admin() to use the new role field
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN COALESCE(
        (SELECT role = 'admin' FROM profiles WHERE id = auth.uid()),
        FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- Update handle_new_user() to assign role
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_referred_by_id UUID := NULL;
    v_referral_code TEXT;
    v_role role_type := 'user';
BEGIN
    -- Determine role from metadata
    IF (NEW.raw_app_meta_data ->> 'is_admin')::boolean = true OR (NEW.raw_user_meta_data ->> 'is_admin')::boolean = true THEN
        v_role := 'admin';
    ELSIF (NEW.raw_user_meta_data ->> 'is_agent')::boolean = true THEN
        v_role := 'agent';
    END IF;

    -- Resolve referral_code
    IF NEW.raw_user_meta_data ->> 'referred_by_code' IS NOT NULL THEN
        SELECT id INTO v_referred_by_id FROM public.profiles
        WHERE referral_code = (NEW.raw_user_meta_data ->> 'referred_by_code');
    END IF;

    -- Generate referral code
    LOOP
        v_referral_code := 'K-' || upper(substring(md5(random()::text) from 1 for 4)) || '-' || upper(substring(md5(random()::text) from 5 for 4));
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE referral_code = v_referral_code);
    END LOOP;

    INSERT INTO public.profiles (id, full_name, email, phone, country_code, referral_code, referred_by_id, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
        COALESCE(NEW.email, ''),
        COALESCE(NEW.phone, NEW.raw_user_meta_data ->> 'phone'),
        COALESCE(NEW.raw_user_meta_data ->> 'country_code', NULL),
        v_referral_code,
        v_referred_by_id,
        v_role
    );

    -- Auto-create admin_profile if role is admin
    IF v_role = 'admin' THEN
        INSERT INTO admin_profiles (id, role, is_active)
        VALUES (NEW.id, 'admin', TRUE)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Update Admin Dashboard Function
CREATE OR REPLACE FUNCTION fn_admin_dashboard()
RETURNS TABLE (
    total_users BIGINT, active_users BIGINT, pending_kyc BIGINT,
    total_balance NUMERIC, total_invested NUMERIC,
    pending_txns BIGINT, active_loans BIGINT, delayed_loans BIGINT, active_agents BIGINT
) AS $$
BEGIN
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

COMMIT;
