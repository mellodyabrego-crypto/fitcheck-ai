# Her Style Co. — Project Guide for Claude

## ⚠️ Supabase ownership — read first

This project's Supabase backend (`ntfgkukhjfzbmumhyqzq`) is owned by **Mellody Abrego** (`mellodyabrego-crypto` GitHub / Supabase account), NOT by Ben. Implication for every session:

- **Ben owns the codebase.** Code changes, pubspec edits, frontend work, git pushes — Ben.
- **Mellody owns the backend.** SQL migrations, edge function deploys (`npx supabase functions deploy ...`), edge function secrets (`npx supabase secrets set ...`), Storage bucket settings, pg_cron extensions, Auth provider config (Apple, Google) — **Mellody must run these**. Ben does not have a Supabase access token for her project.
- **Don't tell Ben to run Supabase admin commands.** If a change requires it, write the steps for Mellody and hand them off (HANDOFF.md is the canonical place).
- **Do not confuse with Ben's Supabase** (`bhdaiddrfeqtwjlsfifx`) — different project, different account, different prefix conventions. The `w_*` / `p_*` / `cfo_*` prefixes Ben uses elsewhere DO NOT APPLY here.

## What this app is
Flutter web app: **Her Style Co.** — an AI-powered personal stylist.
- Users upload their wardrobe, get AI outfit suggestions, track outfit logs in a calendar, shop for similar items, and share looks.
- Tagline: "Your personal Stylist"

## Running the app locally
```bash
/Users/nelly/development/flutter/bin/flutter run -d web-server --web-port 3003 --web-hostname 0.0.0.0
# Then open http://localhost:3003
```
Flutter binary: `/Users/nelly/development/flutter/bin/flutter`

## Deployment
- **Production (primary):** Cloudflare Pages project `her-style-co` — auto-deploys on push to `main` via `.github/workflows/deploy.yml`. Branch is **`main`**, not `master`.
- **Repo:** `mellodyabrego-crypto/fitcheck-ai`
- **Legacy:** `fitcheck-ai-546.netlify.app` (Netlify) still alive as a backup; `netlify.toml` is kept in sync.
- **CI gate:** the `verify` job runs `dart format --set-exit-if-changed`, `flutter analyze --no-fatal-infos`, and `flutter test` before deploy. A formatting drift will block the deploy.
- **Local build:**
  ```bash
  /Users/nelly/development/flutter/bin/flutter build web --release \
    --dart-define=SUPABASE_URL=https://ntfgkukhjfzbmumhyqzq.supabase.co \
    --dart-define=SUPABASE_ANON_KEY='<anon-key>' \
    --dart-define=SENTRY_DSN='<optional>' \
    --dart-define=POSTHOG_API_KEY='<optional>' \
    --dart-define=APP_ENV=production
  ```
- `.env` is bundled for local dev only; in production the creds come from `--dart-define`.

## Branding rules
- App name is **Her Style Co.** everywhere — never "GRWM", never "The Candy Shop"
- Colors: primary `#C48A96` (blush), accent `#B89A5D` (gold), primaryDeep `#A96E7A`
- Login logo uses `GoogleFonts.pacifico` for the title with blush→gold gradient
- Every Scaffold body must be wrapped with `WithDecorations(sparse: true, child: ...)`

## Architecture
- **State:** Riverpod (`StateProvider`, `FutureProvider`, `AsyncNotifierProvider`)
- **Navigation:** GoRouter — routes in `lib/router.dart`. Public routes (no auth required): `/auth`, `/terms`, `/privacy`. 404s render via `errorBuilder`.
- **Backend:** Supabase project **`ntfgkukhjfzbmumhyqzq`** (owned by `mellodyabrego-crypto` account)
- **AI:** Gemini 2.5 / 2.0 Flash via **Supabase Edge Function `gemini-proxy`** — JWT-verified, per-user 50/day quota, model allow-list, 8 KB input cap, 1024-token output cap, 25 s timeout. Key NEVER ships to the browser.
- **Quota infra:** `public.usage_counters` table + `public.increment_gemini_quota()` RPC + `public.my_gemini_quota_today` view (client can read remaining quota). Migration in `supabase/migrations/`.
- **Weather:** Open-Meteo (free, no key) via `lib/services/weather_service.dart`
- **Observability:** `lib/services/observability_service.dart` (Sentry wrapper) + `lib/services/analytics_service.dart` (PostHog wrapper). Both are **null-safe** — empty `SENTRY_DSN` / `POSTHOG_API_KEY` = no-op. Centralised event constants in `AnalyticsEvents`.
- **Persistence (web):** `dart:html` localStorage for profile fields, walkthrough-seen flag, calendar photos
- **Tab perf:** `lib/widgets/lazy_indexed_stack.dart` — only mounts a tab the first time it's shown; state preserved after first visit. Use this, not `IndexedStack`, for any new multi-tab surface.

