# Workspace Audit — 2026-10-20

A second full-lifecycle audit of the `flutter-migration` branch at
`3eaf15a`. It covers `JobTrigger-Frontend/` (Flutter), `JobTrigger-Backend/`
(Node/Express/MongoDB), CI/CD, native platform configuration, and the
documentation and task tracker.

It builds on [`2026-09-29-workspace-audit.md`](2026-09-29-workspace-audit.md)
(AUD-01 to AUD-41, all marked fixed) and does two things:

1. **Re-verifies** the fixed claims in the code as it stands today.
2. **Audits what changed since**: the 50 commits after `57af2a2`, mostly
   Phase 11 (notifications, background work, app lock, home widget,
   offline cache, deep links) and the Phase 12 backend work (encryption at
   rest, refresh tokens).

New findings continue the registry at **AUD-42**. Use the same conventions
as the first audit (stable id, status column, backend-track items need
per-item approval under `CLAUDE.md` §7 and NFR-SEC-05).

`.env` and `.env.example` were not opened (`CLAUDE.md` §8). The
git-ignore rules and the Docker build context were checked instead.

## Remediation status

Tasks are in [`tasks/phase-13-audit-2-remediation.md`](../../tasks/phase-13-audit-2-remediation.md).
A finding is `fixed` once its commit is on the branch and CI is green on it.

| Id | Task | Status |
|---|---|---|
| AUD-42 | P13-01 | fixed |
| AUD-43 | P13-02 | fixed |
| AUD-44 | P13-03 | fixed |
| AUD-45 | P13-04 | fixed |
| AUD-46 | P13-05 | fixed |
| AUD-47 | P13-06 | fixed |
| AUD-48 | P13-07 | fixed (delete account, change password); reset stays open as US-AUTH-08, pending an email provider |
| AUD-49 | P13-08 | fixed |
| AUD-50 | P13-09 | fixed |
| AUD-51 | P13-10 | fixed |
| AUD-52 | P13-11 | fixed |
| AUD-53 | P13-12 | fixed |
| AUD-54 | P13-13 | fixed |
| AUD-55 | P13-14 | open |
| AUD-56 | P13-15 | open |
| AUD-57 | P13-16 | open |
| AUD-58 | P13-17 | open |
| AUD-59 | P13-18 | open |
| AUD-60 | — | fixed (index only, 2026-10-20; no commit) |
| AUD-61 | P13-19 | open |
| AUD-62 | P13-20 | open |
| AUD-63 | P13-21 | open |
| AUD-64 | P13-22 | open |
| AUD-65 | P13-07 | fixed (found during P13-07) |
| §13 indexes | P13-23 | open |
| §11 layering | P13-24 | open |
| §14 pin status | P13-25 | open |
| §19 request ids | P13-26 | open |

---

## 1. Executive summary

**Overall:** a well-engineered codebase with unusually good internal
documentation, layering discipline, and test volume (639 Flutter tests, 16
skipped fixture suites, 17 backend suites). Most of the first audit's
fixes hold up under re-inspection. The biggest risks now are **process and
release risks**, not code-quality risks. A few correctness and security
defects were introduced by the Phase 11 features.

**Major strengths**

- A consistent `Result`/`AppFailure` boundary. `guardRequest` makes the
  data layer impossible to escape (AUD-11 holds).
- The backend hardening is real and tested. Field-level AES-256-GCM with
  key ids and AAD runs on both `save` and `findOneAndUpdate`. Queries are
  scoped by owner, filters are sanitized, there is a central error handler,
  and refresh tokens carry `tokenVersion`.
- The deep-link resolver (`resolveJenkinsLink`) is a model of defensive
  design: it only contacts saved servers, refuses credentials in URLs, and
  confirms before switching servers.
- Secrets stay where they belong: tokens in secure storage, no password in
  prefs (AUD-01 holds), and logs, artifacts and the widget hold no
  credentials.

**Major weaknesses and biggest risks**

1. **CI has been red for 19 consecutive pushes** (since P11-24 on
   2026-09-30). Every Phase 12 "fixed" status was verified only on a
   developer Mac. Nothing stops a failing build from landing (AUD-42).
2. **Release builds point at `http://127.0.0.1:5001`.** Neither the CD
   workflow nor the documented store-build commands pass the prod config,
   and nothing fails loudly (AUD-43).
3. **Cross-server credential leak.** Tapping a build notification for
   server B while server A is active sends server A's Basic Auth to server
   B (AUD-45).
4. **Stale credentials after editing the active server.** This breaks the
   app's own "switch to an API token" flow (AUD-46).
5. **Sessions are wiped on any refresh failure.** Combined with a per-IP
   refresh limit, an office behind one NAT can be signed out en masse
   (AUD-47).
6. **Store-policy blockers.** There is no in-app account deletion (AUD-48)
   and no iOS privacy manifest despite a first-party required-reason API
   (AUD-56).
7. **A new critical dependency advisory** (`proxy-addr`) sits on exactly
   the code path the rate limiter depends on (AUD-44).

**Production readiness:** **DEVELOPMENT READY.** Fixture-verified feature
work is solid, but the release configuration, CI gate, store compliance
and the session-reliability items must be closed before even a TestFlight
or Play internal-track build is meaningful. See §23.

**Most important actions:** see §24. In short: fix and protect CI, make
release builds fail without prod config, fix the three cross-cutting state
bugs (AUD-45/46/47), run `npm audit fix`, and add account deletion.

---

## 2. Project understanding

| Aspect | Finding |
|---|---|
| Purpose | Trigger, monitor and inspect CI builds from a phone. Jenkins is complete; GitHub Actions is partial (P8, 11 of 28); SonarQube is credentials only (P10, 6 of 16). |
| Users | DevOps and release engineers, often on corporate networks and VPNs, frequently with several Jenkins servers (prod, staging, client instances). |
| Critical workflows | Log in → choose a server → browse the tree → trigger (with parameters) → watch status and log → cancel or approve input. Secondary: history, artifacts, notifications, widget, deep links. |
| Architecture | Flutter feature-first Clean Architecture (presentation, domain, data) with Riverpod 3 code-gen, go_router and Dio. The phone talks to Jenkins, GitHub and SonarQube **directly**. The Node backend only stores accounts and encrypted tool credentials. |
| Backend | Express 5, Mongoose 9, JWT (15-minute access token, 30-day refresh, `tokenVersion`), helmet, express-rate-limit, AES-256-GCM field encryption. Docker on `node:22-alpine` as a non-root user. |
| Platforms | iOS (plus a WidgetKit extension and App Group), Android (plus an AppWidget), and macOS (local development target only). |
| Deployment | None yet. No backend host, no store accounts, and `cd.yml` is manual build-verification only. |
| Maturity | Feature-rich, heavily documented, pre-release. A first audit has been remediated, and the release checklist is blocked on external items. |

---

## 3. Critical findings

| ID | Category | Issue | Severity | Confidence | Priority |
|---|---|---|---|---|---|
| AUD-42 | DEVOPS / TESTING | Flutter CI red for 19 pushes; a test leaks a real `workmanager` process on Linux | High | CONFIRMED | P0 |
| AUD-43 | CONFIGURATION / RELEASE | Release builds default to `http://127.0.0.1:5001`; prod config never applied | High | CONFIRMED | P0 |
| AUD-44 | SECURITY (dependency) | `proxy-addr` critical advisory (IP spoofing) under `trust proxy` and rate limiting | High | CONFIRMED | P0 |
| AUD-45 | SECURITY | Notification tap sends the active server's Basic Auth to another server's host | High | HIGH-CONFIDENCE | P1 |
| AUD-46 | BUG | Editing the active server keeps the stale URL and secret until restart | High | HIGH-CONFIDENCE | P1 |
| AUD-47 | RELIABILITY / SECURITY | Any refresh failure (429, 5xx, timeout) wipes the session; per-IP refresh limit punishes shared NAT | High | HIGH-CONFIDENCE | P1 |
| AUD-48 | PRODUCT / COMPLIANCE | No account deletion, password change or reset (App Store 5.1.1(v), Play data-deletion policy) | High | CONFIRMED | P1 |
| AUD-56 | RELEASE / COMPLIANCE | No `PrivacyInfo.xcprivacy`; the widget extension uses `UserDefaults` (a required-reason API) | Medium | CONFIRMED | P1 |
| AUD-60 | HYGIENE | The staged index blanks `macos/Flutter/GeneratedPluginRegistrant.swift` | Low | CONFIRMED | P1 (trivial) |

