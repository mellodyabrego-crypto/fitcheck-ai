# Her Style Co. — User Growth Roadmap

Each tier lists **(what breaks first)** · **(what to build)** · **(what to measure)** · **(what to spend)**.
Ask "where are we today?" before planning work — tier-appropriate advice only.

---

## Tier 0 → 200 users (pre-launch hardening)

Before any outbound push, the 10 must-fix items from the hostile review:

1. Gemini proxy: JWT verify, per-user daily quota, model allow-list, input-size cap.
2. Project-ref audit: confirm edge function deployed to the right Supabase project.
3. Sentry + Posthog wired (free tiers).
4. Terms of Service + Privacy Policy live (Termly or iubenda).
5. `netlify.toml` security headers: CSP, HSTS, X-Frame-Options.
6. Accessibility pass: `Semantics` on every interactive widget, fix `#C48A96` contrast, honor `textScaler`.
7. Walkthrough: add Skip button, track funnel events.
8. Server-side image resize + MIME check.
9. One retention channel shipped (web push OR email reminder).
10. PWA manifest fixed to "Her Style Co." + install prompt.

---

## Tier 1 → 1,000 users

**Breaks first:** Supabase free storage, unmetered Gemini cost, Unsplash commercial licensing.

**Build:**
- Paid Supabase tier (Pro $25/mo) before 150 users.
- Image transforms (Supabase or Cloudflare).
- Replace Unsplash placeholders with licensed stock or user uploads only.
- Onboarding funnel instrumented end-to-end.
- Support inbox (front, help-scout free, or a simple `support@` Gmail).

**Measure:** D1/D7/D30 retention, onboarding completion %, AI generations per WAU, Gemini cost per DAU, crash-free sessions %.

**Spend:** ~$60/mo (Supabase Pro, Termly, domain, Postmark/Resend starter).

---

## Tier 2 → 5,000 users

**Breaks first:** Gemini concurrency, single-region latency, moderation surface on Network tab.

**Build:**
- Proper auth flows: password reset, email verify, Apple/Google Sign-In.
- Native app wrappers (Capacitor or Flutter iOS/Android).
- Outfit generation cache (same wardrobe + weather + event → cached response).
- Referral loop (track K-factor, asymmetric "rate a friend's outfit" share mechanic).
- Network moderation (Perspective API or user-report queue).
- DMCA + UGC policy.

**Measure:** viral coefficient K, CAC by channel, server cost per DAU, feature adoption by cohort.

**Spend:** ~$300/mo + part-time contractor for support/moderation (~10 hr/wk).

---

## Tier 3 → 10,000 users

**Breaks first:** Solo ops, "Coming Soon" debt, cross-region latency.

**Build:**
- Ship paywall for real (Stripe + RevenueCat).
- Dedicated async job queue for outfit generation (Inngest / pg-boss).
- Design system doc + component audit.
- Incident runbook + status page (statuspage.io or upptime).
- Admin dashboard for support/refunds.

**Measure:** MRR, churn, free→paid conversion, NPS, support ticket volume, p95 generation latency.

**Spend:** First FT engineer or senior contractor. RevenueCat (free <$10K MTR), Stripe fees, Inngest/Trigger.dev.

---

## Tier 4 → 25,000 users

**Breaks first:** Persona mismatch, English-only copy, manual content ops.

**Build:**
- Segmentation: teen / work / mom / bride personas, each with tailored first-week flow.
- i18n via Flutter `intl` (start Spanish + Portuguese).
- Admin dashboard for support, refunds, moderation.
- A/B test framework (GrowthBook).
- Influencer / affiliate tooling.

**Measure:** segment-level retention, localization lift, CAC by channel, LTV by segment.

**Spend:** Growth lead, second engineer, designer contract, data warehouse starter.

---

## Tier 5 → 100,000 users

**Breaks first:** Everything that wasn't a real discipline — compliance, reliability, org.

**Build:**
- SOC 2 Type I (Vanta).
- On-call rotation + SLAs.
- Dedicated infra (Supabase Team or self-hosted Postgres).
- ML team owning outfit recommender (embeddings-based retrieval on your own wardrobe corpus + "similar user" signal).
- Retail / brand partnerships — this is where the real revenue lives (affiliate + paid placements in Shop tab).

**Measure:** cohort P&L, brand partnership revenue share, model recommendation CTR, refund rate.

**Spend:** CTO/eng lead, security engineer, partnerships lead, legal counsel retainer.

---

## Blind-spot questions (revisit quarterly)

**Design:** Who is the one persona? What is the 10-second job? What does the app look like with no AI?
**Dev:** What's the DR / backup policy? Who gets paged? What's the test/CI bar? What's the model-swap plan?
**Marketing:** Which single acquisition channel? What's the asymmetric share loop? What's the monetization mechanism? Who is the face of the brand?
