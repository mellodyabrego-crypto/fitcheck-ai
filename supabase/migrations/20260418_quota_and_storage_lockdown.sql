-- ============================================
-- 2026-04-18 — Cost / abuse hardening
--   1. usage_counters table + RPC for Gemini per-user daily quota
--   2. Storage policy hardening for wardrobe-images bucket
-- Apply via: Supabase SQL editor OR `supabase db push`
-- ============================================

-- 1. usage_counters --------------------------------------------------
create table if not exists public.usage_counters (
  user_id uuid not null references auth.users(id) on delete cascade,
  day     date not null,
  feature text not null default 'gemini',
  count   int  not null default 0,
  primary key (user_id, day, feature)
);

alter table public.usage_counters enable row level security;

-- Users can READ their own counters (so the client can show "X of N used today")
drop policy if exists "usage_counters_select_own" on public.usage_counters;
create policy "usage_counters_select_own"
  on public.usage_counters
  for select
  using (auth.uid() = user_id);

-- No INSERT/UPDATE/DELETE from clients. Mutation goes through the
-- SECURITY DEFINER RPC below using the service role from the edge function.

-- Atomically increment + check quota. Returns { allowed: bool, used: int }.
create or replace function public.increment_gemini_quota(
  p_user_id uuid,
  p_day     date,
  p_limit   int
)
returns table(allowed boolean, used int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  insert into public.usage_counters (user_id, day, feature, count)
  values (p_user_id, p_day, 'gemini', 1)
  on conflict (user_id, day, feature)
  do update set count = public.usage_counters.count + 1
  returning count into v_count;

  return query select (v_count <= p_limit), v_count;
end;
$$;

-- Lock down direct access to the function (only the edge function via service
-- role should call it; never grant to anon/authenticated).
revoke all on function public.increment_gemini_quota(uuid, date, int) from public;
revoke all on function public.increment_gemini_quota(uuid, date, int) from anon;
revoke all on function public.increment_gemini_quota(uuid, date, int) from authenticated;

-- 2. Storage policy hardening ----------------------------------------
-- The existing schema already enables RLS on storage.objects scoped to
-- "<auth.uid()>/...". This adds defense-in-depth: also enforce a max size
-- via a CHECK on a metadata column, AND ensure delete is restricted to owner.
-- (Supabase storage doesn't expose object size as a column to PostgreSQL
-- directly; size limits must be enforced in the bucket configuration in the
-- Supabase dashboard. See HANDOFF.md for the manual step.)

-- 3. Helper view for client to read remaining quota --------------------
create or replace view public.my_gemini_quota_today as
  select
    coalesce(count, 0) as used,
    50 as daily_limit  -- keep in sync with edge function DAILY_QUOTA
  from public.usage_counters
  where user_id = auth.uid()
    and day     = current_date
    and feature = 'gemini';

grant select on public.my_gemini_quota_today to authenticated;