---

## 4. Complete findings

### AUD-42 — Flutter CI has failed on every push since P11-24

**Category:** DEVOPS / TESTING · **Severity:** High · **Priority:** P0 · **Confidence:** CONFIRMED
**Location:** `.github/workflows/flutter-ci.yml`; `test/presentation/features/job_detail/job_detail_confirmation_test.dart` ("shows last success/failure links only when they differ (US-JX-05)")
**Affected component:** CI gate, release process

#### Problem
`gh run list --branch flutter-migration` shows **Flutter CI failing on 19
consecutive pushes** from `4c26f44` (P11-24, 2026-09-30 13:24) to HEAD.
Every Phase 12 remediation commit is among them. The run log reports
`638 tests passed, 1 failed, 16 skipped`. The failure is `A Timer is still
pending even after the widget tree was disposed`. The stack goes from
`BuildWatchNotifier._load` to `BackgroundWatchScheduler.sync` to
`Workmanager.cancelByUniqueName` to `workmanager_linux`, which shells out
with `Process.run`.

#### Evidence
- Local `flutter test` on macOS: 639 passed (the macOS plugin throws
  immediately, so no timer is left behind).
- CI on `ubuntu-latest`: 1 failed. `build-android` passes.
- `docs/audit/2026-09-29-workspace-audit.md` and `tasks/README.md` mark
  Phase 12 "done", and the baseline table there still says
  `flutter test | 371 passed`.

#### Why it matters
The gate exists but isn't respected. Twenty commits, including security
fixes, merged with no green CI run. A real regression in that window would
have been indistinguishable from this known failure. It also suggests
there is no branch protection requiring the check.

#### Root cause
1. The test (and `MyApp`, which watches `buildWatchNotifierProvider`)
   doesn't override `backgroundWatchSchedulerProvider`, so the real
   platform plugin runs in tests.
2. A platform-dependent test passed on the developer's OS, and verification
   was local only.

#### Recommended fix
1. Override `backgroundWatchSchedulerProvider` with a no-op fake in the
   shared test harness (`test/support/`) for every widget test that pumps
   `MyApp` or a `ProviderScope` that reaches it.
2. Enable branch protection on `flutter-migration` and `develop` requiring
   both CI workflows.
3. Add "CI green on the commit" to the definition of done in
   `tasks/README.md`, and require a CI run link when a task or audit item is
   marked fixed.

#### Verification
CI is green on a push. Run `flutter test` in a Linux container locally
(`docker run ghcr.io/cirruslabs/flutter:3.44.9`).

#### Regression test
Add a test-harness assertion that fails if any test instantiates the real
`BackgroundWatchScheduler`, for example a `debugAssertNoRealScheduler`
flag.

---

### AUD-43 — Release builds point at the local dev backend over HTTP

**Category:** CONFIGURATION / RELEASE · **Severity:** High · **Priority:** P0 · **Confidence:** CONFIRMED
**Location:** `lib/core/config/app_config.dart:13-29`; `.github/workflows/cd.yml:32,37`; `docs/deployment.md` ("The mechanical deploy process")
**Affected component:** every backend call in every release build

#### Problem
`AppConfig.fromEnvironment()` defaults `BACKEND_BASE_URL` to
`http://127.0.0.1:5001` and `ENVIRONMENT` to `dev`. The only place prod
values exist is `config/prod.json`, consumed via
`--dart-define-from-file`. But:

- `cd.yml` runs `flutter build apk --release` and `flutter build ipa
  --release --no-codesign` **without** that flag.
- `docs/deployment.md` documents `flutter build appbundle --release` and
  `flutter build ipa --release`, also without it.
- `AppConfig.environment` is read nowhere (searching for
  `AppEnvironment.prod` finds nothing), so nothing can assert on it.

#### Why it matters
Following the documented release steps produces a store build whose login
calls `127.0.0.1` over cleartext HTTP. On a phone that is either a
connection error or, worse, whatever happens to be listening on the device.
It fails silently until a tester tries to log in.

#### Recommended fix
- Make release builds fail without config. In `AppConfig.fromEnvironment`,
  when `kReleaseMode` is true and `BACKEND_BASE_URL` is missing or not
  `https://`, throw at startup (or use `bool.hasEnvironment`).
- Add `--dart-define-from-file=config/prod.json` to `cd.yml` and to every
  build command in `docs/deployment.md`.
- Optionally, show the environment name on the App Info screen in non-prod
  builds.

#### Verification
A `flutter build apk --release` without the flag fails. With
`prod.json`, App Info shows the prod environment.

#### Regression test
A unit test of an `AppConfig.validateForRelease()` helper covering the
missing, `http://` and `https://` cases. Add a CI step that greps the
`cd.yml` build commands for `dart-define-from-file`.

---

### AUD-44 — `proxy-addr` critical advisory on the rate-limit path (backend track)

**Category:** SECURITY / DEPENDENCY · **Severity:** High (npm rates it Critical) · **Priority:** P0 · **Confidence:** CONFIRMED
**Location:** `JobTrigger-Backend/package-lock.json` (transitive via `express`); `server.js:20-22`; `middleware/rateLimit.js`

**Attack surface:** `X-Forwarded-For` handling when `TRUST_PROXY` is set to a subnet or a non-numeric value
**Threat actor:** anonymous internet client
**Precondition:** the backend runs behind a proxy with a `trust proxy` subnet configuration
**Impact:** a spoofed client IP lets an attacker evade per-IP login, signup and refresh limits (AUD-05), or attribute abuse to someone else
**Exploitability:** low effort once the precondition holds
**Affected asset:** account passwords (brute force)

#### Problem
`npm audit` now reports `proxy-addr 1.1.0 - 2.0.7` as critical
(GHSA-jqcg-44mw-7w3h, IP spoofing via IPv4-mapped IPv6 in trust subnets).
Separately, `server.js` passes `Number(TRUST_PROXY) || TRUST_PROXY`. A value
like `true` therefore means "trust every hop", which makes
`X-Forwarded-For` fully client-controlled even after the patch.

#### Why it matters
The AUD-05 brute-force protection depends entirely on `req.ip`. Node CI
will also go red on its next run (`npm audit --audit-level=high`), adding a
second failing gate on top of AUD-42.

#### Recommended fix
Run `npm audit fix` and re-run the suite. Accept only a positive integer
hop count for `TRUST_PROXY` and refuse to start otherwise, by adding it to
`config/env.js`'s `invalidConfig`.

#### Verification and regression test
`npm audit` is clean. Add a `config/env.js` unit test that `TRUST_PROXY=true`
and `TRUST_PROXY=abc` are rejected and `TRUST_PROXY=1` is accepted.

---

### AUD-45 — Notification tap sends one server's credentials to another

**Category:** SECURITY / BUG · **Severity:** High · **Priority:** P1 · **Confidence:** HIGH-CONFIDENCE
**Location:** `lib/main.dart:34-42`; every `JenkinsRepositoryImpl` call that appends to an absolute job URL (for example `fetchFolder`, `fetchJobDetail`)

**Attack surface:** the local notification payload
**Threat actor:** none required. It's a correctness bug with a security consequence, and also any Jenkins host the user has saved but trusts less.
**Precondition:** watches on two servers; the user switches the active server, then taps a notification for the other one
**Impact:** server A's username and password or API token go to server B's host in an `Authorization: Basic` header
**Affected asset:** Jenkins credentials

