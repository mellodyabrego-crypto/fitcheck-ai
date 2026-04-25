-- ============================================
-- 2026-04-25 — Device tokens + daily reminder pg_cron schedule
--   1. device_tokens table (per-user FCM push tokens)
--   2. pg_cron schedule that fires the send-daily-reminder edge function hourly
-- Apply via: Supabase SQL editor OR `supabase db push`
--
-- MANUAL STEPS REQUIRED in Supabase dashboard (cannot be done from code):
--   * Database → Extensions: enable pg_cron + pg_net (one click each)
--   * Edge Functions → set secrets:
--       FCM_PROJECT_ID      = your Firebase project id
--       FCM_PRIVATE_KEY     = service account private key (full JSON content)
--       FCM_CLIENT_EMAIL    = service account email
--   * Edge Functions → deploy: `npx supabase functions deploy send-daily-reminder`
--
-- The cron job below assumes pg_net is available so we can issue an HTTP POST
-- to the edge function. If pg_net is not yet enabled the schedule will install
-- but no requests will fire — re-enable extension and the next tick will work.
-- ============================================

-- 1. device_tokens ---------------------------------------------------
create table if not exists public.device_tokens (
  user_id     uuid not null references auth.users(id) on delete cascade,
  token       text not null,
  platform    text not null check (platform in ('web', 'ios', 'android')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  primary key (user_id, token)
);

create index if not exists idx_device_tokens_user
  on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

drop policy if exists "device_tokens_rw_own" on public.device_tokens;
create policy "device_tokens_rw_own"
  on public.device_tokens
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 2. pg_cron schedule ------------------------------------------------
-- Runs every minute. The edge function will internally:
--   * find users whose notification_time matches the current minute (UTC for
--     v1 — local-time notifications are a follow-up once we collect TZ)
--   * fire FCM pushes to all of their registered device_tokens
--
-- Using a 1-minute granularity keeps the function idempotent: if the function
-- is already running when the next tick fires, the second invocation will see
-- no fresh users and exit cheaply.

-- pg_cron + pg_net must be enabled (see header)
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') and
     exists (select 1 from pg_extension where extname = 'pg_net') then
    -- Drop any prior schedule so re-running this migration is safe.
    perform cron.unschedule(jobid)
      from cron.job
      where jobname = 'her-style-daily-reminder';

    perform cron.schedule(
      'her-style-daily-reminder',
      '* * * * *', -- every minute
      $cron$
      select net.http_post(
        url := concat(current_setting('app.settings.supabase_url', true),
                      '/functions/v1/send-daily-reminder'),
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization',
          concat('Bearer ',
                 current_setting('app.settings.supabase_service_role_key', true))
        ),
        body := '{}'::jsonb
      );
      $cron$
    );
  end if;
end$$;

-- After applying this migration set the two settings the cron job needs:
--   alter database postgres set "app.settings.supabase_url"
--     = 'https://YOUR_PROJECT.supabase.co';
--   alter database postgres set "app.settings.supabase_service_role_key"
--     = 'eyJ...';
-- (These run once per project. Alternatively use Vault — see HANDOFF.md.)
