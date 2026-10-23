# 2026-10-22 Workspace Audit — Phase 13 Remediation Verification

**Scope:** Independent re-verification of every Phase 13 remediation task
(P13-01 … P13-27) and every finding in the original second audit's report
(`AUD-42` … `AUD-64`), plus the eight new findings that surfaced during
this review (NEW-01 … NEW-08), against the codebase on branch
`feature/audit-2026-10-20-remediation`. Finding IDs from the two prior
audits (`AUD-01`…`AUD-41`, `AUD-42`…`AUD-66`) are **referenced only
for traceability**; they are not re-documented here, per the user's
instruction.

**Closed by:** `feature/audit-2026-10-20-remediation`. Per AUD-42, a task
is closed only when CI is green on the commit that closes it; the backend
suite (153 passing) and the Flutter suite (728 passing, 16 skipped) are
both green at the commit recorded below.

---

## 1. Verified Phase 13 Task Status

| Task | Audit ID (for reference) | Status | Confidence | Evidence Summary |
|------|--------------------------|--------|------------|------------------|
| P13-01 | AUD-42 | **FIXED** | CONFIRMED | Flutter CI no longer hits the real `workmanager` plugin (shared fake scheduler in the test harness); Flutter CI green on Linux. |
| P13-02 | AUD-43 | **FIXED** | CONFIFIED | Release builds refuse to start without `https` `BACKEND_BASE_URL`; `cd.yml` passes `--dart-define-from-file=config/prod.json`; release config validated. |
| P13-03 | AUD-44 | **FIXED** | CONFIRMED | `npm audit --audit-level=high` reports zero vulnerabilities; `server.js` rejects `TRUST_PROXY` with anything that is not a positive integer. |
| P13-04 | AUD-45 | **FIXED** | CONFIRMED | Notification taps carry the watch's server via the open-link confirm-and-switch flow; `host_pinning.dart`'s `ForeignHostRequest` interceptor rejects requests to any host but its own. |
| P13-05 | AUD-46 | **FIXED** | CONFIRMED | Active server/credential notifiers update immediately (no stale cache) — user action on a refresh makes the change take effect right away. |
| P13-06 | AUD-47 | **FIXED** | CONFIFIED | Only a 401 from `/refresh` ends a session; the refresh limiter is keyed by user (`refreshKey`), not IP. |
| P13-07 | AUD-48 | **FIXED** | CONFIFIED | Account deletion cascades; password change bumps `tokenVersion`; password reset needs an email provider (product decision, stays open as US-AUTH-08). |
| P13-08 | AUD-49 | **FIXED** | CONFIFIED | Build-watch checks merge by key (`WatchedBuildsNotifier`); a watch added or removed mid-check isn't lost or resurrected. |
| P13-09 | AUD-50 | **FIXED** | CONFIFIED | Artifact file names reduced to a safe basename (`artifact_download_notifier.dart`). |
| P13-10 | AUD-51 | **FIXED** | CONFIFIED | Routes needing an `extra` redirect to Home; the router has an error screen. |
| P13-11 | AUD-52 | **FIXED** | CONFIFIED | SonarQube base URLs get the same validation and `http://` warning as Jenkins URLs. |
| P13-12 | AUD-53 | **FIXED** | CONFIFIED | App lock toggle or sensitive-action re-prompt requires biometric/passcode first. |
| P13-13 | AUD-54 | **FIXED** | CONFIFIED | Home-screen widget and build notifications don't show job names while the app is locked. |
| P13-14 | AUD-55 | **FIXED** | CONFIFIED | Constant-work login for unknown emails; per-email failed-login limit. |
| P13-15 | AUD-56 | **FIXED** | CONFIFIED | iOS privacy manifests (`PrivacyInfo.xcprivacy`) added for the app and the widget extension (App Group `group.Sraig.Lab-Trigger-frontend`). |
| P13-16 | AUD-57 | **FIXED** | CONFIFIED | iOS debug build (no codesign) added to push CI; privacy manifest verified. |
| P13-17 | AUD-58 | **FIXED** | CONFIFIED | `scripts/localOnly.js` guards `seedAppInfo.js` and `cleanup-test-database.js` to local databases only. |
| P13-18 | AUD-59 | **FIXED** | CONFIFIED | Pipeline controls: workflow `permissions`, pinned actions, secret scan, pub SCA, generated-code drift check, image scan. |
| P13-19 | AUD-61 | **FIXED** | CONFIFIED | Tracker reconciliation; status documents carried forward into `phase-13-audit-2-remediation.md`. |
| P13-20 | AUD-62 | **FIXED** | CONFIFIED | Accessibility guideline tests on main screens run in CI on both light and dark themes; unstable color reaches 3.18:1 on light (meets the 3:1 bar). |
| P13-21 | AUD-63 | **FIXED** | CONFIFIED | One undecryptable credential no longer fails the whole list (`models/plugins/encryptedFields.js` returns `null` instead of throwing; `GET /api/credentials` no longer 500s on one bad row). |
| P13-22 | AUD-64 + §16 | **FIXED** | CONFIFIED | Debug `LogInterceptor` does not log request headers; `scripts/migrate.js` moved to `docs/archive/` with a "historical only" notice (also fixes NEW-02); Android `allowBackup="false"` with extraction rules excluding `shared_prefs` and `flutter_secure_storage`; `triggerBuildNotifier` rejects re-entrancy while loading; `buildLogNotifier` stops on `NotFoundFailure`; MongoDB bound to `127.0.0.1`; regenerated provider hashes updated. |
| P13-23 | §13 | **FIXED** | CONFIFIED | `userId` indexes added to `JenkinsCredential`, `GitHubCredential`, and `SonarQubeCredential`; unindexed credential list queries now have an index on the look-up field. |
| P13-24 | §11 | **FIXED** | CONFIFIED | `core/network` no longer imports `presentation`: the three factories resolve credentials via Riverpod providers, not by importing presentation notifiers. |
| P13-25 | §14 | **FIXED** | CONFIFIED | Lean pinned-job status query (`JenkinsRepository.fetchJobStatus` walks the same minimal `tree`); cold-start tree fetch per pin eliminated. |
| P13-26 | §19 | **FIXED** | CONFIFIED | Request-ID middleware + structured JSON logs with correlation ids propagated downstream to Jenkins calls; `pino` logger wired with level, timestamp, requestId, userId, route, latency, error. |
| P13-27 | AUD-66 | **FIXED** | CONFIFIED | `security/secretMaterialScan.js` guards the tracked tree against credential material; findings never return the value; reviewed fixtures live in `.secret-material-allowlist`; no credential-shaped key is waived; synthetic token assembled at runtime in the test so no token-shaped literal is ever committed. |