#### Problem
`BuildWatch` stores `serverId` and a `jobUrl` rewritten to that server's
host. The notification-tap listener ignores `serverId`. It builds
`JenkinsJob(url: value)` and pushes job detail, which uses
`jenkinsRepositoryProvider`, the **active** server's `Dio`. Repository
methods call `_dio.get('${_withSlash(job.url)}api/json')`, and Dio sends
absolute URLs as-is with the client's default headers. Server A's Basic
Auth header is attached to a request to server B. Users who keep a client
or vendor Jenkins next to their own are exactly the multi-server persona.

The deep-link path (`OpenLinkScreen`) already handles this correctly:
resolve, then confirm, then switch. The notification path skips all of it.

#### Recommended fix
1. Put `serverId` in the notification payload (encode it with the URL).
2. Route taps through the same flow as `OpenLinkScreen`, for example
   `context.push(AppRoutes.openLink, …)` with the stored server id.
3. Defence in depth: add a Jenkins `Dio` interceptor that rejects any
   request whose host and port differ from `baseUrl` with an
   `AppFailure`, so no future code path can repeat this.

#### Verification and regression test
- Widget test: two servers, a watch on B, A active, tap the notification.
  Expect the switch confirmation and no request to B with A's header.
- Unit test of the host-pinning interceptor: a request to a foreign host
  never reaches the adapter.

---

### AUD-46 — Editing the active server keeps the old URL and secret

**Category:** BUG · **Severity:** High · **Priority:** P1 · **Confidence:** HIGH-CONFIDENCE
**Location:** `lib/presentation/features/settings/server_form_notifier.dart:62-74`; `active_server_notifier.dart:24-62`
**User journey:** Settings → edit the active server → change the password to an API token (the P11-14 nudge) or fix the URL → Save

#### Problem
`ActiveServerNotifier` holds a `JenkinsServer` **snapshot**, including
`secret`. Saving an edit refreshes `credentialsNotifierProvider` but
updates the active server only `if (isDefault)`. With "Set as default" off,
which is the common case when editing, `jenkinsClientProvider` keeps
building `Dio` from the old URL and secret.

**Current behavior:** the old credentials are used until an app restart or a
manual re-select. If the old password was revoked after switching to a
token, every screen shows "Your credentials were rejected".
**Expected behavior:** an edit to the active server applies immediately.

#### Root cause
The active server is stored as a value, not derived. Its `build()` reads
the credentials with `ref.read`, never `ref.watch`. The same pattern
appears in `ActiveGitHubCredentialNotifier` and
`ActiveSonarQubeCredentialNotifier`; check both.

#### Recommended fix
Store only the active **id**, and derive the server from
`credentialsNotifierProvider` (`ref.watch` plus a lookup). The minimal fix
is: after a successful update, `if (id == activeServer.id)
setActiveServer(value)`.

#### Regression test
In `server_form_notifier_test.dart`: edit the active server's secret with
`isDefault: false`, then expect `jenkinsClientProvider`'s `Authorization`
header to carry the new secret. No such test exists today.

---

### AUD-47 — A failed refresh signs the user out, and the refresh limit is per IP

**Category:** RELIABILITY / SECURITY · **Severity:** High · **Priority:** P1 · **Confidence:** HIGH-CONFIDENCE (the impact depends on deployment topology)
**Location:** `lib/core/network/backend_api_client.dart:83-99,122-143`; `JobTrigger-Backend/middleware/rateLimit.js:37-41`; `notifications/background_watch.dart:44-62`

#### Problem
- `_refresh` returns `null` for **any** `DioException`: a 429, a 5xx, a
  timeout, or no network. The interceptor then runs
  `secureStorage.clear()` (`deleteAll`) and `onUnauthorized`. A transient
  backend blip at the moment a 15-minute access token expires permanently
  discards a valid 30-day refresh token.
- `refreshLimiter` allows 30 refreshes per 15 minutes **per IP**. The
  target users work on corporate networks behind one egress IP. Each
  active user refreshes about every 15 minutes, so roughly 30 or more
  concurrent users in one office exhaust the limit. Everyone after that
  gets 429, then a wiped session, then the login screen.
- The background isolate (`buildWatchDispatcher`) goes through the same
  interceptor. Its access token is almost always expired (the app has been
  closed for more than 15 minutes), so it refreshes on every run. A
  failure there silently logs the user out while the app is closed.

#### Recommended fix
- Client: clear the session **only** when `/api/auth/refresh` returns
  401. On a 429, 5xx or network error, return the original error as a
  `NetworkFailure` or `ServerFailure` and keep the tokens.
- Backend: key `refreshLimiter` on the token subject (the user id from a
  verified refresh token), not the IP, or raise the IP limit. Keep per-IP
  limits for login and signup only.
