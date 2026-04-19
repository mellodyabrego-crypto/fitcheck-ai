// Plain-text source of Terms of Service and Privacy Policy. Kept in code so
// the app can be deployed offline. Replace with the version reviewed by your
// attorney before paid users come on. Last reviewed: 2026-04-18.

const String kTermsLastUpdated = 'April 18, 2026';

const String kTermsOfService = '''
Her Style Co. — Terms of Service
Last updated: $kTermsLastUpdated

1. Acceptance of Terms
By creating an account or using Her Style Co. ("the Service"), you agree to these
Terms of Service. If you do not agree, do not use the Service.

2. Eligibility
You must be at least 13 years old (16 in the EU/UK). By using the Service you
represent that you meet this requirement.

3. Account
You are responsible for safeguarding your account credentials and for all
activity under your account. Notify us immediately at hello@herstyleco.app if
you suspect unauthorized access.

4. Content & License
You retain ownership of photos, wardrobe items, and other content you upload.
You grant Her Style Co. a worldwide, non-exclusive, royalty-free license to
store, display, and process this content solely to operate the Service for you.

5. AI Output
The Service uses third-party AI models (currently Google Gemini) to generate
outfit suggestions, color analyses, and style notes. AI output is provided
"as-is" and may be incorrect, biased, or inappropriate. Use it as inspiration,
not as professional advice.

6. Acceptable Use
You may not: (a) upload illegal or sexually explicit content; (b) impersonate
others; (c) attempt to reverse-engineer the Service or its AI prompts; (d) use
the Service to harass, defame, or violate the rights of others; (e) automate or
scrape the Service.

7. Subscription & Payments
Some features may require a paid subscription. Pricing, billing, and refund
policies are shown at point of purchase. Subscriptions auto-renew until
cancelled.

8. Termination
We may suspend or terminate accounts that violate these Terms. You may close
your account at any time from Settings.

9. Disclaimer & Limitation of Liability
THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. TO THE MAXIMUM
EXTENT PERMITTED BY LAW, OUR TOTAL LIABILITY ARISING OUT OF OR RELATED TO THESE
TERMS WILL NOT EXCEED THE AMOUNT YOU PAID US IN THE 12 MONTHS BEFORE THE CLAIM.

10. Changes
We may update these Terms. Material changes will be announced in-app at least
14 days before they take effect.

11. Contact
hello@herstyleco.app
''';

const String kPrivacyPolicy = '''
Her Style Co. — Privacy Policy
Last updated: $kTermsLastUpdated

1. What we collect
- Account data: email, display name, profile photo (if you upload one).
- Style profile: aesthetics, body type, sizes, color preferences, brands —
  collected during onboarding.
- Wardrobe & outfits: photos and metadata you upload to your closet.
- Analytics: pseudonymous usage events (e.g. "opened Outfits tab") used to
  improve the product.
- Crash reports: stack traces of app errors (no photo data attached).

2. How we use it
- To run the core features you asked for (outfit generation, calendar, etc.).
- To send AI requests to our processor (currently Google Gemini); your prompts
  and uploaded images are sent to the AI provider for processing.
- To improve the product (aggregate analytics, error monitoring).

3. Who we share it with
- Supabase (database + storage + auth) — our backend infrastructure provider.
- Google Gemini — AI processor for outfit/style/color analysis.
- PostHog — product analytics (pseudonymous user IDs only).
- Sentry — crash + error monitoring (stack traces only, no photos).
- We never sell your personal data.

4. Where it lives
Data is stored in the United States. By using the Service you consent to this
transfer.

5. Your rights
You can: (a) export your data; (b) delete your account and all associated data;
(c) request a copy of personal data we hold; (d) object to processing.
Email hello@herstyleco.app — we respond within 30 days.

6. Cookies
We use only the cookies/local-storage entries needed to keep you signed in and
remember your onboarding progress. We do not use advertising trackers.

7. Children
The Service is not intended for users under 13 (or under 16 in the EU/UK).
We do not knowingly collect data from children. If you believe a child has
created an account, contact hello@herstyleco.app.

8. Retention
We retain your account data while your account is active. Deleted accounts are
purged from our active systems within 30 days; backups are rotated within 90
days.

9. Security
We use TLS in transit, RLS at the database layer, and server-side AI key
storage. No system is perfect — report suspected vulnerabilities to
security@herstyleco.app.

10. Changes
We will announce material changes in-app at least 14 days before they take
effect.

11. Contact
hello@herstyleco.app
''';
