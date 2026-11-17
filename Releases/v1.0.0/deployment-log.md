# Deployment Log — v1.0.0

- **Version**: `1.0.0`
- **Date**: 2026-11-17
- **Base Commit SHA**: `9b87d10` (develop, 2026-11-17; re-confirm the
  tag commit when cutting the release)

> **Status: plan, not executed.** The values below are the intended
> production configuration. Nothing here has been deployed or stored yet;
> tick each step and replace placeholder secrets during the real
> deployment.

---

## 1. Backend Infrastructure (Render / Docker)

- **Target Host**: Render / Container Service
- **Build Target**: `JobTrigger-Backend/Dockerfile`
- **Production URL**: `https://api.jobtrigger.app`
- **Database**: MongoDB Atlas Production Cluster
- **Environment Verification**:
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
  ```
- **Verification**: `GET https://api.jobtrigger.app/healthz` returns `200 OK`.

---

## 2. Web Deployment (Vercel)

- **Platform**: Vercel
- **Root Directory**: `JobTrigger-Web`
- **Domain**: `https://jobtrigger.app`
- **Environment Variables**:
  ```bash
  JOBTRIGGER_BACKEND_URL=https://api.jobtrigger.app
  SESSION_SECRET=<32-byte-secret>
  SITE_URL=https://jobtrigger.app
  UMAMI_URL=...
  UMAMI_WEBSITE_ID=...
  ```
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
