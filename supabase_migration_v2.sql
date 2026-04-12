-- ============================================================
-- Migration v2: Add onboarding fields to user_profiles
-- Run this in Supabase SQL Editor if you already ran schema v1
-- ============================================================

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS goals              JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS age_range          TEXT,
  ADD COLUMN IF NOT EXISTS brands             JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS top_size           TEXT,
  ADD COLUMN IF NOT EXISTS bottom_size        TEXT,
  ADD COLUMN IF NOT EXISTS shoe_size          TEXT,
  ADD COLUMN IF NOT EXISTS skin_tone_undertone TEXT;

-- Confirm
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;