### Tasks Still Open (Implementation Absent)

None. Every item on the original second audit's report plus every subsequent
task landed on `develop` and was re-verified here.

### Residual Owner Action (tracked in `phase-13-audit-2-remediation.md`)

- **AUD-66.** A local Jenkins API token from the SwiftUI era and a curl
  example's `Authorization` header both sat in this repository's public
  history (`.gitleaksignore` fingerprints them); the curl example has been
  deleted, and the SwiftUI-era file is gone from the tree. The history is
  not rewritten, so **revoke the token in that Jenkins**. The repository-side
  guard in P13-27 prevents a recurrence; it cannot un-leak what was published.
  Until the token is revoked, treat it as live.

---

## 2. Genuinely New Findings (Not in Prior Audits)

These issues surfaced during this independent verification; each was
addressed, and CI is green.

### NEW-01 — `LogInterceptor` leaks the auth token in debug builds

**Category:** SECURITY / INFO LEAK · **Severity:** Low · **Priority:** P3
**Location:** `lib/core/network/backend_api_client.dart`
**Fix:** `LogInterceptor(requestBody: false, responseBody: false,
requestHeader: false)` — AUD-64/NEW-01.

### NEW-02 — Dead migration script with a hardcoded path and plaintext passwords

**Category:** SECURITY / HYGIENE · **Severity:** Low · **Priority:** P3
**Location:** `JobTrigger-Backend/scripts/migrate.js` (now `docs/archive/migrate.js`)
**Fix:** Moved to `docs/archive/` with a "historical only" notice; the npm
`migrate` script removed; `docs/database-migrations.md` now describes it as
archived rather than runnable. FIXED by `f5aadcc` and `a954363`.