- Consider rotating refresh tokens with reuse detection (today a stolen
  refresh token is valid for 30 days unless the user runs "log out
  everywhere").

#### Regression tests
Interceptor tests where `/refresh` answers 429, 503 or a connection
error: the tokens survive and `onUnauthorized` is not called. Backend: 31
refreshes from one IP with different users all succeed.

---

### AUD-48 — No account deletion, password change or password reset

**Category:** PRODUCT / COMPLIANCE / PRIVACY · **Severity:** High · **Priority:** P1 (release blocker) · **Confidence:** CONFIRMED (absent)
**Location:** `JobTrigger-Backend/routes/authRoutes.js` (signup, login, refresh, logout-all only); `docs/user-stories/shared/01-authentication.md` (US-AUTH-01..05)

#### Problem
The app offers account creation but has no way to delete the account and
its stored tool credentials. Apple App Store Review Guideline 5.1.1(v)
requires in-app account deletion for apps that support account creation,
and Google Play requires an in-app and web deletion path. There is also no
password change and no forgot-password flow. A user who forgets their
password is locked out of all their saved servers forever. The first audit
noted (AUD-26) that a future password-change endpoint must bump
`tokenVersion`; no story tracks it.

#### Recommended fix
New stories US-AUTH-06 (delete account), US-AUTH-07 (change password) and
US-AUTH-08 (reset password); see §20. These are backend-track items: they
need `DELETE /api/auth/account` (cascade-delete all three credential
collections), `POST /api/auth/password` (bump `tokenVersion`) and a reset
flow (needs an email provider, which is a product decision).

---

### AUD-49 — Build watches: lost updates and overlapping checks

**Category:** BUG / CONCURRENCY · **Severity:** Medium · **Priority:** P2 · **Confidence:** HIGH-CONFIDENCE
**Location:** `notifications/watch_runner.dart:15-48`; `build_watch_notifier.dart:74-111,120-126`

#### Problem
`runWatchCheck` loads the store, then awaits the network for each watch in
turn (each up to a 15-second connect plus 15-second receive timeout), then
calls `store.save(remaining)` and the notifier sets `state = remaining`.

- A watch **added** during that window is overwritten and lost.
- A watch **removed** during it comes back.
- The 30-second `Timer.periodic` never checks whether a pass is still
  running. Two watches on an unreachable server already take more than 30
  seconds, so passes overlap and the same build can be notified twice.
- The background isolate and the foreground timer have the same race
  against each other. `prefs.reload()` narrows it but doesn't close it.

#### Recommended fix
Keep a `_checking` guard in the notifier and skip a tick while a pass runs.
Merge results by `watch.key` against a fresh `load()` just before saving,
instead of overwriting: apply only the per-key outcomes this pass computed.
Run per-watch fetches with `Future.wait` grouped by server.

#### Regression test
A fake repository with a delayed completer: start `check()`, call
`watchBuild` before it completes, then expect both watches to be present.
A second test: a tick during a running pass doesn't start another.

---

### AUD-50 — Artifact file name from Jenkins is written to disk unsanitized

**Category:** SECURITY · **Severity:** Medium · **Priority:** P2 · **Confidence:** HIGH-CONFIDENCE (code path); exploitation needs a hostile server

**Attack surface:** the `artifacts[].fileName` JSON field
**Threat actor:** a malicious or compromised Jenkins, or a MITM on an `http://` server (allowed, with a warning, since P12-06)
**Impact:** write arbitrary files inside the app sandbox (for example, overwrite the `shared_preferences` store or plant files under the job-tree cache), outside the temp folder that is cleaned up
**Location:** `job_detail/artifact_download_notifier.dart:75`

#### Problem
`'${folder.path}/${artifact.fileName}'` is passed to `dio.download`. A
`fileName` of `../../shared_prefs/x.xml` escapes the per-download temp
folder, and the `finally` block deletes only that folder. The full-log
export in the same feature already does this correctly with `_fileSafe()`
(`build_log_screen.dart:219`), so the two code paths are inconsistent.

#### Fix and test
Use the basename only (`p.basename`, or strip `/`, `\` and `..`), and fall
back to `artifact` when the result is empty. Add a unit test that a
`../` file name resolves inside the temp folder.

---

### AUD-51 — External deep links can open `extra`-only routes and crash them

**Category:** BUG / ROBUSTNESS · **Severity:** Medium · **Priority:** P2 · **Confidence:** HIGH-CONFIDENCE
**Location:** `presentation/navigation/app_router.dart:166-216`; `AndroidManifest.xml` (`flutter_deeplinking_enabled`); `Info.plist` (`FlutterDeepLinkingEnabled`)

#### Problem
Deep linking is enabled for the whole router, not just `/open`. Any web
page or app can fire `jobtrigger://app/home/job` (or `/home/job/build-log`,
`/home/job/build`, `/home/job/history`, `/github/repos/workflows`). The
builder runs `state.extra! as JenkinsJob` and throws on null. The user then
sees Flutter's error widget (grey in release) in place of a screen. There
is no `errorBuilder` or `onException` either.

#### Fix and test
Add a top-level `redirect` that sends any `extra`-requiring route with a
missing or wrongly-typed `extra` to `AppRoutes.home`. Add an `errorBuilder`.
Better, accept only `/open` from the platform (a `redirect` on
`state.uri.scheme == 'jobtrigger'` other than `/open`). Router test:
`router.go('/home/job')` with no `extra` lands on Home.

---

### AUD-52 — SonarQube URL is not validated and `http://` sends the token silently

**Category:** SECURITY · **Severity:** Medium · **Priority:** P2 · **Confidence:** CONFIRMED
**Location:** `settings/sonarqube_credential_form_notifier.dart`, `sonarqube_credential_edit_bottom_sheet.dart`; compare `domain/credential/jenkins_url.dart`

AUD-14's fix (scheme and host validation, normalisation, and the "Not
encrypted" warning) was applied only to Jenkins. A self-hosted SonarQube
`baseUrl` accepts any string, and "Test connection" sends the Bearer token
over `http://` with no warning. **Fix:** generalise `jenkinsUrlProblem` and
`isCleartext` into a shared `serverUrlProblem`, and use it in the SonarQube
form and its test-connection notifier. Mirror the existing
`server_form_notifier_test` cases.

---

### AUD-53 — App lock and its sensitive-action re-prompt can be turned off without authenticating

**Category:** SECURITY / UX · **Severity:** Medium · **Priority:** P2 · **Confidence:** CONFIRMED
**Location:** `app_lock/app_lock_notifier.dart:155-171`

`setEnabled(false)` and `setRequireForSensitive(false)` save immediately.
US-JX-21's threat model is "someone else holding my unlocked phone". That
person can open Settings within the timeout window and disable both
protections, then trigger builds freely. **Fix:** require
`_authenticate('Turn off app lock')` (and the same for turning off the
re-prompt) before saving. **Test:** with a failed authentication, the
setting remains enabled.

---

### AUD-54 — Widget and notifications reveal job data regardless of app lock

**Category:** PRIVACY · **Severity:** Medium · **Priority:** P3 · **Confidence:** CONFIRMED (by design)
**Location:** `ios/PinnedJobsWidget/PinnedJobsWidget.swift`, `home_widget_sync.dart`, `core/platform/notification_service.dart`

The code itself treats job names as sensitive (it clears them on logout and
caches them only in non-backed-up storage). Yet with app lock on, pinned job
names and statuses still show on the home screen and lock screen, and build
notifications show `"<job> #N failed"` on the lock screen. Android
notifications don't set `visibility: NotificationVisibility.private`.
**Fix:** when app lock is enabled, write a redacted snapshot (counts or
statuses only), apply `.privacySensitive()` on iOS, and set private
visibility with a public redacted version on Android. This is a product
decision; document it in US-JX-21 and US-JX-23 either way.

---

### AUD-55 — Account enumeration and per-IP-only login throttling (backend track)

**Category:** SECURITY · **Severity:** Medium · **Priority:** P2 · **Confidence:** CONFIRMED
**Location:** `controllers/authController.js:48-51,72-81`; `middleware/rateLimit.js:26-30`

- Login returns before running bcrypt when the email is unknown, so
  response time distinguishes "no such account" from "wrong password".
- Signup answers `User already exists`, which is explicit enumeration.
  The signup limit of 5 per hour per IP slows it, but rotating IPs bypass
  that.
- The AUD-05 fix proposed "per IP **plus a per-email key**", but only the
  per-IP limiter shipped. Credential stuffing from a botnet faces no
  per-account limit at all.

**Fix:** compare against a dummy bcrypt hash when the user is missing.
Return a generic signup response, or accept the trade-off explicitly in
US-AUTH-01. Add a second limiter keyed on `email` (normalised) for failed
logins. **Test:** timing-insensitive. Assert that `comparePassword` or
bcrypt is called on the unknown-user path, and that the eleventh failed
login for one email from distinct IPs gets 429.

---

### AUD-56 — No iOS privacy manifest

**Category:** RELEASE / COMPLIANCE · **Severity:** Medium · **Priority:** P1 (before the first TestFlight upload) · **Confidence:** CONFIRMED (absent); impact HIGH-CONFIDENCE

There is no `PrivacyInfo.xcprivacy` in `ios/Runner` or
`ios/PinnedJobsWidget`. The widget extension's own Swift code calls
`UserDefaults(suiteName:)`, a required-reason API category, and the app
target uses `NSUserDefaults` through `shared_preferences`. Since May 2024,
App Store Connect rejects uploads that use required-reason APIs without a
declared reason (ITMS-91053). **Fix:** add manifests to both targets with
`NSPrivacyAccessedAPICategoryUserDefaults` (reason `CA92.1` / `1C8F.1` for
App Groups). Declare collected data: email address and account
credentials. Add it to `release-checklist.md`.

---

### AUD-57 — No iOS build in push CI

**Category:** DEVOPS · **Severity:** Medium · **Priority:** P2 · **Confidence:** CONFIRMED

AUD-40's lesson ("tests don't run Gradle") was applied to Android only. The
iOS target now has a WidgetKit extension, App Group entitlements,
`BGTaskScheduler` registration and Face ID. None of it is compiled on push;
only the manual `cd.yml` builds it. **Fix:** add a `macos-latest` job that
runs `flutter build ios --debug --no-codesign`, on PRs only if cost matters.

---

### AUD-58 — The seed script creates a published-password account with no environment guard

**Category:** SECURITY / OPERATIONS (backend track) · **Severity:** Medium · **Priority:** P2 · **Confidence:** POTENTIAL
**Location:** `JobTrigger-Backend/scripts/setup-migrations.js:61-93`; `setup-dev.sh:96-126`; `docs/dev-setup.md`; `docs/mongodb-cloud-setup.md`

The script deletes and re-seeds `AppInfo` (with `example.com` URLs). It
creates `developer@jobtrigger.app` with a password published in the README,
and three placeholder Jenkins credentials. It connects to whatever
`MONGODB_URI` says. The docs offer Atlas as a drop-in database, so a
shared or staging cluster can end up with a known-password account.
**Fix:** refuse to run unless `NODE_ENV !== 'production'` and the URI host
is `localhost`/`127.0.0.1`/`mongo`, or an explicit `--i-know` flag is
passed. Never seed the dev user outside local.

---

### AUD-59 — DevSecOps gaps in the pipeline

**Category:** DEVOPS / SUPPLY-CHAIN · **Severity:** Medium · **Priority:** P3 · **Confidence:** CONFIRMED

| Control | State |
|---|---|
| SCA, npm | ✅ blocking (`npm audit --audit-level=high`) |
| SCA, pub (87 packages behind; Riverpod, freezed and analyzer pinned exact) | ❌ none. Add `osv-scanner` on `pubspec.lock`. |
| Secret scanning | ❌ no gitleaks/trufflehog step. GitHub push protection is unknown. |
| SAST | ⚠️ SonarCloud is configured, but `sonar.projectKey=CHANGE_ME`, so it self-skips. Nothing runs for Dart beyond `flutter analyze`. |
| Container scan | ❌ the image is built in `cd.yml` but not scanned (Trivy/Grype). |
| Action pinning | ⚠️ tags (`@v2`, `@v4`, `@v5`), not commit SHAs |
| Workflow `permissions:` | ❌ none declared, so they depend on the repository default |
| Generated-code drift | ❌ 116 `*.g.dart`/`*.freezed.dart` files are committed, but CI never runs `build_runner` plus `git diff --exit-code` |
| Branch protection | UNKNOWN. The evidence (AUD-42) suggests it is not enforced. |
| SBOM / artifact signing | ❌ (acceptable pre-release) |

---

### AUD-60 — The index has a blanked plugin registrant staged

**Category:** HYGIENE · **Severity:** Low · **Priority:** P1 (trivial) · **Confidence:** CONFIRMED

`git diff --cached` shows `JobTrigger-Frontend/macos/Flutter/GeneratedPluginRegistrant.swift`
with all nine plugin registrations removed (most likely regenerated while
the pub cache was missing). The working tree matches `HEAD` again. A
`git commit` of the index would break secure storage, notifications and the
rest on the macOS development target. **Fix:** run
`git restore --staged JobTrigger-Frontend/macos/Flutter/GeneratedPluginRegistrant.swift`.
The auditor did not touch the index.

---

### AUD-61 — Status documents contradict each other

**Category:** DOCUMENTATION · **Severity:** Low · **Priority:** P3 · **Confidence:** CONFIRMED

- `docs/user-stories/README.md` says GitHub Actions is "**implemented**".
  `tasks/README.md` says P8 is in progress at 11 of 28, and the app shows
  "GitHub Actions run history is coming soon".
- The 2026-09-29 audit's baseline (`371 passed`, "CI not running") and the
  "41 findings, all fixed" claim don't reflect that CI has been red since
  2026-09-30 (AUD-42).
- `pubspec.yaml` still has the template `description: "A new Flutter project."`.

**Fix:** keep one status of record (`tasks/README.md`) and make the other
documents link to it rather than restate it.

---

### AUD-62 — Accessibility coverage is thin outside the status indicator

**Category:** ACCESSIBILITY · **Severity:** Low · **Priority:** P3 · **Confidence:** POTENTIAL

`Semantics(` appears in only three files: `status_indicator`, `app_lock_gate`
and `build_trends_card`. NFR-A11Y-02 (screen reader and tap targets) is
asserted by a single widget test. The `buildUnstable` orange (2.06:1 on
light) is still the open follow-up from AUD-30. Neither the console view
(custom spans), the trends chart, nor the glass surfaces have
text-scaling or screen-reader tests. **Fix:** add `meetsGuideline(
androidTapTargetGuideline / textContrastGuideline / labeledTapTargetGuideline)`
checks to the main screens' widget tests and fix what they flag. Decide the
unstable color.

---

### AUD-63 — An undecryptable credential row breaks the whole list (backend track)

**Category:** RELIABILITY · **Severity:** Low · **Priority:** P3 · **Confidence:** HIGH-CONFIDENCE
**Location:** `models/plugins/encryptedFields.js` (getter), `security/secretCipher.js:77-89`

The decrypting getter throws when a key id is missing from the keyring (for
example, a previous key dropped from `CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS`
too early) or the GCM tag fails. `toJSON` then throws, `GET
/api/credentials` returns 500, and the user loses access to **every**
server, not just the bad one. **Fix:** log the failing row and serialise it
with `secret: null` plus a `needsReentry: true` flag that the client
shows. Add a startup check that every key id present in the database is
loadable (the backfill script already scans it).

---

### AUD-64 — Low-severity hygiene items

| Item | Location | Note |
|---|---|---|
| The debug `LogInterceptor` logs request headers, including `x-auth-token` | `backend_api_client.dart:104-108` | Dio's `requestHeader` defaults to `true`. Debug only. Pass `requestHeader: false`. |
| Dead migration script with a hardcoded absolute path to the old SwiftUI repo | `JobTrigger-Backend/scripts/migrate.js:8` | Also imports plaintext passwords from JSON. Remove it, or document it as historical. |
| Android `allowBackup` left at its default (`true`), no `dataExtractionRules` | `AndroidManifest.xml` | Prefs (cached email, watch list and pinned job URLs) go to Google Drive backup. Encrypted secure-storage blobs restored to a new device can't be decrypted. Exclude both. **POTENTIAL.** |
| Placeholder production domains (`api.jobtrigger.app`, `support@jobtrigger.dev`) | `config/prod.json`, `setup-migrations.js` | **UNKNOWN** whether the team owns these domains. If not, a prod build would send account passwords to a third party. Verify ownership before any release. |
| No notifier-level re-entrancy guard on trigger | `trigger_build_notifier.dart:31-41` | Modal confirmation protects the UI path today; add `if (state.isLoading) return;` as the other notifiers do. |
| Log poll retries a deleted build forever (backoff capped at 15s) | `build_log_notifier.dart:137-159` | Stop and show "Build no longer exists" on `NotFoundFailure`. |

### AUD-65 — Every backend 400 reads "Something went wrong on the server (HTTP 400)"

**Category:** UX / BUG · **Severity:** Medium · **Priority:** P2 · **Confidence:** CONFIRMED (found 2026-10-20 while fixing AUD-48)
**Location:** `lib/data/repositories/auth_repository_impl.dart`, `core/error/app_failure.dart`

The backend answers a wrong login password with `400 {"message": "Invalid
credentials"}` and a taken email with `400 {"message": "User already
exists"}`. `AppFailure.fromDioException` maps any non-401/403/404 status to
`ServerFailure(code)`, whose copy blames the server. A user mistyping their
password saw "Something went wrong on the server (HTTP 400)". The existing
repository test even asserted `ServerFailure` for that case.
**Fix:** a `RejectedRequestFailure(serverMessage)` produced by the auth
repository for a backend 400 that carries a `message`. Those messages are
user copy by construction: the central error handler never puts internals
in a 400 (AUD-06). Jenkins 400s (HTML) are unaffected.

---

## 5. Security findings by severity

| Severity | Findings |
|---|---|
| Critical | None in this codebase's own code. AUD-44 is rated critical by npm and contextually High. |
| High | AUD-44 (`proxy-addr` / `trust proxy`), AUD-45 (cross-server credential leak), AUD-47 (session wipe; refresh-token lifetime without reuse detection) |
| Medium | AUD-50 (artifact path traversal), AUD-52 (SonarQube cleartext), AUD-53 (lock disable without auth), AUD-55 (enumeration, per-account throttling), AUD-58 (seed account), AUD-59 (pipeline controls), AUD-54 (lock-screen disclosure) |
| Low | AUD-64 (debug header logging, backups) |
| Informational | Jenkins `paramToken` travels in the trigger URL's query string, so it lands in Jenkins and proxy access logs (Jenkins' own design; document it). `workmanager` writes a marker file to temp (noted in the first audit). |

