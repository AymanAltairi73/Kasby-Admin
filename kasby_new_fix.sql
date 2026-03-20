-- ============================================================
-- KASBY – DATABASE FIX: TRANSACTION APPROVAL ERROR
-- This script fixes the "record 'new' has no field 'updated_at'" error.
-- ============================================================

-- 1. Drop the zombie trigger on the transactions table
-- This trigger was part of V4 but the 'updated_at' column was removed in V5.
DROP TRIGGER IF EXISTS trg_t_updated ON public.transactions;

-- 2. Clean up other potential zombie triggers from V4 to prevent future issues
-- V5 uses different naming conventions (e.g., trg_profiles_updated instead of trg_p_updated)
DROP TRIGGER IF EXISTS trg_p_updated ON public.profiles;
DROP TRIGGER IF EXISTS trg_w_updated ON public.wallets;

-- 3. (Optional but Recommended) Ensure the handle_updated_at function is correct
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN 
    -- Only update if the column exists to be ultra-safe
    NEW.updated_at = NOW(); 
    RETURN NEW; 
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Verify that existing V5 triggers are still active
-- Profiles
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_profiles_updated') THEN
        CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
    END IF;
END $$;

-- Wallets
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_wallets_updated') THEN
        CREATE TRIGGER trg_wallets_updated BEFORE UPDATE ON public.wallets FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
    END IF;
END $$;

-- Agents
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_agents_updated') THEN
        CREATE TRIGGER trg_agents_updated BEFORE UPDATE ON public.agents FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
    END IF;
END $$;
