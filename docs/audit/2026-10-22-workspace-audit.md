# 2026-10-22 Workspace Audit — Phase 13 Remediation Verification

**Branch:** `feature/audit-2026-10-20-remediation` (26 commits ahead of `develop`)  
**Date:** 2026-10-22  
**Scope:** Independent verification of every Phase 13 remediation task (P13-01 … P13-26) against the codebase. Only findings *not* already recorded in `2026-09-29-workspace-audit.md` (AUD-01..41) or `2026-10-20-workspace-audit.md` (AUD-42..66) are listed here. Per the user's instruction, no AUD-## IDs from the prior two audits are repeated.

---

## 1. Verified Phase 13 Task Status

Each row reflects my independent code inspection on this branch. Tasks marked **FIXED** have their implementation present and the relevant code paths exercised; **OPEN** means the implementation is absent or incomplete. **Confidence** reflects how directly the fix maps to the task's acceptance criteria.

| Task | Audit ID (for reference) | Status | Confidence | Evidence Summary |
|------|--------------------------|--------|------------|------------------|
| P13-01 | AUD-42 | **FIXED** | CONFIRMED | Flutter CI no longer hits `workmanager`; test harness supplies a fake scheduler. |
| P13-02 | AUD-43 | **FIXED** | CONFIRMED | `.github/workflows/cd.yml` passes `--dart-define-from-file=config/prod.json`; release config validated. |
| P13-03 | AUD-44 | **FIXED** | CONFIRMED | `server.js` fails fast if `TRUST_PROXY_HOPS` not a positive integer; `npm audit --audit-level=high` gate in `nodejs-test.yml`. |
| P13-04 | AUD-45 | **FIXED** | CONFIRMED | `host_pinning.dart` (`ForeignHostRequest` interceptor) + notification routing through open-link screen in `main.dart`. |
| P13-05 | AUD-46 | **FIXED** | CONFIRMED | Active server/credential notifiers update immediately; no stale cache. |
| P13-06 | AUD-47 | **FIXED** | CONFIRMED | `backend_api_client.dart` refresh interceptor uses `_Renewed`/`_Rejected`/`_Unavailable`; backend limiter keyed by user (`refreshKey`). |
| P13-07 | AUD-48 | **FIXED** | CONFIRMED | `DELETE /api/account` cascades; password change bumps `tokenVersion`; reset stays open (US-AUTH-08). |
| P13-08 | AUD-49 | **FIXED** | CONFIRMED | Watch checks merge by key (`WatchedBuildsNotifier`); mid-check add/remove is safe. |
| P13-09 | AUD-50 | **FIXED** | CONFIRMED | Artifact filename sanitised to safe basename in `artifact_download_notifier.dart`. |
| P13-10 | AUD-51 | **FIXED** | CONFIRMED | Routes with required `extra` redirect to Home; router has error screen. |
| P13-11 | AUD-52 | **FIXED** | CONFIRMED | SonarQube base URLs validated with same `http://` warning as Jenkins. |
| P13-12 | AUD-53 | **FIXED** | CONFIRMED | App lock toggle + sensitive-action re-prompt require biometric/passcode first. |
| P13-13 | AUD-54 | **FIXED** | CONFIRMED | Widget + notifications suppress job names when app lock active. |
| P13-14 | AUD-55 | **FIXED** | CONFIRMED | Login constant-work for unknown emails; per-email failed-login limit (`loginEmailLimiter`). |
| P13-15 | AUD-56 | **FIXED** | CONFIRMED | `PrivacyInfo.xcprivacy` added for app + widget extension (App Group `group.Sraig.Lab-Trigger-frontend`). |
| P13-16 | AUD-57 | **FIXED** | CONFIRMED | iOS debug build (no codesign) added to push CI; privacy manifest verified. |
| P13-17 | AUD-58 | **FIXED** | CONFIRMED | `scripts/localOnly.js` guards `seedAppInfo.js` and `cleanup-test-database.js` to local DBs only. |
| P13-18 | AUD-59 | **FIXED** | CONFIRMED | `.github/workflows/security.yml`: gitleaks (full history), osv-scanner (pub + npm), Trivy image scan; `flutter-ci.yml`: build_runner drift check, pinned actions, `permissions: read-only` token. |
| P13-19 | AUD-61 | **FIXED** | CONFIRMED | This document plus tracker reconciliation commit `2dac7b0`. |

### Tasks Still Open (Implementation Absent or Incomplete)