**Re-verified as holding:** AUD-01 (the legacy password key is deleted on
read; only the email is stored), AUD-03 (setters run on `$set` updates, so
updates are encrypted too), AUD-04, AUD-06, AUD-11, AUD-14 (Jenkins only;
see AUD-52), AUD-24, AUD-25, AUD-26 (with AUD-47's caveats), AUD-28 and
AUD-29. Confirmed done well: secure storage holds only the two tokens, so
`deleteAll` is safe today; the Jenkins `Dio` has no logging interceptor;
deep links refuse credentials in URLs and unknown hosts; and the widget
never fetches and holds no credentials.

---

## 6. Bug report (confirmed and high-confidence)

| ID | Bug | Reproduction |
|---|---|---|
| AUD-42 | CI test fails on Linux | Push any commit and look at the `analyze-and-test` job |
| AUD-45 | Notification opens the job against the wrong server | Watch a job on B, switch to A, wait for the notification, tap it |
| AUD-46 | Stale active-server credentials | Edit the active server's secret with "default" off, then open Home: the old secret is used |
| AUD-47 | Logged out by a transient refresh error | Let the access token expire, make the backend return 503 or 429 on `/refresh`, perform any action: back at Login |
| AUD-49 | Watch lost or resurrected | With a slow server, add a watch while a check is in flight: it disappears 30s later |
| AUD-51 | Grey error screen from a deep link | `adb shell am start -d "jobtrigger://app/home/job"` |
| AUD-63 | All servers vanish after a key-rotation mistake | Drop a previous key id that the database still uses, then `GET /api/credentials` returns 500 |

---

## 7. UI audit

| Screen | Issue | Severity | Evidence | Recommendation |
|---|---|---|---|---|
| Any `extra` route | Error widget shown for an external deep link | Medium | AUD-51 | Redirect to Home |
| History tab (GitHub Actions) | Placeholder "coming soon" in a production tab | Low | `app_router.dart:98-123` | Hide the tab or disable it with an explanation while GH-HIST is unbuilt |
| Unstable status color | 2.06:1 contrast on light | Low | AUD-30 follow-up | Decide a darker shade; keep the icon and label (NFR-A11Y-03) |
| Settings → app lock | Destructive toggle with no confirmation | Medium | AUD-53 | Require authentication |

The rest of the UI (confirmation sheets with parameter summaries and masked
secrets, offline banner, reconnecting banner, progress on artifact
download, toasts for every failure) is consistent and well-specified.

---

## 8. UX audit

| Journey | Friction | Impact | Recommendation |
|---|---|---|---|
| Rotate a password to an API token (the P11-14 nudge) | The change doesn't apply until restart (AUD-46) | The user follows the app's own advice and gets "credentials rejected" | Derive the active server from the list |
| Return to the app after a backend blip | Silently signed out (AUD-47) | Repeated logins; loss of trust | Keep the session on non-401 refresh errors |
| Notification tap for a non-active server | Wrong data or an auth error (AUD-45) | Confusion, plus a security issue | Same confirm-and-switch flow as deep links |
| Forgotten password | No recovery path (AUD-48) | Permanent loss of saved servers | Reset flow |
| A watch added while a check runs | Silently dropped (AUD-49) | Missed build notification | Merge by key |

---

## 9. User story audit

- **Existing stories:** AUTH, TOOL, CRED, TREE, JOB, LOG, HIST, PROF,
  DESIGN, PIPE and JX for Jenkins; GH partially implemented; SQ only up to
  credentials; GL and CC docs only. NFR-SEC, TEST, A11Y, PERF and PLAT are
  cross-referenced. The backlog doc is accurately maintained.
- **Incomplete stories or acceptance criteria:**
  - **US-JX-10** (notifications): no acceptance criteria for a
    multi-server tap target or for concurrent edits during a check
    (AUD-45, AUD-49).
  - **US-CRED-03** (edit server): no criterion that edits to the
    *active* server apply immediately (AUD-46).
  - **US-AUTH-05** (session expiry): it covers the 401 but not "refresh
    fails for a non-auth reason" (AUD-47).
  - **US-JX-21** (app lock): disabling isn't specified as requiring
    authentication, and widget and notification redaction aren't
    specified (AUD-53, AUD-54).
  - **US-JX-19** (deep links): it doesn't say that only `/open` is
    accepted from outside (AUD-51).
  - **NFR-SEC-02** (input validation): SonarQube URLs aren't named
    (AUD-52).
- **Missing stories:** see §20.

---

## 10. Functional gap analysis

| Feature | Current state | Expected state | Gap | Priority |
|---|---|---|---|---|
| Account deletion | None | In-app deletion with cascade | Store-policy blocker | P1 |
| Password change and reset | None | Change (revokes tokens) and email reset | Lockout risk | P1 |
| GitHub Actions run, log and history | Repos and workflows only | Trigger, status, logs, history (P8-12..28) | 17 tasks | P2 (or hide the tool) |
| SonarQube projects and quality | Credentials only | Projects and quality gate (P10-07..16) | 10 tasks | P2 (or hide the tool) |
| Crash reporting | Deliberately none (BACKLOG-07) | A decision before the dogfood window | No production diagnostics (§19) | P2 |
| Backend deployment | None; placeholder domains | Hosted, TLS, monitored | Everything server-side | P1 |
| Data export | None | Optional; low value for this product | — | P4 |

---

## 11. Architecture audit

- **Current:** feature-first Clean Architecture in Flutter, plus a thin
  credential vault backend, with the phone talking directly to CI tools.
  This is appropriate for the scale. There are no god classes; the largest
  files are screens of about 900 lines, which is long but cohesive.
- **Strengths:** a single error boundary (`guardRequest`), pure domain
  functions for tricky logic (`decideWatch`, `resolveJenkinsLink`,
  `shouldLockOnResume`, `ConsoleDecoder`), and provider overrides
  everywhere for testability.
- **Weaknesses:**
  1. *State stored as snapshots, not derived* (`ActiveServerNotifier`
     holding secrets), which caused AUD-46.
  2. *Host trust is implicit*: the Jenkins `Dio` will send its credentials
     anywhere an absolute URL points. It is safe only because every URL
     source rewrites, and one source (notifications) doesn't (AUD-45). Pin
     the host in the client.
  3. `core/network/jenkins_client_factory.dart` imports
     `presentation/features/settings/active_server_notifier.dart`, so core
     depends on presentation. The same applies to the GitHub and SonarQube
     factories. This is a layering inversion that `docs/architecture.md`
     forbids. Move the "active credential" providers to the
     domain or data layer.
  4. Shared mutable store across isolates without a merge strategy
     (AUD-49).
- **Recommendation:** no rewrite. Apply targeted fixes: derived active
  credentials, a host-pinning interceptor, and a merge-based watch store.

---

## 12. API audit

| Endpoint | Auth | Notes |
|---|---|---|
| `POST /api/auth/signup` | none; limit 5/h/IP | Enumerates existing accounts (AUD-55). Email and password validated. |
| `POST /api/auth/login` | none; 10 failed per 15 min per IP | Timing enumeration; no per-account limit (AUD-55). Returns 400, not 401, for bad credentials (consistent with the client). |
| `POST /api/auth/refresh` | refresh token; 30/15 min/IP | The IP key punishes NAT (AUD-47). No rotation or reuse detection. |
| `POST /api/auth/logout-all` | access | ✅ |
| `GET/POST/PUT/DELETE /api/{credentials,github-credentials,sonarqube-credentials}` | access | ✅ owner-scoped and validated. No cap on the number of credentials per user and no pagination (Low). Returns decrypted secrets by design. One bad row returns 500 for the whole list (AUD-63). |
| `POST /api/*/switch/:id` | access | ✅ `bulkWrite`; the documented residual race is acceptable |
| `GET /api/appinfo` | public | Fine |
| `GET /healthz` | public | ✅ DB-aware. There is no readiness/liveness split (acceptable for a single container). |
| Missing | — | Account delete, password change/reset (AUD-48). There is no API versioning (`/api/v1`); add it before the first public client ships, because store builds can't be force-updated. |

---

## 13. Database audit

- **Schema:** `User.email` is unique and lower-cased. The credential
  collections have **no index on `userId`**; every list, update and switch
  filters on it. That's fine at the current size and a collection scan at
  scale, so add `{ userId: 1 }` (and `{ userId: 1, isDefault: 1 }`).
- **Integrity:** there is no cascade from `User` to credentials (relevant
  once AUD-48 adds deletion). "Only one default per user" isn't enforced
  by a partial unique index (`{userId:1}` unique where `isDefault: true`),
  and the code comment admits the residual race.
- **Security:** field encryption is strong (GCM, per-value IV, AAD = field
  name, key id). Key management is environment-based; plan KMS longer term,
  as the first audit noted. Server and job URLs and usernames are plaintext,
  which is acceptable, but document it.
- **Backup and recovery:** not documented anywhere. Losing
  `CREDENTIALS_ENCRYPTION_KEY` makes every stored secret unrecoverable; the
  key needs its own backup procedure in `docs/deployment.md`.
- **Migrations:** ad hoc scripts; see AUD-58 and AUD-64.

---

## 14. Performance audit

- **Current:** none blocking. AUD-12 and AUD-20 hold: incremental console
  decoding, a 20k-line cap, tail-first opening for logs over 1 MB, and lazy
  folders.
- **Potential:**
  - `BuildLogNotifier._apply` copies up to 20k lines into a new
    `List.unmodifiable` every poll (each second), which is O(n) allocation
    per second during long builds. Consider exposing an append-only view.
  - Watch checks run sequentially with 30-second worst-case timeouts per
    watch (AUD-49).
  - `pinnedJobStatusProvider` fetches every pin's full `_detailsTree` (with
    parameters, change sets and artifacts) only to show a colour in the
    widget. Use the lean tree fields instead.
