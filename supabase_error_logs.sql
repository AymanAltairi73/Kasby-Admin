-- ═══════════════════════════════════════════════════════════════
-- Kasby — Error Logs Table
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  controller_name TEXT NOT NULL,
  method_name TEXT NOT NULL,
  error_message TEXT NOT NULL,
  stack_trace TEXT,
  device_info TEXT,
  app_version TEXT DEFAULT '1.0.0',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: Only admin/service_role can read logs
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can INSERT (so errors get logged)
DROP POLICY IF EXISTS "Authenticated users can insert error_logs" ON error_logs;
CREATE POLICY "Authenticated users can insert error_logs"
  ON error_logs FOR INSERT
  WITH CHECK (true);

-- Only service_role can SELECT (admin reads via service_role or dashboard)
DROP POLICY IF EXISTS "Service role can read error_logs" ON error_logs;
CREATE POLICY "Service role can read error_logs"
  ON error_logs FOR SELECT
  USING (auth.role() = 'service_role');

-- Admin users can also read (via is_admin check)
DROP POLICY IF EXISTS "Admin users can read error_logs" ON error_logs;
CREATE POLICY "Admin users can read error_logs"
  ON error_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_app_meta_data->>'is_admin' = 'true'
    )
  );

-- Index for fast queries by controller and time
CREATE INDEX IF NOT EXISTS idx_error_logs_controller ON error_logs (controller_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_error_logs_created_at ON error_logs (created_at DESC);

-- ═══════════════════════════════════════════════════════════════
-- Done! Error logs table is ready.
-- ═══════════════════════════════════════════════════════════════
