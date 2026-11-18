# Pre-Release Checklist — v1.0.0

- **Target Version**: `1.0.0`
- **Target Branch**: `main`
- **Sign-off Date**: 2026-11-17

---

## 1. Automated Test & Code Quality Gates

- [x] **Tools Manifest Synchronization**:
  - `release/tools.json` verified (`release: "1.0"`, Jenkins 1.0, SonarQube 1.0, GitHub Actions 1.0).
  - Run check: `node scripts/sync-tools.mjs --check` passes cleanly across Frontend, Web, and Backend.
- [x] **Frontend Unit & Widget Tests**:
  - All 1,718 Flutter tests passing, 29 skipped (`JobTrigger-Frontend/test/`,
    re-run 2026-11-18; P24-05 added the shared-header widget tests and the
    support pull-to-refresh added one more).
- [x] **Backend Tests**:
  - Node test suite passing (`npm test` in `JobTrigger-Backend`).
- [x] **Web Tests**:
  - Vitest test suite passing (63 test files, 467 tests in `JobTrigger-Web`).
- [x] **Security Workflows**:
  - `security.yml` dependency and secret scanning verified (`gitleaks`, OSV advisories).

---

## 2. Store Assets & Submissions Readiness

- [x] **App Icons & Branding**:
  - Generated app icons in place (`release/store-screenshots/`, `scripts/export-icons.sh`).
- [x] **Store Screenshots (iOS)**:
  - 7 alpha-free JPEGs (1320×2868, iPhone 6.9") in `release/store-screenshots/ios-6.9/`.
- [x] **Store Screenshots (Android)**:
  - 7 alpha-free JPEGs (1080×2160, 2:1 ratio) in `release/store-screenshots/android-2by1/`.
- [x] **Store Copy (Google Play & App Store)**:
  - Short description (80 chars): `Jenkins, GitHub Actions and SonarQube builds, on your phone.`
  - Full description: Prepared in `tasks/release-checklist.md`.
  - Zero mentions of GitLab CI or CircleCI in listing keywords or descriptions.
- [x] **Privacy & Data Safety Disclosures**:
  - iOS Privacy manifest: `ios/Runner/PrivacyInfo.xcprivacy` verified (User Defaults reasons CA92.1/1C8F.1, FileTimestamp C617.1, SystemBootTime 35F9.1).
  - Play Data Safety answers aligned with `tasks/release-checklist.md`.

---

## 3. Manual Owner Verifications (`manually/`)

- [ ] **M-01 Physical iPhone Relaunch**: Kill and relaunch on physical iPhone.
- [ ] **M-07 Crash Reporting**: Confirm test crash reporting to GlitchTip over production DSN.
- [ ] **M-08 & M-09 Store Accounts**: Active Apple Developer ($99/yr) & Google Play Console ($25).
- [ ] **M-12 Final Review Sign-off**: Review notes and test credentials supplied to App Store Review.