- **Scaling:** the backend credential lookups need the `userId` index
  (§13). bcrypt cost 10 is fine.

---

## 15. Testing gap analysis

| Area | Existing coverage | Missing coverage | Priority |
|---|---|---|---|
| CI determinism | 639 tests | Tests that touch platform plugins without overrides (AUD-42) | P0 |
| Active credential lifecycle | Add, delete, switch | Edit active server (Jenkins, GitHub, SonarQube) (AUD-46) | P1 |
| Session refresh | 401 to refresh to replay; concurrent 401s | Refresh answering 429, 5xx or timeout; background-isolate refresh (AUD-47) | P1 |
| Notifications | `decideWatch` pure tests | Concurrent add during check; overlapping ticks; multi-server tap (AUD-45/49) | P1 |
| Router | Auth redirect; open link | External deep link with no `extra` (AUD-51) | P2 |
| File handling | Artifact progress | Hostile `fileName` (AUD-50) | P2 |
| App lock | Lock and unlock, timeouts | Disable requires authentication (AUD-53) | P2 |
| Backend auth | 58+ tests, sessions, rate limits | Unknown-user timing path; per-email limit; `TRUST_PROXY` validation (AUD-44/55) | P2 |
| Accessibility | Status indicator label | Guideline matchers on the main screens (AUD-62) | P3 |
| iOS native | None in CI | Widget extension and entitlements compile (AUD-57) | P2 |
| Real-Jenkins fixture suites | 16 suites, skipped in CI | They need a Jenkins service container to run in CI at all; today they only run by hand | P3 |