## Key files to know
| File | Purpose |
|------|---------|
| `lib/router.dart` | All routes — add new screens here |
| `lib/main.dart` | `kDemoMode` flag, app init, dotenv + Supabase init (with guards) |
| `lib/core/theme.dart` | Colors, gradients, text styles |
| `lib/core/constants.dart` | `AppConstants` — reads `String.fromEnvironment()` first, then dotenv |
| `lib/features/home/home_screen.dart` | 7-tab IndexedStack inside `WalkthroughOverlay` |
| `lib/features/wardrobe/wardrobe_controller.dart` | Mock wardrobe (used when real wardrobe empty) |
| `lib/services/gemini_service.dart` | All Gemini calls go through `_postToGemini` which hits the proxy |
| `lib/services/image_service.dart` | Camera/gallery — use `pickWithSheet(context)` |
| `lib/services/share_service.dart` | Web-safe sharing via share_plus text |
| `lib/services/supabase_service.dart` | DB helpers — provider is nullable, `userId` returns `''` when no user |
| `lib/widgets/decorative_symbols.dart` | `WithDecorations` wrapper |
| `lib/widgets/walkthrough_overlay.dart` | 7-step onboarding tour, seen-flag persisted to localStorage |
| `supabase/functions/gemini-proxy/index.ts` | The edge function that keeps the Gemini key server-side |

## Hard rules
1. **Every screen body** uses `WithDecorations(sparse: true, child: ...)` — no exceptions
2. **Camera:** Always use `imageService.pickWithSheet(context)` — never roll your own bottom sheet + `pickFromCamera()` directly
3. **Web sharing:** Use `Share.share(text)` only — never `dart:io` File or path_provider (crashes on web)
4. **Wardrobe images:** Item `name` must accurately describe what the Unsplash photo shows. Always add `errorBuilder`.
5. **Never commit/push** without user approval. Show the diff first.
6. **Gemini calls** go through `_postToGemini` in `GeminiService` (hits the proxy). Never hit `generativelanguage.googleapis.com` directly from client code. The proxy now sends the user's session JWT — anonymous Gemini access is no longer possible.
7. **Don't fabricate AI output.** If an AI call fails, surface an honest error (`⚠️ AI palette check failed`). No "Warm tones detected" fake fallbacks, no auto-generated score-X-out-of-10 on uploads.
8. **Color palette is sacred.** Never change the hex values in `lib/core/theme.dart`. If a foreground fails contrast (e.g. blush `#C48A96` on white = 3.2:1), switch which existing palette token is used (`primary` → `primaryDeep`), don't introduce a new color.
9. **Never rename the pubspec package** (`name: grwm`). Renaming would touch every `package:grwm/...` import. The user-facing brand is "Her Style Co." — that's set in `app.dart` `MaterialApp.title`, `web/manifest.json`, and `web/index.html`.
10. **Image uploads** must go through `SupabaseService.uploadImage` — it does magic-byte MIME sniff (JPEG/PNG/WebP only), 2 MB cap, sets `contentType`. Never call `storage.uploadBinary` directly from a screen.
11. **Image preprocessing:** call `ImageService.compressImage(bytes)` (default 800 px max edge, JPEG@85) before any storage upload. Don't ship raw camera bytes.

## Gemini API (proxy architecture)
- Key is stored as a Supabase Edge Function secret on project `ntfgkukhjfzbmumhyqzq`, NOT in any client bundle
- Client calls: `POST {SUPABASE_URL}/functions/v1/gemini-proxy` with `{model, contents, generationConfig?}` body + anon-key auth header
- Proxy forwards to `generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` server-side
- `GeminiService.isGeminiConfigured` now checks Supabase URL + anon key are present (not a Gemini key)
- **Rotate the key:** `export SUPABASE_ACCESS_TOKEN=<pat> && npx supabase secrets set GEMINI_API_KEY=<new> --project-ref ntfgkukhjfzbmumhyqzq` (no rebuild needed)
- **Redeploy the function:** `npx supabase functions deploy gemini-proxy --project-ref ntfgkukhjfzbmumhyqzq --no-verify-jwt`

