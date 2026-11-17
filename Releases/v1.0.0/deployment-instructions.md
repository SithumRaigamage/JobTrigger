# JobTrigger Release 1.0.0 — Complete Production Deployment Guide

This document is the comprehensive, all-in-one deployment guide for **JobTrigger Release 1.0.0**. It covers the lowest-cost hosting breakdown, sequential deployment steps, third-party service setups (Umami, Sentry, Firebase, RevenueCat, Paddle), transactional emails, customer support, and store approvals.

---

## 1. Hosting & Infrastructure Cost Breakdown (Lowest Viable Cost)

You can launch and run the entire stack for **~$10 – $14 / year** initially, scaling up only when user traffic grows.

| Component | Recommended Provider | Tier / Plan | Monthly Cost | Annual Cost | Notes |
|---|---|---|---|---|---|
| **Domain** | Cloudflare Registrar / Porkbun / Namecheap | `.app` or `.com` | ~$1.00 / mo | **~$10.00 – $14.00 / yr** | `.app` domains have built-in HSTS (HTTPS required). |
| **Frontend / Web Portal** | **Vercel** | Hobby Plan (Free) | **$0.00 / mo** | $0.00 | Free custom domain, SSL, edge network, Next.js optimization. |
| **Backend API** | **Render.com** *(Option A: Free)*<br>**Hetzner / Railway** *(Option B: 24/7)* | Free Web Service<br>Hetzner CX22 / Railway | **$0.00 / mo**<br>~$4.50 – $5.00 / mo | $0.00<br>~$54.00 / yr | Free tier spins down after 15 min idle (30s spin-up). $4.50/mo avoids sleep. |
| **Database** | **MongoDB Atlas** | Shared M0 (Free Forever) | **$0.00 / mo** | $0.00 | 512 MB storage, shared RAM, automated TLS 1.3, backup snapshots. |
| **Email (SMTP)** | **Resend** or **SendGrid** | Free Tier | **$0.00 / mo** | $0.00 | 3,000 emails/mo free (plenty for auth & verification). |
| **Analytics** | **Umami Cloud** | Hobby Free Tier | **$0.00 / mo** | $0.00 | 10,000 events/mo free, cookie-free, no GDPR consent banner. |
| **Crash Monitoring** | **Sentry.io** | Developer Free Tier | **$0.00 / mo** | $0.00 | 5,000 error events/mo free. |
| **Push Notifications** | **Google Firebase (FCM)** | Spark Plan (Free) | **$0.00 / mo** | $0.00 | Generous free push notifications. |
| **Payments Gateway** | **RevenueCat** (App)<br>**Paddle** (Web) | Free Tier ($0 under $2,500 MTR)<br>Pay-as-you-go (5% + 50¢) | **$0.00 / mo** | $0.00 | No upfront cost; only pay small fee per transaction. |
| **Developer Accounts** | **Google Play Console**<br>**Apple Developer** | One-time<br>Annual membership | —<br>— | **$25.00** (one-time)<br>**$99.00 / yr** *(optional for iOS)* | Google Play requires $25 once. Apple requires $99/yr. |

> **Summary**: Absolute minimum initial setup cost is **$10 – $14/year** (Domain only) + **$25** one-time Google Play fee.

---

## 2. Analytics Setup (Umami)

JobTrigger uses **Umami** for cookie-free, privacy-preserving analytics (no cookie banners required by GDPR).

