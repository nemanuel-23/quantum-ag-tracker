-- Quantum Ag Tracker — Supabase Database Setup
-- Run this SQL in your Supabase project's SQL Editor (Dashboard > SQL Editor)

-- 1. Create the main data table
CREATE TABLE IF NOT EXISTS app_data (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by TEXT DEFAULT 'system'
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE app_data ENABLE ROW LEVEL SECURITY;

-- 3. Create a permissive policy (all authenticated + anon users can read/write)
--    Adjust this if you want stricter access control.
CREATE POLICY "Allow all access to app_data"
  ON app_data
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 4. Enable Realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE app_data;

-- 5. Insert initial empty row (the app will populate it on first sync)
INSERT INTO app_data (data, updated_by)
VALUES ('{}', 'init')
ON CONFLICT DO NOTHING;

-- 6. Create an auto-update trigger for updated_at
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON app_data
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_column();

-- Done! Now in the app:
--   1. Go to Settings
--   2. Enter your Supabase Project URL (e.g. https://xyzproject.supabase.co)
--   3. Enter your Supabase Anon Key (found in Project Settings > API)
--   4. Toggle "Enable Supabase Sync" on
--   5. The green "Connected" badge will appear when sync is active
