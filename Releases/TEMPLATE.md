# Release Template

Use this template when starting a new release (e.g., `v1.1.0`, `v1.2.0`). Copy these files into `Releases/vX.Y.Z/`.

---

## 1. `release-notes.md`

```markdown
# Release Notes — vX.Y.Z

- **Release Version**: vX.Y.Z
- **Release Date**: YYYY-MM-DD
- **Target Branch**: main
- **Supported Tools Manifest**: (`release/tools.json`)

## What's Shipping
- **Summary**: High-level overview of the release.
- **New Capabilities**:
  - Feature 1
  - Feature 2
- **Bug Fixes & Refinements**:
  - Fix 1
  - Fix 2

## Breaking Changes & Deprecations
- None (or list details)

## Known Limitations & Scope
- List any excluded tools (e.g. GitLab CI / CircleCI planned for 1.3).
```

---

## 2. `pre-release-checklist.md`

```markdown
# Pre-Release Checklist — vX.Y.Z

- [ ] **1. Tool Manifest Synchronisation**:
  - `release/tools.json` up to date.
  - `node scripts/sync-tools.mjs --check` passes without drift.
- [ ] **2. Automated Test Gates**:
  - Frontend: `flutter analyze` clean.
  - Frontend: `flutter test` green.
  - Backend: `npm test` green.
  - Web: `npm test` / Vitest green.
- [ ] **3. Security & Dependency Checks**:
  - GitHub Actions security workflow green.
  - Sentry / GlitchTip event scrubbing verified.
- [ ] **4. Store Listings & Assets**:
  - App Store Connect screenshots (iPhone 6.9") ready.
  - Google Play screenshots (Android 2:1) ready.
  - Store text (title, subtitle, description) matches shipping tools.
  - Privacy manifests & Data safety declarations verified.
- [ ] **5. Manual Owner Sign-off**:
  - Device smoke test executed (`manually/`).
```

---

## 3. `deployment-log.md`

```markdown
# Deployment Log — vX.Y.Z

- **Release Version**: vX.Y.Z
- **Deploy Date**: YYYY-MM-DD
- **Commit SHA**: `<commit-sha>`

## Backend Deployment
- Host: `<host-provider>`
- Database: MongoDB Atlas
- Environment variable verification:
  - `NODE_ENV=production`
  - `JWT_SECRET` verified
  - `CREDENTIALS_ENCRYPTION_KEY` verified
  - `CORS_ORIGIN` set
- Status: Live / Healthcheck verified

## Web Deployment
- Platform: Vercel (`JobTrigger-Web`)
- Target Domain: `https://jobtrigger.app`
- Environment variable verification:
  - `JOBTRIGGER_BACKEND_URL` verified
  - `SESSION_SECRET` verified
- Status: Deployed

## Mobile Artifacts
- Android AAB: `flutter build appbundle --release --dart-define-from-file=config/prod.json`
- iOS IPA: `flutter build ipa --release --dart-define-from-file=config/prod.json`
- Play Console Track: Internal Testing / Production
- App Store Connect Track: TestFlight / App Store
```

---

## 4. `post-release.md`

```markdown
# Post-Release Verification & Monitoring — vX.Y.Z

- **Release Date**: YYYY-MM-DD
- **Monitoring Window**: 72-hour window

## Device Smoke Test
- [ ] Physical iPhone verification (Login, view servers, trigger build, watch).
- [ ] Physical Android verification (Login, view servers, trigger build, watch).

## Crash & Error Monitoring
- GlitchTip / Sentry Project: `jobtrigger-frontend` / `jobtrigger-backend`
- Crash-free user rate: Target > 99.5%
- Uncaught exceptions / issues observed: None.

## Hotfixes
- Hotfix branches spawned: None (or `hotfix/vX.Y.Z+1`).
```