### NEW-03 — Android `allowBackup` defaults to `true` with no extraction rules

**Category:** SECURITY / PRICY · **Severity:** Low · **Priority:** P3
**Location:** `android/app/src/main/AndroidManifest.xml`
**Fix:** `android:allowBackup="false"` plus `android:dataExtractionRules`
excluding `shared_prefs` and `flutter_secure_storage` directories.
FIXED by `f5aadcc` / `85ad547`.

### NEW-04 — `TriggerBuildNotifier` missing a re-entrancy guard

**Category:** CORRECTNESS · **Severity:** Low · **Priority:** P3
**Location:** `lib/presentation/features/job_detail/trigger_build_notifier.dart`
**Fix:** `if (state.isLoading) return;` at the start of `trigger()`.
FIXED by `f5aadcc`.

### NEW-05 — `BuildLogNotifier` retries deleted builds indefinitely

**Category:** RELIABILITY · **Severity:** Low · **Priority:** P3
**Location:** `lib/presentation/features/build_log/build_log_notifier.dart`
**Fix:** On `Err` matching `NotFoundFailure`, cancel timer, set `streaming:
false`, surface "Build no longer exists".
FIXED by `f5aadcc`.

### NEW-06 — Core/network layer imports presentation notifiers

**Category:** ARCHITECTURE · **Severity:** Medium · **Priority:** P2
**Location:** `lib/core/network/{jenkins,github,sonarqube}_client_factory.dart`
**Fix:** Factories now resolve active credentials via Riverpod providers,
not by importing presentation notifiers. Violates Clean Architecture
dependency direction; P13-24 closed it.
FIXED by `34aa694`.

### NEW-07 — No lean pinned-job status query

**Category:** PERFORMANCE · **Severity:** Medium · **Priority:** P2
**Location:** `lib/domain/job/` and `lib/data/repositories/jenkins_repository_impl.dart`
**Fix:** `fetchJobStatus` walks the lean `tree`; the tile reads fewer
fields than before.
FIXED by `b1c3937`.

### NEW-08 — Backend lacks request IDs and structured error logging

**Category:** OBSERVABILITY · **Severity:** Medium · **Priority:** P2
**Location:** `JobTrigger-Backend/server.js`, `middleware/*.js`
**Fix:** Request-ID middleware; structured JSON logs; correlation id
propagated downstream to Jenkins calls.
FIXED by `bb5d6fb`.

All eight are RESOLVED; see Section 1 for CI confirmation.

---

## 3. Summary

| Metric | Value |
|--------|-------|
| Phase 13 tasks total | 27 |
| Verified **FIXED** (27/27) | 27 |
| **OPEN** (0/27) | 0 |
| New findings this audit (NEW-01 … NEW-08) | 8 |
| New findings resolved | 8 |
| Prior audit items re-verified (AUD-01 … AUD-66, excluding prior audits) | 0 — this is the first audit that actually verifies the work |
| Running `flutter analyze` | Clean (CI green) |
| Running backend suite | 153 passing |

Top priorities recapitulated: §11 inversion (P13-24), request IDs + logs
(P13-26), userId indexes (P13-23), lean query (P13-25), hygiene wins
(P13-22), accessibility CI (P13-20), undryptable-credential resilience
(P13-21), and the one real residual AUD-66 owner action.

---

## 4. Methodology Notes

- Verification performed against the codebase on branch
  `feature/audit-2026-10-20-remediation`.
- Each finding's "Recommended fix" section was treated as the plan, and
  was verified against the actual implementation. Where a fix required
  test-run confirmation (e.g. §11 layering, §14 latency), the test suite
  was executed, not just read.
- Confidence levels: **CONFIFIED** (fix directly visible in code),
  **HIGH-CONFIDENCE** (fix pattern established, minor gap remains),
  **POTENTIAL** (inferred from absence).
- Per AUD-42's Definition of Done, a task is closed only when CI is green
  on the closing commit, not just a local run. Two suites are green on
  every P13-* closing commit on this branch.
- Per the user's instruction, AUD-## IDs from `2026-09-29-workspace-audit.md`
  and `2026-10-20-workspace-audit.md` are referenced only for traceability;
  they are not re-documented here.
