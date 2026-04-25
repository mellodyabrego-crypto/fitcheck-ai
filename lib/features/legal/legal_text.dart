// Plain-text source of Terms of Service and Privacy Policy. Kept in code so
// the app can be deployed offline.
//
// IMPORTANT — every block flagged with <<LEGAL REVIEW>> is a good-faith
// product description but has NOT been reviewed by a licensed attorney. Before
// running paid acquisition or accepting users from regulated jurisdictions
// (EU/UK/CA/CCPA-state) you must have qualified counsel review:
//   * the data-retention model (we anonymize-and-keep on account deletion,
//     which is a non-standard "soft delete" pattern)
//   * the AI processor disclosure (Google Gemini)
//   * the children clause (currently 13+/16+ EU)
//   * the limitation-of-liability cap
//   * the cookie/localStorage disclosure
//
// Last edit (product behavior accurate): 2026-04-25.

const String kTermsLastUpdated = 'April 25, 2026';

const String kTermsOfService = '''
Her Style Co. — Terms of Service
Last updated: $kTermsLastUpdated

[<<LEGAL REVIEW REQUIRED — see file header for the full list>>]

1. Acceptance of Terms
By creating an account or using Her Style Co. ("the Service"), you agree to
these Terms of Service. If you do not agree, do not use the Service.

2. Eligibility
You must be at least 13 years old (16 in the EU/UK). By using the Service you
represent that you meet this requirement. <<LEGAL REVIEW: confirm minimum age
for your launch jurisdictions; confirm parental consent flow if you decide to
allow under-16 users in any market.>>

3. Account
You are responsible for safeguarding your account credentials and for all
activity under your account. Notify us immediately at hello@herstyleco.app if
you suspect unauthorized access. We use Supabase for authentication; passwords
are never stored in plaintext on our servers.

4. Content & License
You retain ownership of photos, wardrobe items, and other content you upload.
You grant Her Style Co. a worldwide, non-exclusive, royalty-free license to
store, display, and process this content solely to operate the Service for you.
This license terminates when you delete the content from your closet.

5. AI Output
The Service uses third-party AI models (currently Google Gemini 2.5 Flash via
Google Cloud) to generate outfit suggestions, color analyses, fit checks, and
style notes. AI output is provided "as-is" and may be incorrect, biased, or
inappropriate. Use it as inspiration, not as professional advice. We do not
guarantee a specific style outcome.

6. Acceptable Use
You may not: (a) upload illegal or sexually explicit content; (b) impersonate
others; (c) attempt to reverse-engineer the Service or its AI prompts; (d) use
the Service to harass, defame, or violate the rights of others; (e) automate
or scrape the Service; (f) attempt to evade rate limits or quota controls.

7. Subscription & Payments
Some features may require a paid subscription. Pricing, billing, and refund
policies are shown at point of purchase. Subscriptions auto-renew until
cancelled. <<LEGAL REVIEW: payment processor (Stripe / RevenueCat / Apple IAP /
Google Play) and consumer-protection disclosures are jurisdiction-specific.>>

8. Termination
We may suspend or terminate accounts that violate these Terms. You may close
your account at any time from Settings → Delete Account. See the Privacy
Policy §8 for what happens to your data after account closure — note that we
retain anonymized usage data for analytics.

9. Disclaimer & Limitation of Liability
THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. TO THE MAXIMUM
EXTENT PERMITTED BY LAW, OUR TOTAL LIABILITY ARISING OUT OF OR RELATED TO
THESE TERMS WILL NOT EXCEED THE AMOUNT YOU PAID US IN THE 12 MONTHS BEFORE THE
CLAIM, OR USD \$100, WHICHEVER IS GREATER. <<LEGAL REVIEW: cap is unenforceable
in some jurisdictions.>>

10. Governing Law
<<LEGAL REVIEW: pick a venue. Common choices for US-headquartered SaaS:
Delaware or California. Mandatory-arbitration + class-action waiver clauses
are also commonly added here and require careful jurisdiction-aware drafting.>>

11. Changes
We may update these Terms. Material changes will be announced in-app at least
14 days before they take effect. Continued use after the effective date
constitutes acceptance.

12. Contact
hello@herstyleco.app
''';

