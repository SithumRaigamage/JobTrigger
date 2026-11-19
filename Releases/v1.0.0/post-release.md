# Post-Release Verification & Monitoring — v1.0.0

- **Version**: `1.0.0`
- **Release Date**: TBD (store review and production deployment pending)
- **Target Tracking Window**: 72 Hours Post-Launch

---

## 1. Production Smoke Tests

- [ ] **Onboarding & Sign-in**:
  - Test new account registration on production backend (`https://api.jobtrigger.app`).
  - Verify email verification / password reset flow via production SMTP.
  - Verify `GET https://api.jobtrigger.app/healthz` returns `200 OK` (the container health check; the app does not call it).
- [ ] **CI Server Connectivity**:
  - Jenkins: Connect live Jenkins server, verify CSRF crumb negotiation and job tree loading.
  - SonarQube: Connect SonarQube / SonarCloud server, inspect quality gates and issues.
  - GitHub Actions: Connect GitHub PAT, list repos and inspect workflow runs.
- [ ] **Push & Background Alerts**:
  - Verify background watch alerting on watched Jenkins/SonarQube builds.
- [ ] **"What's New" Sheet**:
  - Confirm `WhatsNewSheet` presents on initial app launch after update, and can be reopened from Profile.

---

## 2. Crash Reporting & Error Monitoring

- **Monitoring Service**: GlitchTip / Sentry
- **Target Projects**:
  - `jobtrigger-frontend`
  - `jobtrigger-backend`
  - `jobtrigger-web`
- **Thresholds**:
  - Crash-free user rate: `> 99.5%`
  - Scrubber verification: Ensure all tokens, passwords, and sensitive headers remain redacted in Sentry events.

---

## 3. Hotfix Tracking

| Incident / Ticket | Severity | Fix Commit | Hotfix Release |
|---|---|---|---|
| None recorded | — | — | — |
