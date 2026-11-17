# Release 1.0.0 Deployment Instructions

Follow these sequential instructions to deploy Release 1.0.0 across GitHub, the backend, the web portal, and Android.

---

## Phase 1 — GitHub Release (`v1.0.0`) *(First Priority)*

This tags the code, publishes the release notes, and bundles the release artifacts.

### 1. Ensure `main` / `develop` is clean and up to date
* Verify that `develop` passes all CI checks:
  * `.github/workflows/flutter-ci.yml`
  * `nodejs-test.yml`
  * `web-ci.yml`
  * `security.yml`
* Merge `develop` into `main` (if your release workflow tags off `main`).

### 2. Verify Version Bump
* **Flutter**: `JobTrigger-Frontend/pubspec.yaml` should have `version: 1.0.0+1` (or desired build number).
* **Web**: `JobTrigger-Web/package.json` should have `"version": "1.0.0"`.
* **Backend**: `JobTrigger-Backend/package.json` should have `"version": "1.0.0"`.

### 3. Create Git Tag
```bash
git tag -a v1.0.0 -m "Release 1.0.0: Jenkins, SonarQube, and GitHub Actions"
git push origin v1.0.0
```

### 4. Build & Attach Release Binaries (Manual or via `.github/workflows/cd.yml`)
Build unsigned/release standalone APK:
```bash
cd JobTrigger-Frontend
flutter build apk --release --dart-define-from-file=config/prod.json
```
*Resulting file*: `build/app/outputs/flutter-apk/app-release.apk`

### 5. Publish GitHub Release
Using GitHub CLI:
```bash
gh release create v1.0.0 \
  build/app/outputs/flutter-apk/app-release.apk#JobTrigger-v1.0.0.apk \
  --title "JobTrigger 1.0.0" \
  --notes-file Releases/v1.0.0/release-notes.md
```
Include the changelog summary:
* Jenkins + SonarQube + GitHub Actions in one app
* Per-watch notification rules (`all`, `failuresOnly`, `backToGreenOnly`, `mainBranchOnly`)
* Offline data age banners ("Updated Xm ago" / "Offline — showing data from HH:MM")
* Accessible shape & visible label status marks (`StatusMark`)
* Two-step safety production protection locks and read-only servers
* In-app token creation wizards and first-run onboarding checklist

---

## Phase 2 — Backend Deployment *(Required for Web & App)*

The app and web portal need the production API endpoint (`https://api.jobtrigger.app` per `config/prod.json`).

### 1. Production Server / Platform Selection
* Select your host (Railway, Render, Fly.io, DigitalOcean, or VPS).
* Dockerized deployment ready via `JobTrigger-Backend/Dockerfile`.

### 2. MongoDB Atlas Production Cluster
* Create a production database cluster (Atlas M0/M10).
* Whitelist backend outbound IPs (or `0.0.0.0/0` with strong authentication).
* Set `MONGODB_URI=mongodb+srv://...` in production environment variables.

### 3. Environment Variables
* `NODE_ENV=production`
* `PORT=5001` (or host assigned)
* `JWT_SECRET` (generate strong 32+ character random secret)
* `CREDENTIALS_ENCRYPTION_KEY` (AES-256 key for sensitive tokens)
* `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM` (transactional email for password resets & student verification)
* `CORS_ORIGIN=https://jobtrigger.app`
* `FCM_SERVICE_ACCOUNT` (JSON string of Firebase service account for push notifications)

### 4. Health & Smoke Test
* Check `GET /health` returns `200 OK`.
* Confirm HTTPS certificate is active (via Cloudflare or Let's Encrypt).

---

## Phase 3 — Web Deployment *(Vercel)*

Deploys the marketing website, user portal, and changelog.

### 1. Connect Repository to Vercel
* Root directory: `JobTrigger-Web`
* Framework preset: `Next.js`

### 2. Configure Environment Variables in Vercel
* `JOBTRIGGER_BACKEND_URL`: `https://api.jobtrigger.app`
* `SESSION_SECRET`: (strong 32-byte secret for iron-session)
* `NEXT_PUBLIC_UMAMI_WEBSITE_ID`: (if tracking analytics)
* `SENTRY_DSN`: (optional GlitchTip/Sentry DSN for web error logging)

### 3. Verify Domain & Links
* Point DNS for `jobtrigger.app` and `www.jobtrigger.app` to Vercel CNAME/A records.
* Verify `https://jobtrigger.app/changelog` displays the new released v1.0 entry.

---

## Phase 4 — Android Deployment *(Google Play Console)*

### 1. Google Play Console Account & App Creation
* Google Play Console developer account ($25 one-time registration).
* Create new app: **JobTrigger** (Default language: English).

### 2. Release Keystore (`upload-keystore.jks`)
Generate upload key:
```bash
keytool -genkey -v -keystore ~/jobtrigger-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Create `JobTrigger-Frontend/android/key.properties` (git-ignored):
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/path/to/jobtrigger-upload-keystore.jks
```

### 3. Build the Production App Bundle (`.aab`)
```bash
cd JobTrigger-Frontend
flutter build appbundle --release --dart-define-from-file=config/prod.json
```
*(Artifact generated at: `build/app/outputs/bundle/release/app-release.aab`)*

### 4. Store Listing Assets
* **App Icon**: 512×512 PNG (ready from Phase 16).
* **Feature Graphic**: 1024×500 JPEG/PNG.
* **Phone Screenshots**: Prepared in `release/store-screenshots/android-2by1/` (7 images, 1080×2160, no alpha).
* **Short description (80 chars)**: `Jenkins, GitHub Actions and SonarQube builds, on your phone.`
* **Full description**: Ready in `tasks/release-checklist.md`.

### 5. App Content & Data Safety Declarations
* **Privacy policy URL**: `https://jobtrigger.app/privacy`
* **Target audience**: 18+ (developer tool)
* **Data safety answers**: Declared in `tasks/release-checklist.md §Google Play Data safety` (Email address, User IDs, Crash logs, Diagnostics; no third-party data sharing; encrypted in transit).

### 6. Initial Upload
* Create release on the **Internal testing** track first.
* Upload `app-release.aab`.
* Validate installation on a test Android device before submitting to Production/Open testing.
