# Her Style Co. — Project Guide for Claude

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
- **Production:** https://fitcheck-ai-546.netlify.app (Netlify site `fitcheck-ai-546`)
- **Redeploy:**
  ```bash
  /Users/nelly/development/flutter/bin/flutter build web --release \
    --dart-define=SUPABASE_URL=https://ntfgkukhjfzbmumhyqzq.supabase.co \
    --dart-define=SUPABASE_ANON_KEY='<anon-key>'
  netlify deploy --prod --dir=build/web
  ```
- `.env` is bundled for local dev only; in production the creds come from `--dart-define`.

## Branding rules
- App name is **Her Style Co.** everywhere — never "GRWM", never "The Candy Shop"
- Colors: primary `#C48A96` (blush), accent `#B89A5D` (gold), primaryDeep `#A96E7A`
- Login logo uses `GoogleFonts.pacifico` for the title with blush→gold gradient
- Every Scaffold body must be wrapped with `WithDecorations(sparse: true, child: ...)`

## Architecture
- **State:** Riverpod (`StateProvider`, `FutureProvider`, `AsyncNotifierProvider`)
- **Navigation:** GoRouter — routes in `lib/router.dart`
- **Backend:** Supabase project **`ntfgkukhjfzbmumhyqzq`** (owned by `mellodyabrego-crypto` account)
- **AI:** Gemini 2.0 Flash via **Supabase Edge Function `gemini-proxy`** — the key NEVER ships to the browser
- **Weather:** Open-Meteo (free, no key) via `lib/services/weather_service.dart`
- **Persistence (web):** `dart:html` localStorage for profile fields, walkthrough-seen flag, calendar photos

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
6. **Gemini calls** go through `_postToGemini` in `GeminiService` (hits the proxy). Never hit `generativelanguage.googleapis.com` directly from client code.
7. **Don't fabricate AI output.** If an AI call fails, surface an honest error (`⚠️ AI palette check failed`). No "Warm tones detected" fake fallbacks, no auto-generated score-X-out-of-10 on uploads.

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
- **Settings** — notifications, reminder time, export, Terms, Privacy, Delete Account are all marked "Coming Soon"
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
