-- ═══════════════════════════════════════════════════════════════
-- Kasby — Create Admin User
-- Run this in Supabase SQL Editor AFTER the main migration
-- ═══════════════════════════════════════════════════════════════

-- Step 1: Create the admin user in Supabase Auth
-- This inserts directly into auth.users with a hashed password
DO $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Check if user already exists
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = 'admin@gmail.com';

  IF v_user_id IS NULL THEN
    -- Create the user
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      'admin@gmail.com',
      crypt('pass123', gen_salt('bf')),
      now(),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email'], 'is_admin', true),
      jsonb_build_object('full_name', 'المدير العام'),
      now(),
      now(),
      '',
      ''
    )
    RETURNING id INTO v_user_id;

    -- Create identity record (required for Supabase Auth to work)
    INSERT INTO auth.identities (
      id,
      user_id,
      provider_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_user_id,
      v_user_id::text,
      jsonb_build_object('sub', v_user_id::text, 'email', 'admin@gmail.com'),
      'email',
      now(),
      now(),
      now()
    );

    -- Create wallet for admin
    INSERT INTO wallets (user_id, available_balance, created_at)
    VALUES (v_user_id, 0, now())
    ON CONFLICT DO NOTHING;

    -- Create profile for admin
    INSERT INTO profiles (id, full_name, email, created_at)
    VALUES (v_user_id, 'المدير العام', 'admin@gmail.com', now())
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Admin user created successfully with ID: %', v_user_id;
  ELSE
    -- User exists, ensure admin flag is set
    UPDATE auth.users
    SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object('is_admin', true)
    WHERE id = v_user_id;

    RAISE NOTICE 'Admin user already exists (ID: %). Updated admin flag.', v_user_id;
  END IF;
END;
$$;

-- Step 2: Create is_admin() RPC function (used by the app to verify admin access)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (auth.jwt() -> 'app_metadata' ->> 'is_admin')::BOOLEAN = true;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- Done! You can now login with:
--   Email:    admin@gmail.com
--   Password: pass123
-- ═══════════════════════════════════════════════════════════════
