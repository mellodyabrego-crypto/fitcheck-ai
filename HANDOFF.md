# Hand-off

## ⚠️ Who does what

**Mellody owns the Supabase backend** (`ntfgkukhjfzbmumhyqzq`). Anything in
this document tagged **`[MELLODY]`** must be run by her — Ben does not have
project-level access to her Supabase. Steps tagged **`[BEN]`** are codebase /
git / Cloudflare-side and Ben handles those.

If you are reading this fresh after a `git pull`, read this hand-off
top-to-bottom before deploying. The new code paths are inert without the
backend setup steps.

---

Two batches of work live in this repo:
- **2026-04-18** — Hostile-review hardening (sections below).
- **2026-04-25** — Onboarding v2, real Fit Check, Settings activation, soft
  delete, Fashion infinite-scroll, FCM push pipeline. See
  [§ "2026-04-25 — manual steps"](#2026-04-25--manual-steps) below for the
  follow-on setup.

> Color palette and overall visual identity are unchanged. Foreground colors
> were re-pointed at existing `AppTheme.primaryDeep` (already in the palette)
> wherever the lighter `primary` failed WCAG AA on white.

---

## 0. Manual steps you MUST run before pushing

In order:

1. **`[BEN]` Install new packages.** From `fitcheck-mellody/`:
   ```bash
   /Users/nelly/development/flutter/bin/flutter pub get
   ```
   New deps: `sentry_flutter ^8.10.1`, `posthog_flutter ^4.10.0`.

2. **`[MELLODY]` Apply the database migration.** In Supabase SQL editor for project
   `ntfgkukhjfzbmumhyqzq`, paste and run:
   `supabase/migrations/20260418_quota_and_storage_lockdown.sql`.

3. **`[MELLODY]` Re-deploy the Gemini edge function — *without* the
   `--no-verify-jwt` flag.** The new function REQUIRES a real Supabase JWT.
   ```bash
   export SUPABASE_ACCESS_TOKEN=<Mellody's Supabase PAT>
   npx supabase functions deploy gemini-proxy \
     --project-ref ntfgkukhjfzbmumhyqzq
   ```
   ⚠️ **Verify the project-ref.** Must match the project the Flutter build
   points to (`--dart-define=SUPABASE_URL=...`).

4. **`[MELLODY]` Set/confirm secrets on the same Supabase project:**
   ```bash
   npx supabase secrets set GEMINI_API_KEY=<key> \
     --project-ref ntfgkukhjfzbmumhyqzq
   # SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are auto-injected by Supabase.
   ```

5. **`[MELLODY]` Tighten the storage bucket in the Supabase dashboard:**
   Storage → `wardrobe-images` → Settings:
   - Public: ❌ (already off)
   - File size limit: **2 MB**
   - Allowed MIME types: `image/jpeg, image/png, image/webp`
   (The Flutter client now also rejects oversize / non-image files, but the
   bucket setting is the authoritative server-side gate.)

6. **`[BEN]` Add GitHub Actions repo secrets** (Settings → Secrets → Actions):
   - `SENTRY_DSN` — from sentry.io project settings
   - `POSTHOG_API_KEY` — from posthog.com project settings
   - (existing) `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `CLOUDFLARE_API_TOKEN`,
     `CLOUDFLARE_ACCOUNT_ID`

   Both new secrets are **optional** — the app runs fine if they're empty;
   the wrappers just no-op.

7. **`[BEN]` Smoke test locally:**
   ```bash
   /Users/nelly/development/flutter/bin/flutter run -d web-server \
     --web-port 3003 --web-hostname 0.0.0.0 \
     --dart-define=SUPABASE_URL=https://ntfgkukhjfzbmumhyqzq.supabase.co \
     --dart-define=SUPABASE_ANON_KEY='<anon>'
   ```
   Verify:
   - Sign in → outfit generation still works (proxy now requires JWT).
   - A non-image upload is rejected with a clear message.
   - `/terms` and `/privacy` render (try them logged-out too).
   - Walkthrough shows on first load; `Skip` and `X` both close it and persist.
   - Bottom nav selected color is now the deeper rose (primaryDeep).
   - Hit a bogus URL like `/asdf` → 404 page with "Go home" button.

---

## 1. What changed, file by file

### Security & cost
| File | Change |
|------|--------|
| `supabase/functions/gemini-proxy/index.ts` | **Rewrote.** JWT subject extraction, per-user daily quota (50 calls), model allow-list (`gemini-2.5-flash`, `gemini-2.0-flash`), 8 KB input cap, 1024-token output cap, 25 s upstream timeout, abort on timeout. Returns `X-Quota-Used`/`X-Quota-Limit` headers. |
| `supabase/migrations/20260418_quota_and_storage_lockdown.sql` | New. Creates `public.usage_counters` table + `public.increment_gemini_quota()` RPC + `public.my_gemini_quota_today` view (so the client can show "X/50 used today"). |
| `lib/services/gemini_service.dart` | Adds `_postToGemini` retry (3 attempts, exp backoff on 5xx), 25 s timeout, sends user JWT instead of anon key when available. New typed exceptions: `GeminiAuthException`, `GeminiInputTooLargeException`, `GeminiNetworkException`. |
| `lib/services/supabase_service.dart` | `uploadImage` now magic-byte-sniffs (JPEG / PNG / WebP only), rejects > 2 MB, sets explicit `contentType`. New `UploadValidationException`. |
| `lib/services/image_service.dart` | `compressImage` now defaults to 800 px max edge (was 512) and re-encodes JPEG@85 (was PNG — much smaller). `createThumbnail` switched to JPEG@80. |

### Legal
| File | Change |
|------|--------|
| `lib/features/legal/legal_text.dart` | New. Plain-text Terms of Service + Privacy Policy. **These are good-faith template copy — get an attorney to review before paying users come on.** |
| `lib/features/legal/legal_screen.dart` | New. `LegalScreen.terms()` / `LegalScreen.privacy()` factories. Uses `WithDecorations(sparse: true)` per project rule. |
| `lib/router.dart` | Adds `/terms` and `/privacy` routes (public, no auth required), 404 `errorBuilder` with "Go home", `_publicRoutes` set so the redirect doesn't bounce unauth'd users away from the legal pages. |
| `lib/features/settings/settings_screen.dart` | Terms + Privacy tiles now navigate to the new pages instead of saying "Coming soon". |

### Observability
| File | Change |
|------|--------|
| `pubspec.yaml` | Added `sentry_flutter ^8.10.1` + `posthog_flutter ^4.10.0`. Fixed description string ("The Candy Shop" → "Her Style Co."). Package name `grwm` left alone — renaming would touch every import. |
| `lib/core/constants.dart` | New env: `SENTRY_DSN`, `POSTHOG_API_KEY`, `POSTHOG_HOST` (default `https://us.i.posthog.com`), `APP_ENV` (default `production`). |
| `lib/services/observability_service.dart` | New. Thin Sentry wrapper. `bootstrap()` is a no-op when DSN is empty. Disables screenshot/PII/view-hierarchy attachment. |
| `lib/services/analytics_service.dart` | New. Thin PostHog wrapper. Centralised `AnalyticsEvents` constants (onboarding, walkthrough, wardrobe, outfit, fitcheck, paywall, errors). |
| `lib/main.dart` | Wraps `runZonedGuarded` in `Observability.bootstrap`. Calls `Analytics.setup()`. Identifies the user with both services if a session exists at boot. Reports init failures to Sentry. |

### Accessibility
| File | Change |
|------|--------|
| `lib/app.dart` | `MaterialApp.builder` clamps `MediaQuery.textScaler` to `[0.85, 1.4]` — honors OS text scaling without breaking layouts. |
| `lib/features/home/home_screen.dart` | `selectedItemColor` switched from `AppTheme.primary` (#C48A96, 3.2:1 vs white — fails AA) to `AppTheme.primaryDeep` (#A96E7A, ~4.9:1 — passes AA). Tab tap fires PostHog `home_tab` screen event. |
| `lib/widgets/walkthrough_overlay.dart` | Skip button is now visible on **every** step (was hidden on the last step). Adds an X close icon at the top. `seen` flag is now persisted only on explicit completion / skip / dismiss — not the moment the dialog opens. Fires `walkthrough_shown / step_reached / completed / skipped` events. Title wrapped in `Semantics(header: true)`. |
| `lib/features/legal/legal_screen.dart` | Title wrapped in `Semantics(header: true)`; body uses `SelectableText` so screen readers + copy/paste both work. |

### Performance
| File | Change |
|------|--------|
| `lib/widgets/lazy_indexed_stack.dart` | New. Lazy variant of `IndexedStack` — only mounts a child the first time its index is shown. Once visited, stays alive (preserves state). Saves cold-start work on the 6 unvisited tabs. |
| `lib/features/home/home_screen.dart` | Swapped `IndexedStack` for `LazyIndexedStack`. |

### PWA / SEO / Ops
| File | Change |
|------|--------|
| `web/manifest.json` | Branding: `name`/`short_name` → "Her Style Co.", real description, theme color `#C48A96` (matches the brand), background `#EDE5DB` (matches scaffold). |
| `web/index.html` | Adds `viewport` meta, `theme-color`, Open Graph + Twitter card tags for link previews. |
| `netlify.toml` | Adds Strict-Transport-Security, X-Content-Type-Options, X-Frame-Options DENY, Referrer-Policy, Permissions-Policy (camera/geolocation only when used), and a Content Security Policy scoped to Supabase + Google Fonts + PostHog + Sentry + Open-Meteo. |
| `.github/workflows/deploy.yml` | Triggers on **master** as well as main (was main-only — push to master previously deployed nothing). New `verify` job runs `dart format --set-exit-if-changed`, `flutter analyze --no-fatal-infos`, `flutter test --no-pub` and gates the deploy. The Cloudflare `_headers` block now includes the same security headers as `netlify.toml`. Build now also passes `SENTRY_DSN`, `POSTHOG_API_KEY`, `APP_ENV` via dart-define. |

---

## 2. Things deliberately NOT changed (and why)

- **Color palette hex values.** Per request. Only re-pointed which existing
  palette token gets used as a foreground in one place (home tab).
- **Package name `grwm` in pubspec.** Renaming the package would change every
  `package:grwm/...` import path — out of scope.
- **`kDemoMode = false`.** Left as-is. Toggling demo mode still works.
- **The 7-tab structure / IndexedStack behavior.** Lazy variant preserves the
  same UX (state retained after first visit) — no observable change for users.
- **Existing tests / models / screens.** Only the surfaces listed above were
  touched. Walkthrough copy, theme palette, prompts, all routes work as before.

---

## 3. Known follow-ups (not in this PR)

These came up during the review but are bigger than the surface this PR
covers — track them in `ROADMAP.md` instead:

- **Add a cookie/consent banner** before the first PostHog event fires (EU).
- **Backfill Semantics labels on every screen.** This PR adds the patterns and
  fixes the highest-impact spots (walkthrough, legal, home tabs); a sweep
  through every `IconButton` / `InkWell` / `GestureDetector` is still needed.
- **Backfill `semanticLabel` on every `Image.network` / `CachedNetworkImage`.**
- **Add a real keyboard-shortcut layer** (`Shortcuts` + `Actions`) — this PR
  only adds focus-visible spots in the walkthrough.
- **Push notifications / email reminders** — `notifications_enabled` exists in
  `user_profiles` but no transport is wired.
- **Replace template legal copy** with attorney-reviewed text.
- **Server-side image transform** (Supabase storage transforms or Cloudflare
  Image Resizing) once you outgrow the 800 px client cap.

These are tracked in `ROADMAP.md` under the appropriate user-tier (most are
1K-tier work).

---

## 2026-04-25 — manual steps

This second batch added: onboarding v2 (DOB / gender / location / referral /
permissions + reviews + walkthrough screens), real AI Fit Check, real share
card, hard occasion rules in outfit prompts, learn-from-history outfit loop,
new closet placeholder direction, larger Shop category icons, infinite-scroll
Fashion tab, real Export Wardrobe, real Delete Account (soft delete via ban),
active notification toggles, and the FCM push pipeline scaffolding.

### A. `[MELLODY]` Apply DB migrations (in this order)

In Supabase SQL editor for project `ntfgkukhjfzbmumhyqzq` (Mellody's project —
Ben does not have access; he can copy the SQL into Slack/email and Mellody
pastes it into her dashboard):

1. `supabase/migrations/20260425_onboarding_v2_and_soft_delete.sql`
   - Adds `dob`, `country`, `state`, `referral_source`, `weather_opt_in`,
     `deleted_at` columns to `user_profiles`.
   - RLS guard so deleted users can't read/update their profile row.
   - New `outfit_feedback` table for the learn-from-history loop.
2. `supabase/migrations/20260425_device_tokens_and_reminder_cron.sql`
   - Adds `device_tokens` table.
   - Installs the per-minute pg_cron schedule that calls `send-daily-reminder`.
   - **Pre-req:** in Database → Extensions, enable **`pg_cron`** and **`pg_net`**.

After applying #2, also run once (in the same SQL editor):
```sql
alter database postgres set "app.settings.supabase_url"
  = 'https://ntfgkukhjfzbmumhyqzq.supabase.co';
alter database postgres set "app.settings.supabase_service_role_key"
  = '<SERVICE_ROLE_KEY>'; -- found in Project Settings → API
```

### B. `[MELLODY]` Deploy the new edge functions

Mellody runs these from her machine (she needs the Supabase access token / PAT
for `mellodyabrego-crypto`):

```bash
export SUPABASE_ACCESS_TOKEN=<Mellody's Supabase PAT>
npx supabase functions deploy delete-account \
  --project-ref ntfgkukhjfzbmumhyqzq
npx supabase functions deploy send-daily-reminder \
  --project-ref ntfgkukhjfzbmumhyqzq
```

If Mellody isn't comfortable with the CLI, the function source can also be
pasted into the Supabase dashboard → Edge Functions → New function.

### C. Push notifications (Phase B)

Notifications are **inert until Firebase is configured**. The code, service
worker, edge function, and pg_cron schedule are all wired — they just need
credentials. This step has both Mellody and Ben work; do it in this order:

1. **`[MELLODY]`** Create a Firebase project at console.firebase.google.com.
2. **`[MELLODY]`** Add a Web app: Project Settings → Your apps → "</>" → register.
3. **`[MELLODY]`** Copy the SDK config block — you need: `apiKey`, `authDomain`,
   `projectId`, `storageBucket`, `messagingSenderId`, `appId`. Send these to Ben.
4. **`[MELLODY]`** Cloud Messaging → Web Push certificates → Generate key pair → save
   the key as `FIREBASE_VAPID_KEY`. Send to Ben.
5. **`[MELLODY]`** Project Settings → Service accounts → Generate new private key (JSON).
   Open the JSON and split into three values (keep the JSON for her records):
   - `FCM_PROJECT_ID` — the `project_id` field
   - `FCM_CLIENT_EMAIL` — the `client_email` field
   - `FCM_PRIVATE_KEY` — the `private_key` field (keep the literal `\n`s, the
     edge function decodes them)
6. **`[MELLODY]`** Set Supabase secrets:
   ```bash
   npx supabase secrets set \
     FCM_PROJECT_ID=<...> \
     FCM_CLIENT_EMAIL=<...> \
     FCM_PRIVATE_KEY="<paste with \n line breaks intact>" \
     --project-ref ntfgkukhjfzbmumhyqzq
   ```
7. **`[BEN]`** Substitute placeholders in `web/firebase-messaging-sw.js` with the
   values from step 3 (the worker file is fetched directly by the browser;
   dart-defines don't reach it). Commit the substituted file.
8. **`[BEN]`** Add `FIREBASE_*` dart-defines to `.github/workflows/deploy.yml`
   build step (and the local build command in CLAUDE.md):
   ```
   --dart-define=FIREBASE_API_KEY=<...>
   --dart-define=FIREBASE_PROJECT_ID=<...>
   --dart-define=FIREBASE_MESSAGING_SENDER_ID=<...>
   --dart-define=FIREBASE_APP_ID=<...>
   --dart-define=FIREBASE_AUTH_DOMAIN=<...>
   --dart-define=FIREBASE_STORAGE_BUCKET=<...>
   --dart-define=FIREBASE_VAPID_KEY=<...>
   ```
9. **`[BEN]`** Add the same `FIREBASE_*` values as GitHub Actions repo secrets.
10. **`[BEN]`** `flutter pub get` (adds `firebase_core` + `firebase_messaging`).

After all of the above, every minute the pg_cron job will:
- Find users where `notifications_enabled=true` AND `notification_time=HH:MM`
  matches the current UTC minute AND `deleted_at IS NULL`
- Look up their device tokens
- Send an FCM push titled "Today's look is ready"

The cron uses UTC for v1. Local-time notifications are a follow-up — collect
each user's IANA timezone (browser `Intl.DateTimeFormat().resolvedOptions().timeZone`)
and convert at fire time.

### D. Bug fixes & UX changes that need no infra

These shipped in code and apply on the next deploy automatically:

- **Edit Style Preferences** now passes `?retake=true` so the screen no longer
  bounces back to /home immediately.
- **Outfit prompt** now refuses obvious mismatches (no heels for workout, no
  knits for summer, etc.) and pulls in the user's full style profile + last 5
  accepted/rejected vibes.
- **Fit Check** is now a real Gemini call against the outfit's items + profile.
  Display floor is 70 with an honest "Limited match" tag when the underlying
  score was below 70 (per CLAUDE.md rule #7).
- **Share Score** captures the result card via `RepaintBoundary` and uses
  `Share.shareXFiles` (PNG) with text fallback.
- **JSON parser** now tolerates Gemini's "JSON\n{...}" prefix, smart quotes,
  trailing commas, markdown fences. Failures are logged to Sentry with a
  sample of the bad payload.
- **My Closet empty state** has three premium directions; pick one by changing
  `kClosetPlaceholderStyle` in `lib/features/wardrobe/closet_placeholder.dart`.
  Default is `editorial`.
- **Shop category icons** are now 88×88 with 40-pt icons (was 56×56 with 26-pt).
  Grid switched 4-cols → 3-cols.
- **Fashion tab** is now infinite-scroll (cycles the curated women's-fashion
  list) plus an AppBar search icon that opens Google Image Search for the
  active category.
- **Settings** — Daily Outfit Reminder + Reminder Time + Export Wardrobe +
  Delete Account are real (no more "Coming Soon"). Notifications + reminder
  time persist to `user_profiles` immediately; Phase B picks them up when FCM
  ships.

### E. Things still flagged for review

- `lib/features/legal/legal_text.dart` has `<<LEGAL REVIEW>>` blocks marking
  specific clauses an attorney must look at before paid acquisition.
- The four illustrative testimonials in `ReviewsScreen` are placeholder copy
  — swap with real quotes once you have them.
- Apple Sign-In is **not enabled** (per owner direction). Code in
  `auth_controller.signInWithApple()` is dormant until the $99/yr Apple Dev
  account + Service ID + Supabase Apple provider are configured.
- Background-removal `bg-remove` edge function was **not built** in this batch
  (no fal.ai / remove.bg key chosen). Revisit when a vendor + key are picked.