---

## 16. DevOps and CI/CD audit

- **Build:** Flutter analyze, format and test run on push; Android debug
  build runs on push; iOS builds only manually (AUD-57).
- **Test:** red for 19 pushes (AUD-42). Fixture tests are skipped in CI.
- **Security:** npm SCA blocks; pub has no SCA; no secret scanning; SAST
  placeholder (AUD-59).
- **Deployment:** none. `cd.yml` builds with the wrong config (AUD-43).
  The Android release key setup is good (AUD-15 holds).
- **Secrets:** CI uses only `CODECOV_TOKEN` and `SONAR_TOKEN`, guarded
  properly through `env`. There is no workflow `permissions:` (AUD-59).
- **Infrastructure:** the Dockerfile is good (non-root, `HEALTHCHECK`,
  `npm ci --omit=dev`, `.dockerignore` excludes `.env*`). The
  `docker-compose.yml` exposes Mongo on `0.0.0.0:27017` with no auth. That
  is fine for a laptop and dangerous on any shared host; bind to
  `127.0.0.1`.
- **Rollback and monitoring:** none yet (§19, §21).

---

## 17. Accessibility audit

See AUD-62 and the UI table. The design-system doc (US-DESIGN, NFR-A11Y)
is thorough, and reduce-transparency is implemented. Verification is the
gap, not intent.

---

## 18. Documentation audit

- **Strengths:** a new developer can realistically clone, configure
  (`setup-dev.sh`), run, test and understand this project. The architecture,
  API, data-model and state docs are among the best seen at this stage.
- **Incorrect or outdated:** `docs/deployment.md` build commands (AUD-43);
  the "implemented" status for GH (AUD-61); the first audit's baseline
  table (AUD-61).
- **Missing:**
  - an incident runbook
  - encryption-key backup and restore
  - a production environment-variable reference (`TRUST_PROXY` semantics,
    the `CORS_ORIGINS` default)
  - a privacy policy and data inventory (the App Info screen links to
    `example.com`)
  - a backend deployment target

---

## 19. Technical debt

| Level | Debt |
|---|---|
| Critical | No CI enforcement (AUD-42); release config is not fail-safe (AUD-43) |
| High | Active credentials stored as snapshots (AUD-46); implicit host trust in the Jenkins client (AUD-45); `core` importing `presentation` (§11) |
| Medium | Watch-store merge strategy (AUD-49); ad hoc DB scripts (AUD-58); no pub SCA (AUD-59); placeholder SonarCloud config |
| Low | Dead `migrate.js`; template `pubspec` description; `compileSdk = 37` pin to revert when Flutter catches up (AUD-40 note) |

**Observability ("3 AM test"):** the backend logs unexpected errors to
stdout with method and URL, but there are no request ids, structured logs,
metrics or alerts. The app has no crash reporting by decision
(BACKLOG-07). Today, an engineer **could not** tell why a user was signed
out or why a trigger failed in production. Before the dogfood window
(P6-12), add at least: a request-id middleware, structured (JSON) logs with
auth outcomes and no secrets, and a crash-reporting decision.

---

## 20. Missing user stories

### US-AUTH-06 — Delete my account

> As a JobTrigger user, I want to delete my account and everything stored
> with it, so that my CI credentials don't outlive my use of the app.

**Priority:** Must (store policy) · **Reason missing:** account lifecycle
was never scoped beyond the SwiftUI parity set.

- Given I'm signed in, when I choose Profile → Delete account and confirm
  with my password, then my user and all Jenkins, GitHub and SonarQube
  credential rows are deleted, every token is revoked, and local data is
  cleared as on logout.
- Given the backend is unreachable, when I confirm, then nothing is
  deleted locally and I see a retryable error.
- **Edge cases:** app lock is on (require biometric too); deletion during
  an in-flight background check; deletion succeeds server-side but the
  network drops before the response (make it idempotent).
- **Dependencies:** a backend endpoint (backend track), a privacy policy
  URL, AUD-48.

### US-AUTH-07 — Change my password

> As a user, I want to change my password, so that I can respond to a
> suspected compromise.

- Given the correct current password and a valid new one, when I submit,
  then the password is updated, `tokenVersion` is bumped, other devices
  are signed out, and this device gets a new token pair.
- Given a wrong current password, then a 400 is returned and nothing
  changes, rate-limited like login.
- **Dependencies:** backend endpoint; reuse `AuthValidation`.

### US-AUTH-08 — Reset a forgotten password

> As a user who forgot my password, I want to reset it by email, so that I
> don't lose my saved servers.

- A single-use, 15-minute token is sent by email. The response is the
  same whether or not the email exists (no enumeration). A successful reset
  bumps `tokenVersion`.
- **Dependencies:** an email provider (product and backend decision).

### US-CRED-07 — Edits to the active server take effect immediately

> As a user rotating credentials, I want my edits to the server I'm using
> to apply at once, so that I'm not stuck with a revoked password.

- Given server A is active, when I save a new secret or URL for A, then
  the next request uses the new values without a restart (AUD-46).

### US-JX-24 — Notifications respect which server a build belongs to

> As a user with several Jenkins servers, I want a notification to open
> the build on its own server, so that I never act on, or authenticate
> to, the wrong one.

