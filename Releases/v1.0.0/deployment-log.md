# Deployment Log — v1.0.0

- **Version**: `1.0.0`
- **Date**: 2026-11-19
- **Base Commit SHA**: `1e589cb` (develop after PR #147 merged the billing
  closeout on 2026-11-19; re-confirm
  the tag commit when cutting the release)

> **Status: plan, not executed.** The values below are the intended
> production configuration. Nothing here has been deployed or stored yet;
> tick each step and replace placeholder secrets during the real
> deployment. Checked 2026-11-19: neither `api.jobtrigger.app` nor
> `jobtrigger.app` resolves, so no production deployment is live.

---

## 1. Backend Infrastructure (Render / Docker)

- **Target Host**: Render / Container Service
- **Build Target**: `JobTrigger-Backend/Dockerfile`
- **Production URL**: `https://api.jobtrigger.app`
- **Database**: MongoDB Atlas Production Cluster
- **Verification**: `GET https://api.jobtrigger.app/healthz` returns `200 OK`.

### Mobile app identities (used by stores + RevenueCat)

- **iOS Bundle ID**: `Sraig.Lab-Trigger-frontend` (`PRODUCT_BUNDLE_IDENTIFIER` in `JobTrigger-Frontend/ios/Runner.xcodeproj`)
- **Android Package Name**: `com.sraig.jobtrigger` (application id in `JobTrigger-Frontend/android/app/build.gradle`)

### Backend production secrets

> None of these are committed. The crash-reporting and billing keys are merged
> at build time by `scripts/build-release.sh` from the git-ignored
> `JobTrigger-Frontend/config/sentry.json` and `config/billing.json`; the
> backend-only keys live only in the deployed backend environment.

```bash
NODE_ENV=production
PORT=5001
MONGODB_URI=mongodb+srv://...
JWT_SECRET=<strong-random-key>
CREDENTIALS_ENCRYPTION_KEY=<32-byte-hex-key>
CORS_ORIGINS=https://jobtrigger.app
FCM_SERVICE_ACCOUNT={"type":"service_account",...}
SMTP_HOST=...
SMTP_PORT=587
SMTP_USER=...
SMTP_PASS=...
# Crash reporting (E3): merged at build time from config/sentry.json
SENTRY_DSN=https://<key>@<host>/<project-id>
# Billing (Phase 20): off unless BILLING_ENABLED=true
BILLING_ENABLED=false
REVENUECAT_SECRET_API_KEY=appl_...
REVENUECAT_WEBHOOK_AUTH=<matching-secret-token>
```

---

## 2. Web Deployment (Vercel)

- **Platform**: Vercel
- **Root Directory**: `JobTrigger-Web`
- **Domain**: `https://jobtrigger.app`
- **Web version**: `1.0.0` (`JobTrigger-Web/package.json`)
- **Environment Variables**:
  ```bash
  JOBTRIGGER_BACKEND_URL=https://api.jobtrigger.app
  SESSION_SECRET=<32-byte-secret>
  SITE_URL=https://jobtrigger.app
  UMAMI_URL=...
  UMAMI_WEBSITE_ID=...
  # Web billing (P20-83): Paddle's public client-side token; the backend holds the
  # secret API key. Unset or mismatched → checkout off.
  PADDLE_CLIENT_TOKEN=live_...
  PADDLE_ENV=production
  # Crash reporting (E3): the website reads this exact name, in Vercel's dashboard.
  NEXT_PUBLIC_SENTRY_DSN=https://<key>@<host>/<project-id>
  ```
- **Token guides**: `docs/token-guides.md` — mirrors the in-app token wizards for Jenkins, GitHub and SonarQube.
- **Post-Deploy Check**: `https://jobtrigger.app/changelog` renders the v1.0 release entry cleanly.

---

## 3. Mobile Builds

### Android (Google Play)
- **Configuration**: `config/prod.json` plus the git-ignored
  `config/sentry.json` and `config/billing.json`, merged at build time
- **Signing**: Configured in `android/key.properties` pointing to `jobtrigger-upload-keystore.jks`
- **Command**:
  ```bash
  scripts/build-release.sh appbundle
  ```
- **Output**: `build/app/outputs/bundle/release/app-release.aab`
- **Track**: Upload to Google Play Console → **Internal Testing**.

### iOS (App Store / TestFlight)
- **Command**:
  ```bash
  scripts/build-release.sh ipa
  ```
- **Output**: `build/ios/archive/Runner.xcarchive` / `build/ios/ipa/JobTrigger.ipa`
- **Track**: Upload via Transporter to App Store Connect → **TestFlight**.