### Option A: Umami Cloud (Recommended, Free)
1. Sign up at [https://cloud.umami.is](https://cloud.umami.is).
2. Click **Settings → Websites → Add Website**.
   * **Name**: `JobTrigger Web`
   * **Domain**: `jobtrigger.app`
3. Copy your unique **Website ID** (UUID format).
4. In your Vercel deployment (or `JobTrigger-Web/.env.local`), configure:
   ```env
   NEXT_PUBLIC_UMAMI_WEBSITE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   UMAMI_SCRIPT_URL=https://cloud.umami.is/script.js
   ```
5. *(Optional Backend API Analytics)*: In `JobTrigger-Backend/.env`, provide:
   ```env
   UMAMI_API_URL=https://api-gateway.umami.dev
   UMAMI_WEBSITE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

---

## 3. Crash & Error Reporting Setup (Sentry / GlitchTip)

The apps include built-in PII and credential scrubbing (`event_scrubber.dart`) to ensure no passwords or CI tokens are sent to error logs.

### Sentry.io Setup (Free Developer Plan)
1. Sign up at [https://sentry.io](https://sentry.io).
2. Create an organization: `jobtrigger`.
3. Create three distinct projects:
   * **`jobtrigger-frontend`** (Platform: Flutter)
   * **`jobtrigger-backend`** (Platform: Node.js / Express)
   * **`jobtrigger-web`** (Platform: Next.js)
4. Grab the client DSN keys:
   * **Backend**: In `JobTrigger-Backend/.env`:
     ```env
     SENTRY_DSN=https://<key>@<host>/<project-id>
     ```
   * **Web**: In `JobTrigger-Web/.env.local` / Vercel Environment:
     ```env
     SENTRY_DSN=https://<key>@<host>/<project-id>
     ```
   * **Flutter App**: Add DSN to `JobTrigger-Frontend/config/prod.json`:
     ```json
     {
       "ENVIRONMENT": "prod",
       "BACKEND_BASE_URL": "https://api.jobtrigger.app",
       "WEBSITE_BASE_URL": "https://jobtrigger.app",
       "SENTRY_DSN": "https://<key>@<host>/<project-id>"
     }
     ```
5. **App Store & Play Privacy Compliance**:
   Ensure `tracesSampleRate = 0` (performance monitoring disabled) so you don't collect performance tracking data without user consent.

---

## 4. Push Notifications Setup (Firebase Cloud Messaging)

Real-time build alerts use Firebase Cloud Messaging (FCM).

### Step 1: Create Firebase Project
1. Open [Firebase Console](https://console.firebase.google.com/) and create a project named **`JobTrigger`**.
2. Disable Google Analytics (optional, keeps privacy clean).

### Step 2: Configure Android App
1. Add an Android App in Firebase Console:
   * **Android Package Name**: `com.sraig.jobtrigger`
2. Download `google-services.json` and place it in:
   `JobTrigger-Frontend/android/app/google-services.json`

### Step 3: Configure iOS App (Apple Push Notifications)
1. Add an iOS App in Firebase Console:
   * **Apple Bundle ID**: `com.sraig.jobtrigger`
2. Download `GoogleService-Info.plist` and place it in:
   `JobTrigger-Frontend/ios/Runner/GoogleService-Info.plist`
3. In Apple Developer Account → Certificates, Identifiers & Profiles → Keys:
   * Create an APNs key with "Apple Push Notifications service (APNs)".
   * Download the `.p8` file.
4. Upload `.p8` to Firebase Console: **Project Settings → Cloud Messaging → Apple app configuration**.

### Step 4: Backend Push Credentials
1. In Firebase Console: **Project Settings → Service Accounts → Generate new private key**.
2. Download the JSON key file.
3. Minify the JSON into a single line string and set it in `JobTrigger-Backend/.env`:
   ```env
   FCM_SERVICE_ACCOUNT={"type":"service_account","project_id":"jobtrigger",...}
   ```

---

## 5. Payment Integrations Setup (RevenueCat & Paddle)

JobTrigger uses **RevenueCat** for in-app mobile subscriptions and **Paddle** for web merchant-of-record checkouts.

### A. Mobile Subscriptions (RevenueCat)
1. Sign up at [https://www.revenuecat.com](https://www.revenuecat.com) (Free up to $2,500/mo tracked revenue).
2. Create project: `JobTrigger`.
3. Add Entitlement: Identifier = **`pro`**.
4. Configure Products:
   * **App Store Connect**:
     * Subscriptions → Subscription Group `JobTrigger Pro`.
     * Product 1: `jobtrigger_pro_monthly` ($2.99/mo).
     * Product 2: `jobtrigger_pro_yearly` ($29.99/yr, 7-day free trial).
   * **Google Play Console**:
     * Monetize → Subscriptions.
     * Product: `jobtrigger-pro`.
     * Base plan 1: Monthly ($2.99).
     * Base plan 2: Yearly ($29.99 with 7-day trial).
5. Link Products to Entitlement in RevenueCat under **Default Offering**:
   * `$rc_monthly` → `jobtrigger_pro_monthly` / `jobtrigger-pro:monthly`
   * `$rc_annual` → `jobtrigger_pro_yearly` / `jobtrigger-pro:yearly`
6. Set Webhook:
   * In RevenueCat → Project Settings → Integrations → Webhooks:
   * Webhook URL: `https://api.jobtrigger.app/api/billing/revenuecat`
   * Authorization Header: `<create-secret-token>`
7. Environment Variables:
   * `JobTrigger-Backend/.env`:
     ```env
     REVENUECAT_SECRET_API_KEY=appl_...
     REVENUECAT_WEBHOOK_AUTH=<matching-secret-token>
     ```
   * `JobTrigger-Frontend/config/prod.json`:
     ```json
     {
       "REVENUECAT_APPLE_KEY": "appl_...",
       "REVENUECAT_GOOGLE_KEY": "goog_..."
     }
     ```

### B. Web Billing (Paddle)
1. Sign up at [https://paddle.com](https://paddle.com) (handles global taxes and VAT).
2. Create product `JobTrigger Pro` with monthly & annual recurring prices.
3. Configure Webhook in Paddle Dashboard:
   * URL: `https://api.jobtrigger.app/api/billing/paddle/webhook`
4. Set Environment Variables:
   * `JobTrigger-Backend/.env`:
     ```env
     PADDLE_WEBHOOK_SECRET=pdl_ntfset_...
     PADDLE_API_KEY=...
     ```
   * `JobTrigger-Web/.env.local` / Vercel:
     ```env
     NEXT_PUBLIC_PADDLE_CLIENT_TOKEN=live_...
     NEXT_PUBLIC_PADDLE_ENV=production
     ```

---

## 6. Email, Support & Operational Services

### A. Transactional Emails (Resend / SendGrid)
Used for password reset, student verification codes, and renewal notices.
1. Sign up for **Resend** ([https://resend.com](https://resend.com)) — 3,000 emails/month free.
2. Add and verify your domain `jobtrigger.app` (add SPF, DKIM, DMARC TXT records).
3. Generate an API Key.
4. Set in `JobTrigger-Backend/.env`:
   ```env
   SMTP_HOST=smtp.resend.com
   SMTP_PORT=587
   SMTP_SECURE=false
   SMTP_USER=resend
   SMTP_PASS=re_xxxxxxxxxxxxxxxxxxxx
   MAIL_FROM="JobTrigger <no-reply@jobtrigger.app>"
   RESET_PASSWORD_URL=https://jobtrigger.app/reset-password
   ```

### B. Customer Support & Inquiries
1. **Free Email Forwarding**:
   * Use **Cloudflare Email Routing** ($0/mo) on `jobtrigger.app`.
   * Create route: `support@jobtrigger.app` → forward to your personal Gmail/work email.
2. **In-App Support Links**:
   * The app profile footer opens `mailto:support@jobtrigger.app`.
3. **Help & Guides**:
   * Remote access help hosted at `docs/remote-access.md` and in-app `RemoteAccessGuideScreen`.
   * Token generation help in-app and at `docs/token-guides.md`.

### C. Student Verification Setup
1. In `JobTrigger-Backend/.env`:
   ```env
   STUDENT_ADMIN_EMAIL=admin@jobtrigger.app
   STUDENT_RENEWAL_ENABLED=true
   ```
2. Uploaded student verification documents are AES-encrypted and automatically deleted 30 days after review.

---

## 7. Phased Execution Checklist

### Phase 1: GitHub Release (`v1.0.0`)
- [ ] 1. Verify `develop` passes all CI checks.
- [ ] 2. Sync tools manifest: `node scripts/sync-tools.mjs --check`.
- [ ] 3. Verify version bumps (`pubspec.yaml`: 1.0.0+1, backend & web `package.json`: 1.0.0).
- [ ] 4. Tag commit:
  ```bash
  git tag -a v1.0.0 -m "Release 1.0.0: Jenkins, SonarQube, and GitHub Actions"
  git push origin v1.0.0
  ```
- [ ] 5. Build release APK:
  ```bash
  cd JobTrigger-Frontend
  flutter build apk --release --dart-define-from-file=config/prod.json
  ```
- [ ] 6. Publish GitHub release:
  ```bash
  gh release create v1.0.0 \
    build/app/outputs/flutter-apk/app-release.apk#JobTrigger-v1.0.0.apk \
    --title "JobTrigger 1.0.0" \
    --notes-file Releases/v1.0.0/release-notes.md
  ```

### Phase 2: Production Backend Deployment
- [ ] 1. Spin up MongoDB Atlas production cluster (M0 free).
- [ ] 2. Deploy `JobTrigger-Backend` (Render Docker / Railway).
- [ ] 3. Populate production environment variables (`JWT_SECRET`, `CREDENTIALS_ENCRYPTION_KEY`, `MONGODB_URI`, `SMTP_*`, `CORS_ORIGIN`).
- [ ] 4. Run database index check / initialization.
- [ ] 5. Verify `GET https://api.jobtrigger.app/health` returns `200 OK`.

### Phase 3: Web Deployment (Vercel)
- [ ] 1. Import `JobTrigger-Web` into Vercel.
- [ ] 2. Configure environment variables (`JOBTRIGGER_BACKEND_URL=https://api.jobtrigger.app`, `SESSION_SECRET`).
- [ ] 3. Attach custom domain `jobtrigger.app`.
- [ ] 4. Test sign-in, changelog display, and pricing tables.

### Phase 4: Android Deployment (Google Play Console)
- [ ] 1. Generate release keystore:
  ```bash
  keytool -genkey -v -keystore ~/jobtrigger-upload-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] 2. Configure `JobTrigger-Frontend/android/key.properties`.
- [ ] 3. Build production Android App Bundle:
  ```bash
  cd JobTrigger-Frontend
  flutter build appbundle --release --dart-define-from-file=config/prod.json
  ```
- [ ] 4. Create app listing in Google Play Console.
- [ ] 5. Upload 7 store screenshots from `release/store-screenshots/android-2by1/`.
- [ ] 6. Fill Data Safety questions (declared in `tasks/release-checklist.md`).
- [ ] 7. Submit to **Internal Testing** track first, test on real device, then promote to Production.
