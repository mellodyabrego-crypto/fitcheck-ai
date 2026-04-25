-- ============================================
-- 2026-04-25 — Onboarding v2 + soft-delete + outfit feedback
--   1. Extend user_profiles with new onboarding columns
--   2. Add deleted_at for soft-delete (data retained for analytics)
--   3. Block all access for users with deleted_at IS NOT NULL via RLS
--   4. outfit_feedback table for the "learn from history" loop
-- Apply via: Supabase SQL editor OR `supabase db push`
-- ============================================

-- 1. New onboarding columns ------------------------------------------
alter table public.user_profiles
  add column if not exists dob              date,
  add column if not exists country          text,
  add column if not exists state            text,
  add column if not exists referral_source  text,
  add column if not exists weather_opt_in   boolean not null default false,
  add column if not exists deleted_at       timestamptz,
  -- IANA timezone (e.g. "America/Los_Angeles"). Stored alongside
  -- notification_time so the daily reminder cron can fire in each user's
  -- local clock instead of UTC. NULL = treat as UTC (legacy).
  add column if not exists notification_tz  text;

-- Helpful index for analytics filters that exclude deleted accounts.
create index if not exists idx_user_profiles_deleted_at
  on public.user_profiles (deleted_at)
  where deleted_at is not null;

-- 2. Soft-delete RLS guard -------------------------------------------
-- Block self-reads of profile rows that have been soft-deleted, so a banned
-- user who somehow re-authenticates cannot pull their own row. The auth-side
-- ban (set in the delete-account edge function) is the primary gate; this is
-- defense in depth.
drop policy if exists "user_profiles_select_own_active" on public.user_profiles;
create policy "user_profiles_select_own_active"
  on public.user_profiles
  for select
  using (auth.uid() = user_id and deleted_at is null);

drop policy if exists "user_profiles_update_own_active" on public.user_profiles;
create policy "user_profiles_update_own_active"
  on public.user_profiles
  for update
  using (auth.uid() = user_id and deleted_at is null)
  with check (auth.uid() = user_id and deleted_at is null);

-- 3. outfit_feedback ------------------------------------------------
-- Records accept/reject signals on AI-generated outfits so the next prompt
-- can reference the user's recent preferences. One row per (user, outfit).
create table if not exists public.outfit_feedback (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  outfit_id   text not null,
  occasion    text,
  signal      text not null check (signal in ('accept', 'reject', 'favorite')),
  reason      text,
  created_at  timestamptz not null default now()
);

create index if not exists idx_outfit_feedback_user_recent
  on public.outfit_feedback (user_id, created_at desc);

alter table public.outfit_feedback enable row level security;

drop policy if exists "outfit_feedback_select_own" on public.outfit_feedback;
create policy "outfit_feedback_select_own"
  on public.outfit_feedback
  for select
  using (auth.uid() = user_id);

drop policy if exists "outfit_feedback_insert_own" on public.outfit_feedback;
create policy "outfit_feedback_insert_own"
  on public.outfit_feedback
  for insert
  with check (auth.uid() = user_id);

-- Allow users to undo a vote they regret. Without this, an accidental "reject"
-- tap permanently steers future suggestions away from a vibe the user
-- actually likes.
drop policy if exists "outfit_feedback_delete_own" on public.outfit_feedback;
create policy "outfit_feedback_delete_own"
  on public.outfit_feedback
  for delete
  using (auth.uid() = user_id);