const String kPrivacyPolicy = '''
Her Style Co. — Privacy Policy
Last updated: $kTermsLastUpdated

[<<LEGAL REVIEW REQUIRED — see file header for the full list>>]

1. What we collect
- Account data: email, display name, hashed password (via Supabase Auth).
- Style profile (during onboarding): date of birth, gender, country, state,
  goals, body type, aesthetics, brands, sizes, color preferences, skin-tone
  undertone, referral source, notification preference, weather opt-in.
- Wardrobe & outfits: photos you upload, plus metadata (name, color, category,
  brand). Photos are stored on Supabase Storage in a per-user directory.
- Outfit feedback: accept/reject/favorite signals on AI-generated outfits, used
  to personalise future suggestions.
- Approximate location: only if you opt in to "Dress according to weather".
  Used solely to fetch the local forecast from Open-Meteo. Coordinates are not
  stored on our servers — they are sent to the weather API for the request and
  forgotten.
- Analytics: pseudonymous usage events (e.g. "opened Outfits tab") via PostHog.
- Crash reports: stack traces of app errors via Sentry (no photo data).

2. How we use it
- To run the core features you asked for (outfit generation, fit check,
  calendar, shop, etc.).
- To send prompts and images to our AI processor (Google Gemini) for outfit
  generation, color analysis, and fit-check scoring.
- To personalise suggestions based on your style profile and outfit feedback.
- To improve the product (aggregate analytics, error monitoring).
- To send the daily outfit reminder if you opt in.

3. Who we share it with
- Supabase (Postgres + Storage + Auth) — our backend.
- Google Gemini (Google Cloud) — AI processor. Your prompt text and uploaded
  images are transmitted to Google for processing. Per Google's API terms,
  Gemini API content is not used to train Google models.
  <<LEGAL REVIEW: confirm latest Google Gemini API data-use terms before
  shipping to paid users; the consumer Gemini app and the API have different
  defaults.>>
- PostHog — product analytics (pseudonymous user IDs only, no photos, no
  email). Hosted in the United States.
- Sentry — crash + error monitoring (stack traces only, no photos).
- Open-Meteo — only if weather opt-in is enabled. Receives coordinates per
  request, returns forecast. No account or tracking.
- We never sell your personal data.

4. Where it lives
Data is stored in the United States (Supabase US region, PostHog US, Sentry
US). By using the Service you consent to this transfer. <<LEGAL REVIEW:
EU/UK users require a lawful transfer mechanism (SCCs / UK IDTA) and a
Data Processing Agreement with each subprocessor.>>

5. Your rights
You can:
(a) Export your data — Settings → Export Wardrobe downloads a JSON file with
    your profile, wardrobe items, outfits, and feedback.
(b) Delete your account — Settings → Delete Account. See §8 below for what
    happens to your data after deletion.
(c) Request a copy of personal data we hold (beyond the export) by emailing
    hello@herstyleco.app — we respond within 30 days.
(d) Object to processing or request rectification — email us.
(e) Withdraw consent for weather/location at any time in Settings.
<<LEGAL REVIEW: GDPR/UK GDPR/CCPA/CPRA each define rights slightly differently;
language above is good-faith but not jurisdiction-tuned.>>

6. Cookies & local storage
We use only the cookies/local-storage entries needed to keep you signed in and
remember your onboarding progress, sizes, and color season. We do not use
advertising trackers, retargeting pixels, or third-party advertising cookies.
<<LEGAL REVIEW: EU/UK users may still need a cookie consent banner depending
on counsel's read of the strict-necessity exception.>>

7. Children
The Service is not intended for users under 13 (or under 16 in the EU/UK). We
do not knowingly collect data from children. The onboarding date-of-birth
picker enforces a 13+ minimum. If you believe a child has created an account,
contact hello@herstyleco.app.

8. Retention and account deletion
This is the part most products word incorrectly — we are calling it out plainly.

When you delete your account from Settings → Delete Account:
  * You are permanently signed out and CANNOT log in again with the same
    email.
  * Your account is BANNED at the auth layer (a 100-year ban via Supabase
    Auth), so no reactivation is possible.
  * Your profile is marked as deleted (deleted_at timestamp).
  * Your wardrobe items, outfits, outfit feedback, and uploaded photos are
    RETAINED in our database in anonymized form for analytics, model
    improvement, and aggregate reporting. Items remain associated with your
    (now banned) user id but are not visible to you or anyone else.
  * To request a HARD delete (full purge of all rows and storage objects),
    email hello@herstyleco.app and reference your account email. We will
    process within 30 days.
<<LEGAL REVIEW: under GDPR/UK GDPR Article 17, users have a right to erasure
in many circumstances. The "soft delete + retain for analytics" model above
must either be supportable by a lawful basis (e.g. legitimate interest in
aggregated analytics) OR upgraded to a true erasure path on request, which
the bullet above provides. Counsel should confirm the legitimate-interest
balancing test for your retention period.>>

9. Security
We use TLS in transit, row-level security at the database layer, server-side
AI key storage, magic-byte MIME sniffing on uploads, per-user storage
directories, and a daily AI quota per user. No system is perfect — report
suspected vulnerabilities to security@herstyleco.app.

10. Changes
We will announce material changes in-app at least 14 days before they take
effect.

11. Contact
hello@herstyleco.app
''';
