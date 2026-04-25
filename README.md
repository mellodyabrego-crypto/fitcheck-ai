# Her Style Co.

Flutter web app — AI-powered personal stylist. Production: [her-style-co.pages.dev](https://her-style-co.pages.dev).

---

# 🚨 Mellody — read this first if you just pulled

The latest push (2026-04-25) adds onboarding v2, real Fit Check, soft-delete account flow, real Settings toggles, infinite Fashion feed, and the FCM push pipeline scaffolding. **Several of these features need backend changes only you can run** — Ben does not have admin access to your Supabase project.

Run sections **🔴 Must-do** and **🟡 Phase B** below in order. Each section is self-contained and you can stop after 🔴 and come back to 🟡 weeks later. Section ⚪ is optional cleanup.

If anything breaks: screenshot the error + the Edge Function logs and message Ben.

---

## 🔴 Must do first — without these, parts of the app break for users

These three steps unblock onboarding, the Fit Check / outfit generator, and the Delete Account button. ~10 min total.

### 1. Apply the onboarding + soft-delete migration

Supabase dashboard → **SQL Editor** → **New query** → paste the entire contents of [`supabase/migrations/20260425_onboarding_v2_and_soft_delete.sql`](supabase/migrations/20260425_onboarding_v2_and_soft_delete.sql) → **Run**.

This adds the new profile columns (DOB, gender, country, state, referral_source, weather_opt_in, deleted_at, notification_tz), the `outfit_feedback` table, RLS policies (including the DELETE policy that lets users undo a vote), and the soft-delete RLS guards.

### 2. Re-deploy the existing `gemini-proxy` function

There's a silent 401 bug in the currently-deployed version — fit checks and outfit generations are failing for ~2 of every 3 users without anyone noticing. The fix is in the new code; just re-deploy.

```bash
export SUPABASE_ACCESS_TOKEN=<your Supabase PAT>
npx supabase functions deploy gemini-proxy --project-ref ntfgkukhjfzbmumhyqzq
```

If you'd rather not use the CLI: dashboard → **Edge Functions** → `gemini-proxy` → paste the contents of [`supabase/functions/gemini-proxy/index.ts`](supabase/functions/gemini-proxy/index.ts) → **Deploy**.

### 3. Deploy the new `delete-account` function

Until this exists, Settings → Delete Account gives users an error.

```bash
npx supabase functions deploy delete-account --project-ref ntfgkukhjfzbmumhyqzq
```

(Or paste-and-deploy in the dashboard, same way as #2.)

### ✅ How to know it worked

- Sign up a fresh test user → finish onboarding → SQL Editor → `select * from user_profiles where user_id = '<test>'` → new columns are filled in.
- Generate an outfit → tap "Get Fit Check Score" → real numeric score (not random 65–94) comes back. If it errors, the gemini-proxy redeploy didn't take.
- Settings → Delete Account → type DELETE → confirm → `select deleted_at from user_profiles where user_id = '<test>'` → timestamp present.

---

## 🟡 Phase B — push notifications

Notifications are fully wired in code but inert until Firebase is configured. Until you finish this section, the toggle in Settings just saves the preference. **Skip this whole section if you're not ready** — feel free to come back days or weeks later.

### 4. Enable two Postgres extensions

Database → Extensions → search "pg_cron" → **Enable**. Repeat for "pg_net".

### 5. Apply the device-tokens + cron migration

SQL Editor → paste [`supabase/migrations/20260425_device_tokens_and_reminder_cron.sql`](supabase/migrations/20260425_device_tokens_and_reminder_cron.sql) → **Run**.

### 6. Set the two database settings the cron job needs

(One-time, in SQL Editor.)

```sql
alter database postgres set "app.settings.supabase_url"
  = 'https://ntfgkukhjfzbmumhyqzq.supabase.co';
alter database postgres set "app.settings.supabase_service_role_key"
  = '<paste your service role key from Project Settings → API>';
```

### 7. Set up Firebase (~30 min, one-time)

- [console.firebase.google.com](https://console.firebase.google.com) → **New project** → name it "Her Style Co."
- Project Settings → **Your apps** → Add **Web app** → register → **copy the SDK config block** (apiKey / authDomain / projectId / storageBucket / messagingSenderId / appId) — you'll send this to Ben in step 10
- **Cloud Messaging** tab → **Web Push certificates** → **Generate key pair** → save the VAPID key — you'll send this to Ben in step 10
- Project Settings → **Service accounts** → **Generate new private key** → download the JSON file, **keep it safe**

### 8. Set the FCM secrets in Supabase

Open the JSON from step 7, copy out three fields:

```bash
npx supabase secrets set \
  FCM_PROJECT_ID=<project_id from JSON> \
  FCM_CLIENT_EMAIL=<client_email from JSON> \
  FCM_PRIVATE_KEY="<private_key from JSON, keep the literal \n line breaks>" \
  --project-ref ntfgkukhjfzbmumhyqzq
```

### 9. Deploy the daily reminder function

```bash
npx supabase functions deploy send-daily-reminder --project-ref ntfgkukhjfzbmumhyqzq
```

### 10. Send Ben the Firebase web config

He needs the 6 values from step 7 (apiKey / authDomain / projectId / storageBucket / messagingSenderId / appId) **plus the VAPID key** — these go into the Cloudflare environment variables and the `web/firebase-messaging-sw.js` placeholders. The app build pipeline isn't on your side, so Ben handles the front-end wiring.

### ✅ How to know it worked

Set a reminder for 1 minute from now in Settings → wait → push notification arrives. If nothing fires, check Edge Functions → `send-daily-reminder` → **Logs** for errors.

---

## ⚪ Optional cleanup — if you haven't already

Leftovers from the April 18 hardening pass that may or may not have shipped:

- Storage → `wardrobe-images` → **Settings**: confirm file size limit **2 MB**, allowed MIME types `image/jpeg, image/png, image/webp`, public **off**.
- If [`supabase/migrations/20260418_quota_and_storage_lockdown.sql`](supabase/migrations/20260418_quota_and_storage_lockdown.sql) wasn't applied earlier, run it now (Gemini quota table + storage lockdown).

---

## ⚖️ One thing only a lawyer can fix

The `<<LEGAL REVIEW>>` blocks in [`lib/features/legal/legal_text.dart`](lib/features/legal/legal_text.dart) flag specific clauses an attorney should look at before paid acquisition or EU/UK users — especially the **soft-delete retention model in Privacy Policy §8** (we keep wardrobe data after account deletion for analytics, which is non-standard and needs counsel's read on GDPR Article 17 compatibility). Not a blocker for friends-and-family beta.

---

# Project info (for everyone)

- **Repo:** `mellodyabrego-crypto/fitcheck-ai`
- **Production:** Cloudflare Pages → auto-deploys on push to `main` via `.github/workflows/deploy.yml`
- **Backend:** Supabase project `ntfgkukhjfzbmumhyqzq` (owned by Mellody)
- **AI:** Gemini 2.5 Flash via the `gemini-proxy` edge function — key never ships to the browser
- **Stack:** Flutter web (`name: grwm` in pubspec, brand "Her Style Co." everywhere)
- **Branch:** `main` (not master)

For day-to-day development, see [CLAUDE.md](CLAUDE.md). Full change history & manual setup steps for prior pushes: [HANDOFF.md](HANDOFF.md). Growth-tier roadmap: [ROADMAP.md](ROADMAP.md).