## AI outfit generation
- Prompt instructs Gemini to use PRECISE clothing terms (crop top ≠ blouse, strappy heels ≠ block heels)
- Always includes accessories (necklace/earrings), bag, and shoes
- Falls back to `_fallbackOutfit()` when proxy unavailable (no key or server error)

## Tabs & naming
| Index | Tab | Screen |
|-------|-----|--------|
| 0 | My Closet | WardrobeScreen |
| 1 | Outfits | OutfitHistoryScreen (tabs: "Create" / "My Creations") |
| 2 | Shop | ShopScreen |
| 3 | Network | NetworkScreen |
| 4 | Calendar | CalendarScreen ("Design My Day") |
| 5 | Fashion | FashionScreen |
| 6 | Profile | ProfileScreen |

## Honesty rules for demo features
A lot of UI exists that's deliberately marked as preview until the backend/feature lands. **Don't silently make these "real":**
- **Fit Check** — shows an orange "Demo score — real AI analysis coming soon" banner; feedback labeled "Style Notes", not "AI Feedback"
- **Photo uploads in My Creations** — score = 0 (badge hidden); no fake 7-10 rating generated
- **Paywall** — button is "Coming Soon" + disabled; no fake Start Trial
- **Settings — still Coming Soon:** notifications, reminder time, export, Delete Account
- **Settings — now REAL (since 2026-04-18 hardening):** Terms of Service (`/terms`), Privacy Policy (`/privacy`)
- **Network** — banner says "Sample community — real posting coming soon"
- **Fashion** — header banner "Curated feed — dynamic content coming soon"
- **Shop palette check fallback** — returns `⚠️` error message, not a fabricated "✅ Warm tones detected"
- **Weather** — shows "location unavailable" when geo denied; does NOT silently default to NYC

## Dev server
- Port 3003 is the current dev port: `flutter run -d web-server --web-port 3003 --web-hostname 0.0.0.0`

## Session start — ALWAYS ASK FIRST
Before doing any work in this project, ask Ben/Mellody:
> "Where are we on the user roadmap today — still pre-200, climbing to 1K, 5K, 10K, 25K, or 100K? And what's the top number you're watching this week (retention, signups, cost, something else)?"

Use their answer to pick the right advice tier in `ROADMAP.md`. Do not skip this step, even for small tasks — a tiny refactor can conflict with a scale-tier priority.

## Roadmap
See [ROADMAP.md](ROADMAP.md) for the 1K / 5K / 10K / 25K / 100K tier checklists and what breaks at each level.

## Hardening pass — 2026-04-18 (commit `e7d75ea`)
A hostile review surfaced 20 critical gaps; all shipped in one PR. **The deploy is not complete until the manual steps in [HANDOFF.md](HANDOFF.md) are run** — namely:

1. `flutter pub get` (adds `sentry_flutter`, `posthog_flutter`)
2. Apply `supabase/migrations/20260418_quota_and_storage_lockdown.sql` in Supabase SQL editor
3. Re-deploy `gemini-proxy` **without** `--no-verify-jwt`
4. Set bucket size cap (2 MB) + MIME allow-list in Supabase storage dashboard
5. (Optional) Add `SENTRY_DSN` + `POSTHOG_API_KEY` to GitHub Actions repo secrets

Until those run, the new code paths are inert (Sentry/PostHog no-op; quota RPC fail-opens; edge function still allows anon). HANDOFF.md is the single source of truth for follow-ups.

## Competitive context
Top three to beat (ranked by user threat): **Whering** (~5M users; bad cutouts, paywalls Calendar), **Acloset** (~2M; weak on Western brands, no web), **Indyx** (smaller; strong CPW + resale). HSC's defensible gaps to attack: occasion-aware planning (Calendar + Weather + AI fused), inclusive body types, no-paywall closet, conversational input. See conversation 2026-04-18 for full breakdown.