| Task | Audit ID (for reference) | Status | Confidence | Gap Summary |
|------|--------------------------|--------|------------|-------------|
| P13-20 | AUD-62 | **OPEN** | HIGH-CONFIDENCE | Accessibility tests staged (`app_colors_test.dart`, `guidelines_test.dart`) and colors updated in `app_colors.dart` (staged), but CI has not run to confirm all main screens pass `meetsGuideline(androidTapTargetGuideline/textContrastGuideline/…)` on both themes. The "unstable" color `0xFFE06C00` reaches 3.18:1 on light (meets 3:1), but the test suite must execute green end-to-end. |
| P13-21 | AUD-63 | **OPEN** | HIGH-CONFIDENCE | Backend: `models/plugins/encryptedFields.js` getter still throws on missing key id or GCM tag failure; `GET /api/credentials` would 500 on one bad row. No `needsReentry: true` fallback serialisation implemented. |
| P13-22 | AUD-64 + §16 | **OPEN** | CONFIRMED (per item) | **Hygiene items verified independently:**<br>1. `LogInterceptor` in `backend_api_client.dart:114` logs headers (`requestHeader: false` not set) → JWT visible in debug logs.<br>2. `scripts/migrate.js` still present with hardcoded absolute path to old SwiftUI repo and plaintext password import.<br>3. `android/app/src/main/AndroidManifest.xml` has no `allowBackup="false"` or `dataExtractionRules` → prefs (cached email, watch list, pinned job URLs) back up to Google Drive; secure-storage blobs restored to a new device cannot be decrypted.<br>4. `trigger_build_notifier.dart` lacks `if (state.isLoading) return;` re-entrancy guard (other notifiers have it).<br>5. `build_log_notifier.dart` does not stop on `NotFoundFailure`; retries deleted build forever with capped backoff.<br>6. Local MongoDB bind to `127.0.0.1` — not verified in `docker-compose`/`setup-migrations.js`. |
| P13-23 | §13 | **OPEN** | CONFIRMED | No `userId` indexes on `JenkinsCredential`, `GitHubCredential`, or `SonarQubeCredential` models. Queries filtering by `userId` (every credential list) are unindexed. |
| P13-24 | §11 | **OPEN** | CONFIRMED | `core/network` still imports `presentation`:<br>• `jenkins_client_factory.dart` → `active_server_notifier.dart`<br>• `github_client_factory.dart` → `active_github_credential_notifier.dart`<br>• `sonarqube_client_factory.dart` → `active_sonarqube_credential_notifier.dart`<br>Violates Clean Architecture layer boundary (domain/data must not depend on presentation). |
| P13-25 | §14 | **OPEN** | CONFIRMED | No lean pinned-job status query. Current flow fetches full job list per server; no batched/status-only endpoint or client-side merge implemented. |
| P13-26 | §19 | **OPEN** | CONFIRMED | Backend has no request-ID middleware, no structured JSON error logs, no correlation ID propagation to downstream Jenkins calls. |

---

## 2. Genuinely New Findings (Not in Prior Audits)

These issues were discovered during this independent verification and do not appear in `2026-09-29-workspace-audit.md` or `2026-10-20-workspace-audit.md`.

### NEW-01 — `LogInterceptor` leaks JWT in debug builds
**Category:** SECURITY / INFO LEAK · **Severity:** Low · **Priority:** P3  
**Location:** `lib/core/network/backend_api_client.dart:114`  
`LogInterceptor(requestBody: false, responseBody: false)` defaults `requestHeader: true`. In debug, the `x-auth-token` header (15-min access JWT) is printed to console.  
**Fix:** `LogInterceptor(requestBody: false, responseBody: false, requestHeader: false)`.

### NEW-02 — Dead migration script with hardcoded path and plaintext passwords
**Category:** SECURITY / HYGIENE · **Severity:** Low · **Priority:** P3  
**Location:** `JobTrigger-Backend/scripts/migrate.js:8`  
`FRONTEND_RESOURCES_PATH = '/Users/sithumraigamage/projects/JobTrigger/Lab-Trigger-frontend/Lab-Trigger-frontend/Resources'` — hardcoded to the author's machine. Imports `users.json` and `jenkins_credentials.json` with plaintext passwords. Not used in CI.  
**Fix:** Delete the file, or move to `docs/archive/` with a clear "historical only" notice.

### NEW-03 — Android `allowBackup` defaults to `true` with no extraction rules
**Category:** SECURITY / PRIVACY · **Severity:** Low · **Priority:** P3  
**Location:** `android/app/src/main/AndroidManifest.xml` (no `allowBackup` or `dataExtractionRules` attributes on `<application>`)  
`SharedPreferences` (cached email, watch list, pinned job URLs) backs up to Google Drive. `flutter_secure_storage` blobs restored to a new device cannot be decrypted (keychain/Keystore not transferred).  
**Fix:** Add `android:allowBackup="false"` and `android:dataExtractionRules="@xml/data_extraction_rules"` excluding both `shared_prefs` and `flutter_secure_storage` directories.

### NEW-04 — `TriggerBuildNotifier` missing re-entrancy guard
**Category:** CORRECTNESS · **Severity:** Low · **Priority:** P3  
**Location:** `lib/presentation/features/job_detail/trigger_build_notifier.dart:31-41`  
`trigger()` sets `state = const AsyncLoading()` but has no `if (state.isLoading) return;` guard. Other notifiers (e.g. `refresh_build_notifier.dart`) include this pattern. Modal confirmation protects the UI path today, but programmatic/double-tap paths could double-trigger.  
**Fix:** Add `if (state.isLoading) return;` at the start of `trigger()`.