- A tap on another server's notification asks to switch (as US-JX-19
  does). Credentials are never sent to a host other than the server they
  belong to (AUD-45).

### NFR-SEC-07 — Session continuity

- A session ends only on an explicit logout, a 401 from `/refresh`, or
  "log out everywhere". Network, 429 and 5xx errors never end it (AUD-47).

---

## 21. Recommended backlog

| Priority | Task | Category | Dependency | Complexity |
|---|---|---|---|---|
| P0 | Override `backgroundWatchSchedulerProvider` in the test harness; get CI green; enable branch protection | Testing / DevOps | — | S |
| P0 | Fail-fast release config plus `--dart-define-from-file` in `cd.yml` and the docs | Config | — | S |
| P0 | `npm audit fix`; validate `TRUST_PROXY` | Security (backend) | approval | S |
| P1 | Unstage the blanked registrant | Hygiene | — | XS |
| P1 | Notification tap through the open-link flow; host-pinning interceptor | Security | — | M |
| P1 | Derive active credentials from the list (Jenkins, GitHub, SonarQube) | Bug / Architecture | — | M |
| P1 | Keep the session on non-401 refresh errors; key the refresh limit by user | Reliability (both) | approval | S–M |
| P1 | Account delete and password change endpoints and screens | Product / Compliance | approval; privacy policy | M |
| P1 | iOS privacy manifests | Release | — | S |
| P1 | Verify ownership of the `jobtrigger.app` and `jobtrigger.dev` domains | Release | — | XS |
| P2 | Watch-store merge plus re-entrancy guard | Bug | — | M |
| P2 | Sanitize artifact file names | Security | — | XS |
| P2 | Route guard for `extra` routes; `errorBuilder` | Bug | — | S |
| P2 | Shared URL validation for SonarQube | Security | — | S |
| P2 | Authentication required to disable app lock and re-prompt | Security | — | S |
| P2 | Dummy-hash login; per-email failed-login limiter | Security (backend) | approval | S |
| P2 | Seed-script environment guard | Ops (backend) | approval | XS |
| P2 | iOS build job in CI | DevOps | — | S |
| P2 | Password reset flow | Product | email provider decision | L |
| P3 | Pub SCA, gitleaks, action SHA pinning, `permissions:`, generated-code drift check, Trivy | DevSecOps | — | M |
| P3 | Lock-aware widget and notification redaction | Privacy | product decision | M |
| P3 | `userId` indexes; partial unique default index | Database | approval | S |
| P3 | Per-row decrypt resilience | Reliability (backend) | approval | S |
| P3 | Accessibility guideline tests; unstable color decision | A11y | design decision | M |
| P3 | Request ids, structured logs, crash-reporting decision | Observability | BACKLOG-07 decision | M |
| P3 | Reconcile status docs | Docs | — | XS |
| P4 | Remove `migrate.js`; debug log headers off; backup exclusions; `/api/v1` prefix | Hygiene | — | S |

---

## 22. Recommended implementation order

### Phase 1 — Gates and critical config
1. AUD-60 unstage the registrant.
2. AUD-42 green CI, then branch protection.
3. AUD-44 `npm audit fix` plus `TRUST_PROXY` validation.
4. AUD-43 fail-fast release config.

### Phase 2 — Security and data correctness
1. AUD-45 notification routing plus host pinning.
2. AUD-46 derived active credentials.
3. AUD-47 session continuity (client), then the refresh limiter key (backend).
4. AUD-50, AUD-52, AUD-53 (small, independent).

### Phase 3 — Reliability and compliance
1. AUD-49 watch-store merge.
2. AUD-48 account deletion and password change (backend first).
3. AUD-56 privacy manifests; AUD-55 auth hardening; AUD-58 seed guard.

### Phase 4 — UX and UI
1. AUD-51 deep-link guard.
2. AUD-54 lock-aware redaction (after the product decision).
3. Hide or disable GitHub and SonarQube surfaces that aren't built yet.

### Phase 5 — Testing
1. The §15 matrix, starting with the regression tests named in each
   finding.
2. AUD-57 iOS CI build; run the fixture suites against a Jenkins service
   container.

### Phase 6 — Performance and operations
1. `userId` indexes; lean pin-status query; console list copy.
2. Observability baseline (§19); key backup runbook.

### Phase 7 — Nice to have
1. AUD-59 supply-chain extras (SBOM, signing), `/api/v1`, password reset UX
   polish.

---

## 23. Final scorecard

| Area | Score | Explanation |
|---|---:|---|
| Functionality | 8/10 | Jenkins depth is excellent; GitHub and SonarQube are partial; account lifecycle is missing |
| Security | 6.5/10 | Strong backend crypto and session model; a cross-server credential leak, enumeration, an open critical advisory |
| Architecture | 8/10 | Clean layers and testable pure domain logic; snapshot state and implicit host trust; a core-to-presentation import |
| Code quality | 8.5/10 | Readable and intentional, with exemplary comments; small inconsistencies (file-name sanitizing) |
| UI | 7.5/10 | Consistent design system and confirmations; the deep-link error screen; placeholder tabs |
| UX | 7/10 | Thoughtful flows; stale credentials and surprise logouts undermine trust |
| Accessibility | 6/10 | Good intent and NFRs; little verification |
| Performance | 8/10 | First-audit hotspots fixed; minor allocation churn |
| Reliability | 6/10 | Good retry and backoff in logs; session wipe and watch races |
| Testing | 7/10 | A large, meaningful suite; key concurrency and negative paths missing; CI red |
| DevOps | 5/10 | A sensible container and workflows, but the gate isn't enforced |
| CI/CD | 4.5/10 | Red for 19 pushes; the release build is misconfigured; no iOS build or pub SCA |
| Documentation | 8.5/10 | Outstanding depth; a few contradictory status claims |
| Maintainability | 8/10 | Feature-first, generated code, conventions written down |
| Production readiness | 3.5/10 | No backend host, wrong release config, store-policy gaps, no observability |

### Overall project health: **7/10**

The engineering is strong. What it needs is less code than process: an
enforced CI gate, a release path that can't silently go wrong, and closing
a short list of concrete defects.

---

## 24. Top 10 actions

| # | Action | Why | Risk reduced | Priority | Expected outcome |
|---|---|---|---|---|---|
| 1 | Fix the Linux-only test leak and require CI via branch protection | Twenty commits landed unverified | Undetected regressions | P0 | Every merge is green; "fixed" means fixed |
| 2 | Make release builds refuse to start without an `https` prod config; fix `cd.yml` and the docs | The first TestFlight build would talk to `127.0.0.1` | A broken release | P0 | Misconfiguration fails at build or launch, not in testers' hands |
| 3 | `npm audit fix` and strict `TRUST_PROXY` parsing | A critical advisory on the brute-force defence | Password guessing via IP spoofing | P0 | Rate limits trustworthy behind proxies |
| 4 | Route notification taps through the open-link flow and pin the Jenkins client to its host | Credentials can reach the wrong server | Credential disclosure | P1 | No request ever leaves with another server's credentials |
| 5 | Derive the active server and credentials from the saved list | Edits don't apply until restart | Lockouts after rotating to tokens | P1 | Edits take effect immediately |
| 6 | Only end a session on a 401 from `/refresh`; key the refresh limit per user | Office-wide sign-outs | Availability, user trust | P1 | Sessions survive blips and shared NAT |
| 7 | Ship account deletion and password change (backend plus app) | Store review blocks release | Rejection; privacy liability | P1 | Store-compliant account lifecycle |
| 8 | Add iOS privacy manifests and an iOS CI build | Upload rejection; untested native code | Release blockers | P1 | Clean App Store Connect uploads |
| 9 | Merge-based watch store with a re-entrancy guard | Silent loss of watches | Missed build alerts | P2 | Watches never vanish or duplicate |
| 10 | Close the small security items: artifact names, SonarQube URL validation, lock-disable authentication, login enumeration | Each is a cheap fix to a real gap | Path traversal, cleartext tokens, lock bypass, enumeration | P2 | Consistent security posture across tools and flows |