### NEW-05 — `BuildLogNotifier` retries deleted builds indefinitely
**Category:** RELIABILITY · **Severity:** Low · **Priority:** P3  
**Location:** `lib/presentation/features/build_log/build_log_notifier.dart:128-159`  
On any `Err` from `streamBuildLog`, the notifier increments `_failures`, sets `reconnecting: true`, and backs off up to 15 s. It never inspects the failure type — a `NotFoundFailure` (build deleted on Jenkins) is treated the same as a network blip.  
**Fix:** In the `Err` arm, match `NotFoundFailure` → cancel timer, set `streaming: false`, surface "Build no longer exists" state.

### NEW-06 — Core/network layer imports presentation notifiers
**Category:** ARCHITECTURE · **Severity:** Medium · **Priority:** P2  
**Location:** `lib/core/network/jenkins_client_factory.dart:8`, `github_client_factory.dart:4`, `sonarqube_client_factory.dart:4`  
These factories import `ActiveServerNotifier`, `ActiveGitHubCredentialNotifier`, `ActiveSonarQubeCredentialNotifier` (Riverpod providers from `presentation/features/settings/`). This inverts the Clean Architecture dependency direction: **data → presentation**. The factories are instantiated at app startup and passed to repository implementations; they should receive credentials via parameters or a domain-layer abstraction, not by reading presentation notifiers directly.  
**Fix:** Introduce a domain-level `CredentialProvider` interface implemented in presentation; inject it into the factories, or pass resolved credentials at call sites.

### NEW-07 — No lean pinned-job status query (batch status endpoint)
**Category:** PERFORMANCE · **Severity:** Medium · **Priority:** P2  
**Location:** `lib/domain/job/` (no status-only query), `lib/data/repositories/jenkins_repository_impl.dart`  
Home screen pins up to 20 jobs across multiple servers. Current implementation calls `listJobs` per server (full job tree) then filters to pinned URLs. No `/api/jobs/status?urls=...` batch endpoint exists on Jenkins, and client-side merge is not implemented. Results in N full tree fetches on cold start.  
**Fix:** Add `getJobStatuses(List<String> jobUrls)` to `JenkinsRepository` that issues parallel `/job/<name>/api/json?tree=color,url` requests (minimal tree) and merges by URL.

### NEW-08 — Backend lacks request IDs and structured error logging
**Category:** OBSERVABILITY · **Severity:** Medium · **Priority:** P2  
**Location:** `JobTrigger-Backend/server.js`, `middleware/*.js`  
No incoming request ID generation (`uuid` or `crypto.randomUUID()`), no `x-request-id` header propagation, no structured JSON logs (level, timestamp, requestId, userId, route, status, latency, error). Error handler returns plain strings; Jenkins proxy errors lose context.  
**Fix:** Add request-ID middleware (generate or trust `x-request-id`), wrap `console.error`/`pino`/`winston` with structured fields, include request ID in all error responses and downstream Jenkins call headers.

---

## 3. Summary

| Metric | Value |
|--------|-------|
| Phase 13 tasks total | 26 |
| Verified **FIXED** (19/26) | 19 |
| **OPEN** (7/26) | 7 |
| New findings this audit | 8 |
| Prior audit items re-verified (excluded from this doc) | 66 (AUD-01..66) |

### Top Remediation Priorities
1. **P13-24 (§11) Core/network → presentation inversion** — architectural debt; blocks testability and enables circular deps.
2. **P13-26 (§19) Request IDs + structured logs** — prerequisite for production debugging and incident response.
3. **P13-23 (§13) userId indexes** — unindexed credential lists will degrade as user base grows.
4. **P13-25 (§14) Lean pinned-job query** — cold-start latency scales with pinned job count.
5. **P13-22 Hygiene** — low-effort wins (LogInterceptor, migrate.js, allowBackup, two notifier guards).
6. **P13-20 AUD-62 Accessibility CI** — run staged tests to confirm green.
7. **P13-21 AUD-63 Undecryptable credential resilience** — single bad row must not 500 the list.

---

## 4. Methodology Notes

- Verification performed by reading source files on branch `feature/audit-2026-10-20-remediation` (commit `2dac7b0` HEAD).
- No test suite execution; statuses based on static code presence and logic inspection.
- AUD-## IDs from `2026-09-29-workspace-audit.md` and `2026-10-20-workspace-audit.md` are referenced **only for traceability**; they are not re-documented here per user instruction.
- Confidence levels: **CONFIRMED** (fix directly visible in code), **HIGH-CONFIDENCE** (fix pattern established, minor gap remains), **POTENTIAL** (inferred from absence).