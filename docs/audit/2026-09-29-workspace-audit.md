# Workspace Audit — 2026-09-29

A full audit of the `flutter-migration` branch at `57af2a2` covering
security, correctness, UI/UX, performance, release readiness, DevOps, and
code quality across `JobTrigger-Frontend/` (Flutter) and
`JobTrigger-Backend/` (Node/Express). Remediation is scheduled in
[`tasks/phase-12-audit-remediation.md`](../../tasks/phase-12-audit-remediation.md);
findings that overlap Jenkins feature work in
[`tasks/phase-11-jenkins-extended.md`](../../tasks/phase-11-jenkins-extended.md)
are cross-referenced instead of being fixed twice.

## Baseline at audit time

| Check | Result |
|---|---|
| `flutter analyze` | Clean, no issues |
| `flutter test` | 371 passed, 0 failed |
| `npm audit --omit=dev` (backend) | **4 vulnerabilities** (1 high, 2 moderate, 1 low) |
| CI on the active branch | **Not running** (see AUD-16) |

## How to use this document

- Every finding has a stable id (`AUD-##`). Reference it in commits, e.g.
  `fix(frontend): stop persisting login password [AUD-01]`.
- **Severity:** `Critical` (data exposure or the app can't work in
  production), `High` (a real security gap or user-facing defect on a common
  path), `Medium` (defect on a less common path, or a meaningful performance
  or UX cost), `Low` (hygiene, consistency, or maintainability).
- **Status:** `open`, `in-progress`, `fixed` (include the commit), or
  `won't-fix` (include the reason). Update the status in the summary table
  and the finding itself together.
- Items marked **backend track** change `JobTrigger-Backend/`. Per
  `CLAUDE.md` §7 and `NFR-SEC-05`, they need explicit approval before work
  starts.

## Summary

| Id | Severity | Area | Title | Status |
|---|---|---|---|---|
| AUD-01 | Critical | Security | Login password persisted in plaintext `shared_preferences` | fixed (P12-01) |
| AUD-02 | Critical | Release | Release Android build has no `INTERNET` permission | fixed (P12-02) |
| AUD-03 | Critical | Security (backend) | Jenkins passwords and tokens, GitHub PATs, SonarQube tokens stored unencrypted in MongoDB | fixed (P12-26) |
| AUD-04 | High | Security (backend) | NoSQL operator injection in `/api/auth/login` and `/signup` | fixed (P12-22) |
| AUD-05 | High | Security (backend) | No rate limiting or lockout on login | fixed (P12-24) |
| AUD-06 | High | Security (backend) | 500 responses leak internal `err.message` | fixed (P12-23) |
| AUD-07 | High | Security (backend) | Vulnerable dependencies (`path-to-regexp` ReDoS, `mongoose`, `qs`) | fixed (P12-20) |
| AUD-08 | High | UX / Safety | Trigger and Cancel fire with no confirmation, violating the Must criteria of US-JOB-02/03/05 | fixed (P11-04) |
| AUD-09 | High | Bug | Global history uses duplicate `ValueKey`s when job names repeat across folders | fixed (P12-05) |
| AUD-10 | High | Bug | Folder breadcrumb shows stale or other-server contents after refresh or server switch | fixed (P11-05) |
| AUD-11 | High | Bug / Architecture | Non-`DioException` errors escape the data layer and bypass `AppFailure` | fixed (P12-04) |
| AUD-12 | High | Performance | Console log re-sanitizes and re-splits the whole log every second (O(n²)) | fixed (P11-11) |
| AUD-13 | Medium | Bug | A transient log-poll error discards the displayed log | fixed (P11-11) |
| AUD-14 | High | Security / UX | Jenkins URL unvalidated; Basic Auth sent over `http://` silently; cleartext failures shown as generic errors | open |
| AUD-15 | High | Release | Android release build signed with the debug key | fixed (P12-10) |
| AUD-16 | High | DevOps | CI does not run on the active `flutter-migration` branch | fixed (P12-03) |
| AUD-17 | High | DevOps / Security | Node 20 (EOL) in Dockerfile and CI; container runs as root | fixed (P12-21) |
| AUD-18 | Medium | Bug | Edited build-parameter values silently reset when the form scrolls off-screen | fixed (P11-04) |
| AUD-19 | Medium | Bug | Folders at the tree depth limit render as jobs (5 levels fetched, docs say 6) | fixed (P11-05) |
| AUD-20 | Medium | Performance | Home fetches the whole recursive tree (all levels, with `lastBuild`) on every load | fixed (P11-05) |
| AUD-21 | Medium | Bug / Performance | Artifact download buffers the whole file in memory with a 15s timeout | fixed (P12-08) |
| AUD-22 | Medium | Bug | App Info links do nothing on Android 11+ (`canLaunchUrl` without `<queries>`) | fixed (P12-07) |
| AUD-23 | Medium | Bug (backend) | Credential `PUT` skips validators and never updates `updatedAt` | fixed (P12-25) |
| AUD-24 | Medium | Security (backend) | Ownership failures return 401 (enables id probing); `isDefault` switch not atomic | fixed (P12-25) |
| AUD-25 | Medium | Security (backend) | Wide-open CORS, no security headers, no fail-fast on missing `JWT_SECRET` | fixed (P12-23) |
| AUD-26 | Medium | Security (backend) | Weak password policy, no server-side email validation, 7-day JWT with no revocation | open |
| AUD-27 | Medium | Security / UX | Password build parameters rendered in plaintext and pre-filled | fixed (P11-04) |
| AUD-28 | Low | Privacy | Logout leaves per-user preferences behind on a shared device | fixed (P12-09) |
| AUD-29 | Low | Bug | Artifact download state keyed by relative path only, shared across builds | fixed (P12-09) |
| AUD-30 | Low | UI / A11y | Hardcoded colors bypass `AppColors` tokens (dark-mode contrast) | fixed (P12-09) |
| AUD-31 | Low | Code quality (backend) | Three copy-pasted credential controllers | fixed (P12-25) |
| AUD-32 | Low | Code quality | Trailing-slash URL normalisation duplicated 11× in `JenkinsRepositoryImpl` | fixed (P12-04) |
| AUD-33 | Low | UX | Search results lack folder context; empty state can't pull to refresh | fixed (P11-10) |
| AUD-34 | Low | Bug | Log sanitizer leaves `\r` from CRLF; escape sequences split across chunks leak | fixed (P11-11) |
| AUD-35 | Low | Docs | `CLAUDE.md` §1 still says "JWT bearer"; the backend actually uses `x-auth-token` | fixed (P12-11) |
| AUD-37 | High | Bug | A duplicate parameterized trigger (Jenkins `303`, merged into the queued build) is reported as a failure | fixed (P11-04) |
| AUD-38 | High | Bug | Triggering a job with a Run parameter from the untouched form fails (empty value → Jenkins `500`) | fixed (P11-06) |
| AUD-39 | High | Bug | Cancelling a *pipeline* build reports failure (Jenkins answers the stop with a 302) | fixed (P11-13) |
| AUD-40 | High | Release | Android build fails: `flutter_secure_storage` 11 needs compileSdk 37, the app compiled against 36 | fixed (P11-24) |
| AUD-36 | Low | Hygiene | Untracked leftovers in the workspace (1.2 GB build output, coverage, stray tool dirs) | fixed (local cleanup 2026-09-29) |

**Counts:** 3 Critical, 17 High, 11 Medium, 9 Low (40 total). AUD-37 and AUD-38 were found on 2026-09-29 during P11-04's real-server verification, AUD-39 on 2026-09-30 during P11-13's, and AUD-40 on 2026-09-30 while compile-checking P11-24's native setup.

---

## Critical

### AUD-01 — Login password persisted in plaintext `shared_preferences`

- **Where:** `JobTrigger-Frontend/lib/presentation/features/auth/login_screen.dart:36-72`
- **What:** "Remember me" writes the backend account password to
  `SharedPreferences` under `login_saved_password`. That is plaintext
  `NSUserDefaults` on iOS and an XML file on Android, readable from device
  backups and on rooted or jailbroken devices. This directly violates
  `CLAUDE.md` §7 and `NFR-SEC-01`. Unchecking "Remember me" never removes the
  saved values, and the storage access sits in a widget, which breaks the
  layering rule in `CLAUDE.md` §4/§5.
- **Fix:** Persist only the email, never the password (the JWT already keeps
  the session alive, so a stored password adds nothing). Clear saved values
  when "Remember me" is unchecked. On startup, delete any leftover
  `login_saved_password` key for already-installed users. Move this logic
  into a `RememberedEmailNotifier` or repository. Add tests.

### AUD-02 — Release Android build has no `INTERNET` permission

- **Where:** `JobTrigger-Frontend/android/app/src/main/AndroidManifest.xml`
- **What:** `android.permission.INTERNET` is declared only in the `debug/`
  and `profile/` manifests (the Flutter template default). A release APK or
  AAB can't open any socket: every backend and Jenkins call fails. Debug
  runs and CI never show this.
- **Fix:** Declare `<uses-permission android:name="android.permission.INTERNET"/>`
  in `main/AndroidManifest.xml`. Add a CI guard (a manifest grep or
  `aapt dump permissions` on the release APK in `cd.yml`).

### AUD-03 — Tool secrets stored unencrypted in MongoDB (backend track)

- **Where:** `JobTrigger-Backend/models/JenkinsCredential.js` (`password`,
  `paramToken`), `GitHubCredential.js` (`token`), `SonarQubeCredential.js`
  (`token`)
- **What:** Every CI-tool secret is stored as plaintext. A database dump,
  backup leak, or read-only injection exposes working credentials for every
  user's Jenkins, GitHub, and SonarQube. App-account passwords are
  bcrypt-hashed, but these can't be hashed because the client needs the
  secret back to call Jenkins directly (`docs/architecture.md`).
- **Fix:** Encrypt at the field level with AES-256-GCM (Node `crypto`, no new
  dependency). Use a random IV per value and read the key from
  `CREDENTIALS_ENCRYPTION_KEY`, with rotation via a key-id prefix. Encrypt
  in a mongoose setter or pre-save hook and decrypt in `toJSON`. Add a
  migration script (`scripts/migrate.js`) to encrypt existing rows. Document
  the key in `docs/deployment.md`. Longer term, move to a KMS.

## High

- **Fixed (P12-26, 2026-09-30):** `security/secretCipher.js` (AES-256-GCM,
  a random 96-bit IV, the field name as associated data, and
  `enc:v1:<keyId>:…` for rotation), applied through a mongoose plugin to
  Jenkins `password` and `paramToken` and to the GitHub and SonarQube
  `token`. The API still returns plaintext, and all existing tests pass
  unchanged. Legacy plaintext rows stay readable until
  `scripts/encrypt-credentials.js` (idempotent, `--dry-run`, and also
  rotates) encrypts them. The server won't start without a valid
  `CREDENTIALS_ENCRYPTION_KEY`. 8 tests cover the cipher, at-rest storage,
  and the backfill. Setup and rotation are in `deployment.md` and
  `database-migrations.md`.

### AUD-04 — NoSQL operator injection in auth (backend track)

- **Where:** `JobTrigger-Backend/controllers/authController.js` (`User.findOne({ email })`)
- **What:** `email` comes straight from `req.body` with no type check. A body
  like `{"email": {"$gt": ""}, "password": "…"}` makes `findOne` match an
  arbitrary user, which enables account enumeration and password spraying
  against whichever account matches. In `signup`, `password.length` on a
  non-string throws or passes oddly.
- **Fix:** Reject any non-string `email` or `password` with 400. Enable
  `mongoose.set('sanitizeFilter', true)` globally. Validate email format.
- **Fixed (P12-22, 2026-09-30):** `readCredentials` returns 400 for any
  non-string or empty field before a query runs, and
  `sanitizeFilter` is on globally. The code's own filters use no
  `$`-operators; `$set` in updates is unaffected. Mocha tests cover
  operator objects as email and as password, and arrays and numbers.

### AUD-05 — No rate limiting on login (backend track)

- **Where:** `JobTrigger-Backend/routes/authRoutes.js`
- **What:** Unlimited password attempts are possible.
- **Fix:** Add `express-rate-limit` (new backend dependency, needs approval)
  on `/api/auth/*`: for example, 10 attempts per 15 minutes per IP plus a
  per-email key. Return 429 and handle it client-side as a
  `ServerFailure(429)` with clear copy.

- **Fixed (P12-24, 2026-09-30):** `express-rate-limit` (approved with the
  plan). Login allows 10 *failed* attempts per IP per 15 minutes
  (successful logins don't count, so a real user isn't locked out by
  guessing from the same IP); signup allows 5 per IP per hour. Both return
  429 with a JSON message and a `RateLimit` header, and both are
  configurable (`LOGIN_RATE_LIMIT`, `SIGNUP_RATE_LIMIT`, and `TRUST_PROXY`
  behind a proxy). The client maps `ServerFailure(429)` to "Too many
  attempts…".

### AUD-06 — Internal error messages leak to clients (backend track)

- **Where:** every controller: `res.status(500).json({ message: 'Server error', error: err.message })`
- **What:** Mongo and mongoose internals (collection names, validation
  internals, stack-derived text) reach the client.
- **Fix:** Add a central error handler that logs server-side and returns a
  generic body. Keep the specific 400 validation messages.
- **Fixed (P12-23, 2026-09-30):** `middleware/errorHandler.js`. Controllers
  pass unexpected errors to `next(err)`, and the handler logs them and
  returns `{"message": "Server error"}`. Malformed JSON returns 400,
  unknown routes a JSON 404, and mongoose `ValidationError` a 400 listing
  only the field names (controllers' own 400s keep their messages). Tests
  check that an internal error's text never reaches the body.

### AUD-07 — Vulnerable backend dependencies (backend track)

- **Where:** `JobTrigger-Backend/package-lock.json`
- **What:** `npm audit --omit=dev` reports `path-to-regexp` 8.0–8.3 (high,
  ReDoS: GHSA-j3q9-mxjg-w52f, GHSA-27v5-c462-wpq7), `mongoose` 9.0–9.7.1
  (moderate, prototype pollution: GHSA-664h-wqgq-64gw), `qs` ≤6.15.3
  (moderate, DoS), and one low.
- **Fix:** Run `npm audit fix`, re-run the tests, and add `npm audit
  --audit-level=high` to `nodejs-test.yml`.
- **Fixed (P12-20, 2026-09-30):** `npm audit fix` plus `mocha` 10 → 12 (a
  dev dependency; its `serialize-javascript` high advisory had no
  non-major fix). The full audit, dev dependencies included, went from 11
  findings (7 high) to 0, and the 58 mocha tests pass unchanged. CI now
  runs `npm audit --audit-level=high` after `npm ci`. Mocha 12 needs Node
  ^20.19 or >=22.12, which CI's 20.x matrix satisfies.

### AUD-08 — Trigger and Cancel have no confirmation step

- **Where:** `lib/presentation/features/job_detail/job_detail_screen.dart:117-127`
- **What:** US-JOB-02 ("Confirmation before triggering"), US-JOB-03, and
  US-JOB-05 ("Confirmation required") are **Must** acceptance criteria.
  Today one tap fires a real production build or abort. The input-step
  banner already confirms; trigger and cancel don't.
- **Fix:** Add a glass confirmation sheet (see US-DESIGN) before `trigger()`
  and `cancel()`, and show the parameter summary in the trigger
  confirmation. Add widget tests.

### AUD-09 — Duplicate `ValueKey`s in global history

- **Where:** `lib/domain/jenkins/history_entry.dart` (`id => '$jobName-${build.number}'`),
  `global_history_screen.dart:69`
- **What:** Two jobs with the same name in different folders (very common
  with multibranch, where every repo has `main`) produce equal keys whenever
  their build numbers match. Flutter throws a "Duplicate keys" assertion in
  debug and can reuse the wrong element state in release.
- **Fix:** Key by `build.url`, which is globally unique. Add a unit test with
  colliding names.

### AUD-10 — Stale folder breadcrumb

- **Where:** `lib/presentation/features/home/folder_breadcrumb_notifier.dart`
  (`reset()` has no callers), `filtered_jobs_provider.dart`
- **What:** The breadcrumb stores `JenkinsJob` snapshots, and
  `filteredJobs` shows `breadcrumb.last.jobs`, which is the snapshot's
  children and not the current tree. So (a) pull-to-refresh inside a folder
  keeps showing the old children, and (b) switching the active server while
  inside a folder keeps showing server A's folder under server B.
- **Fix:** Store folder URLs, resolve children from the current
  `jobTreeNotifierProvider` (or from the lazy per-folder fetch in P11-05),
  and reset when `activeServerNotifierProvider` changes. Add tests for both.

### AUD-11 — Non-Dio exceptions escape the data layer

- **Where:** `lib/data/repositories/jenkins_repository_impl.dart` (every
  `response.data!` and `Dto.fromJson`), `jenkins_url_rewriter.dart`
  (`Uri.parse`), `jenkins_client_factory.dart` (`testJenkinsConnection`).
  The same pattern exists in the GitHub and SonarQube repositories.
- **What:** Each method catches only `DioException`. An SSO or reverse proxy
  returning `200 text/html`, a plugin returning an unexpected shape, or a
  malformed server URL throws `TypeError`, `FormatException`, or
  `CheckedFromJsonException` straight through `Result`. That violates
  `CLAUDE.md` §5 ("never throw raw … past the data layer"). Notifiers then
  show `error.toString()` via `describeError`'s fallback, which also leaks
  internals (NFR-SEC-04).
- **Fix:** Add a shared `guardJenkins(() async {...})` helper that maps
  `DioException` to `AppFailure.fromDioException` and anything else to a new
  `UnexpectedResponseFailure` with user-safe copy ("The server returned
  something unexpected — is this a Jenkins URL?"). Apply it to every
  repository and add tests with HTML and garbage bodies.

### AUD-12 — Console log is O(n²) and unbounded

- **Where:** `lib/presentation/features/build_log/console_log_viewer.dart:57`,
  `build_log_notifier.dart:48`
- **What:** Each 1s poll concatenates the whole log string
  (`state.value + text`). Every rebuild, including each scroll-position
  toggle of `_autoScroll`, runs three regexes over the entire log and
  re-splits it. A 50k-line log does that full pass every second on the UI
  isolate, which is the likely cause of the jank P5-13 is meant to catch.
  Memory is unbounded.
- **Fix:** Keep an incremental `List<String>` of already-sanitized lines in
  the notifier, sanitize only the new chunk (carrying a partial trailing
  line and escape sequence), render from the list, and cap it in memory
  (for example the last 20k lines, with "load full log" via `consoleText`).
  Scheduled as P11-11.

### AUD-14 — Jenkins URL validation and cleartext transport

- **Where:** `lib/presentation/features/settings/server_edit_bottom_sheet.dart`
  (no validators; hint text is `http://localhost:8080`), platform configs
- **What:** Any string is accepted as a Jenkins URL. `http://` URLs send
  Basic Auth credentials (often a real password) in cleartext with no
  warning. Release Android (cleartext blocked by default since API 28) and
  iOS (ATS) block `http://` anyway, so users get a generic "Can't reach the
  server" with no explanation.
- **Fix:** Validate that the scheme is `http` or `https` and a host is
  present. Normalise trailing slashes. Show an explicit inline warning for
  `http://`. Map platform cleartext errors to a specific failure message.
  Decide (product decision) whether to allow LAN `http://` in release
  through `network_security_config` / `NSAllowsLocalNetworking`.

### AUD-15 — Release signed with the debug key

- **Where:** `JobTrigger-Frontend/android/app/build.gradle.kts:33`
- **What:** `signingConfig = signingConfigs.getByName("debug")` for
  `release`. Play Console rejects this, and anyone can re-sign an
  "update".
- **Fix:** Read a keystore from `key.properties` (git-ignored), falling back
  to debug only when that file is absent, with a loud Gradle warning. Link
  from `release-checklist.md`.
- **Fixed (P12-10, 2026-09-30):** done as described, and all three paths
  were verified. Without the file, the build succeeds debug-signed with a
  Gradle warning. With an incomplete file, it fails fast naming the
  missing field. With a complete file, `apksigner` showed the
  configured certificate (tested with a throwaway key, since deleted).
  Setup is in `docs/deployment.md`, linked from `release-checklist.md`.

### AUD-16 — CI doesn't run on the active branch

- **Where:** `.github/workflows/flutter-ci.yml`, `nodejs-test.yml`
  (`branches: [ develop, feature/** ]`)
- **What:** All work lands on `flutter-migration`, which matches neither
  pattern. Pushes there get no analyze or test gate.
- **Fix:** Add `flutter-migration` to the branch filters, or trigger on all
  pushes plus PRs to `develop`.

### AUD-17 — EOL Node runtime; container runs as root

- **Where:** `JobTrigger-Backend/Dockerfile` (`node:20-alpine`, no `USER`),
  `nodejs-test.yml` (`node-version: [20.x]`)
- **What:** Node 20 reached end-of-life on 2026-04-30 and gets no security
  patches. The container process runs as root.
- **Fix:** Move to Node 22 LTS or later in both places, add `USER node`, a
  `HEALTHCHECK`, and `NODE_ENV=production`.

## Medium

- **Fixed (P12-21, 2026-09-30):** `node:22-alpine`, `NODE_ENV=production`,
  `USER node` (the app only reads `/app`, so root keeps owning it), and a
  `HEALTHCHECK` on a new `GET /healthz`, which is 503 until MongoDB is
  connected (the old `/` route answers 200 even with the database down).
  CI runs Node 22.x. Verified by building the image: user `node`, Node
  v22.23, and no `.env` in the image. `/healthz` has 2 mocha tests.

### AUD-13 — Log poll error discards the displayed log

- **Where:** `build_log_notifier.dart:52` (`state = AsyncError(...)`)
- **What:** A single network blip during tailing replaces the whole visible
  log with a full-screen error. Retry creates a new notifier from offset 0.
- **Fix:** Keep the data, show an inline "Connection lost — retrying" banner,
  and back off and resume from `_offset` (P11-11).

### AUD-18 — Edited parameter values reset when scrolled away

- **Where:** `lib/presentation/features/job_detail/parameter_form.dart`,
  `job_detail_screen.dart:223` (a `ListView(children:)`)
- **What:** `ParameterForm` holds values in `State`. When the form scrolls
  beyond the cache extent it's disposed, and on return `initState` re-seeds
  the defaults and its post-frame `onChanged` overwrites the parent's
  edited map. The user then triggers with defaults they didn't choose.
- **Fix:** Lift parameter values into a `ParameterValuesNotifier` family
  keyed by job URL. The form reads and writes it, and the trigger reads it.
  This also removes form logic from the widget (P11-04).

### AUD-19 — Folders at the depth limit render as jobs

- **Where:** `jenkins_repository_impl.dart` (`buildJobTreeQuery`, 4 loop
  iterations giving 5 levels, while the doc comment says 6)
- **What:** At the deepest fetched level `jobs` isn't requested, so
  `isFolder` is false. Tapping such a folder opens job detail for a folder.
- **Fix:** Lazy per-folder loading (P11-05) removes the depth limit
  entirely. Until then, request `_class` and treat folder classes as
  folders.

### AUD-20 — Whole-tree fetch on every Home load

- **Where:** `fetchJobTree()`
- **What:** Five nested levels with `lastBuild` for every job come down in
  one request. On large instances that's multi-MB JSON that may exceed the
  15s receive timeout, plus a full-tree flatten per search keystroke.
- **Fix:** Fetch the root level only, load folders on demand, run search
  server-side via `/search/suggest` or a cached flattened index built in the
  background. Debounce search input (P11-05).

### AUD-21 — Artifact download buffers in memory

- **Where:** `fetchArtifactBytes`
- **What:** `ResponseType.bytes` holds the full file in memory under the
  shared 15s `receiveTimeout`. Large artifacts (APKs, zips) time out or risk
  OOM.
- **Fix:** Stream to a temp file with `dio.download`, a per-request timeout,
  progress, and a size warning above a threshold; share with
  `XFile(path)`. (Needs `path_provider` as a direct dependency; it's
  already transitive.)
- **Fixed (P12-08, 2026-09-30):** `fetchArtifactBytes` is replaced by
  `fetchArtifactSize` (`HEAD`, `Content-Length`, verified on the fixture)
  and `downloadArtifact` (`dio.download` to a per-download temp folder,
  with a 2-minute stall timeout and progress). Above 100 MB the user
  confirms first; an unknown size doesn't block. The row shows determinate
  progress, and the file is deleted once it's shared. The temp-directory
  and share providers moved to `core/platform/temp_files.dart`, shared
  with the full-log export.

### AUD-22 — App Info links silently no-op on Android 11+

- **Where:** `lib/presentation/features/app_info/app_info_screen.dart:106`
- **What:** Package visibility rules make `canLaunchUrl` return `false` for
  `https` and `mailto` unless the manifest declares matching `<queries>`,
  so the tap does nothing.
- **Fix:** Add `<queries>` intents for `VIEW https` and `SENDTO mailto`, and
  show a toast if launching still fails.
- **Fixed (P12-07, 2026-09-30):** `<queries>` for `VIEW https`, `VIEW http`
  (a LAN Jenkins' token page), and `SENDTO mailto`. Every external link
  now goes through `openExternalLink`. It tries `launchUrl` directly
  (a `canLaunchUrl` pre-check was part of the bug) and shows "Couldn't
  open link" when nothing handled it.

### AUD-23 — Credential updates skip validation (backend track)

- **Where:** all three `update*` controllers (`findByIdAndUpdate` without
  `runValidators`); `pre('save')` doesn't run on `findOneAndUpdate`
- **What:** `PUT` can blank required fields, and `updatedAt` is never
  refreshed.
- **Fix:** Use schema `{ timestamps: true }` and `runValidators: true`.
- **Fixed (P12-25, 2026-09-30):** both, in the shared controller. A PUT
  that blanks a required field is a 400 naming the field; fields the PUT
  leaves out are unchanged; `updatedAt` refreshes on update.

### AUD-24 — Ownership failures return 401; non-atomic default switch (backend track)

- **What:** Returning 401 (instead of 404) for another user's id confirms
  the id exists, and the client may treat 401 as "session expired". The
  "unset all then set one" default switch can leave two defaults under
  concurrent requests.
- **Fix:** Scope every query by `{ _id, userId }` and return 404 when
  nothing matches. Do the default switch with a transaction or a single
  `bulkWrite`.
- **Fixed (P12-25, 2026-09-30):** every lookup is `{ _id, userId }`, and
  another user's id is a 404 on update, delete, and switch. The nine
  ownership test assertions changed from 401 to 404 on purpose; every
  other existing test passes unchanged. The default switch is one ordered
  `bulkWrite` (unset all, set one), the audit's second option: no
  transaction, because the local and test MongoDB are standalone. Two
  switches racing from the same account could still interleave, and the
  next switch repairs that.

### AUD-25 — CORS, headers, and config fail-fast (backend track)

- **What:** `cors()` allows any origin (the only client is a mobile app).
  There are no security headers (`helmet`). A missing `JWT_SECRET` only
  surfaces as runtime 500s.
- **Fix:** Use an allow-list CORS origin from env (or disable it), add
  `helmet` (new dependency, needs approval), and validate required env at
  startup.
- **Fixed (P12-23, 2026-09-30):** `helmet` (approved with the plan, on
  2026-09-29). CORS is off unless `CORS_ORIGINS` lists origins. The server
  exits with `Missing required configuration: …` when `JWT_SECRET` or
  `MONGODB_URI` is missing or blank (verified: exit code 1).

### AUD-26 — Account security policy (backend track)

- **What:** The minimum password length is 6, email format isn't checked
  server-side, and a stolen 7-day JWT can't be revoked (no logout-all,
  no password-change invalidation).
- **Fix:** Require at least 8 characters with a breached-password check
  (optional), validate email, add a `tokenVersion` on `User` checked in
  `auth.js`, and shorten access-token life with a refresh flow. The client
  change follows the refresh contract.
- **Partly fixed (P12-22, 2026-09-30):** an 8-character minimum and a
  72-byte maximum (bcrypt truncates beyond that), plus a server-side email
  format check, all at signup only so existing accounts can still sign in.
  The client's `AuthValidation` uses the same pattern and minimum. The
  session half (`tokenVersion`, refresh) is P12-27.

### AUD-27 — Password build parameters shown in plaintext

- **Where:** `parameter_form.dart:94` (`default:` branch)
- **What:** `PasswordParameterDefinition` falls through to a visible
  `TextFormField` pre-filled with the default. Tracked and fixed as
  **P11-04**.

### AUD-37 — Duplicate parameterized trigger reported as a failure

- **Where:** `JenkinsRepositoryImpl.triggerBuild`
- **What:** When an identical parameterized build is already queued,
  Jenkins merges the request into it and answers `303 See Other`, with the
  existing queue item as `Location` (verified on the fixture Jenkins).
  Dart doesn't follow redirects for POST, and Dio only accepts 2xx, so the
  user saw "Something went wrong on the server (HTTP 303)" for a trigger
  Jenkins had accepted.
- **Fix (P11-04):** `followRedirects: false` and accept any status below
  400. The `Location` is still returned, so queue tracking follows the
  merged item.

### AUD-38 — Empty Run parameter makes Jenkins return 500

- **Where:** `parameter_form.dart` (a `RunParameterDefinition` falls
  through to a free-text field that starts empty)
- **What:** `buildWithParameters` with `BASE_BUILD=` (empty) returns HTTP
  500, verified on the fixture Jenkins. Triggering any job that declares a
  Run parameter, without typing a valid `job#number`, fails.
- **Fix (P11-06):** a blank Run parameter is **omitted**, and Jenkins then
  uses its default, the latest build (verified on the fixture). An optional
  picker lists the project's recent builds. This is better than the planned
  "disable Trigger until chosen", which would have blocked the most common
  case.

### AUD-39 — Cancelling a pipeline build reports failure

- **Where:** `JenkinsRepositoryImpl.cancelBuild`
- **What:** `POST {build}/stop` on a pipeline (`WorkflowRun`) answers
  `302 Found` back to the build page, verified on the fixture Jenkins.
  Dart doesn't follow redirects for POST, and Dio accepted only 2xx, so
  every pipeline cancel showed "Cancel failed (HTTP 302)" although the
  build had stopped. Freestyle builds, which the original manual test
  covered, return 200, which is why this was missed.
- **Fix (P11-13):** a shared `_acceptRedirects` status check for Jenkins
  POSTs (stop, trigger, scan), with a regression test.

### AUD-40 — The Android build fails at the AAR metadata check

- **Where:** `android/app/build.gradle.kts`
- **What:** `flutter build apk` failed in `:app:checkDebugAarMetadata`:
  `flutter_secure_storage` 11.0.0 declares `compileSdk = 37` and requires
  apps that use it to compile against 37, but the app used
  `flutter.compileSdkVersion` (36). Every Android build, debug or release,
  was blocked. It went unnoticed because work since then was verified with
  `flutter test`, the macOS target, and the fixture, none of which run
  Gradle.
- **Fix (P11-24):** `compileSdk = 37` explicitly (platform 37 is installed;
  AGP 9.0.1 builds it cleanly). `targetSdk` is unchanged, so runtime
  behaviour doesn't change. Revert to `flutter.compileSdkVersion` once
  Flutter's default reaches 37. A `flutter build apk --debug` step in CI
  would have caught this, so `flutter-ci.yml` now has a `build-android`
  job.

## Low

- **AUD-28 — Logout leaves per-user prefs:** `active_server_id`,
  `active_github_credential_id`, `active_sonarqube_credential_id`, theme,
  and "remembered email" survive logout. Fix: clear user-scoped keys in
  `AuthNotifier.logout()`. **Fixed (P12-09):** `clearUserScopedPrefs`
  also removes pins, saved views, and build watches (and the background
  check stops). The theme and other device preferences stay, and so does
  the remembered email, deliberately: "Remember me" is an explicit opt-in
  meant to survive signing out.
- **AUD-29 — Artifact state key collision:**
  `artifactDownloadNotifierProvider(artifact.relativePath)` is shared across
  builds and jobs. Fix: key by `'$buildUrl|$relativePath'`. **Fixed
  (P12-09):** the family takes `(buildUrl, relativePath)`, and there is a
  regression test.
- **AUD-30 — Hardcoded colors:** `Colors.blue` and `Colors.amber`
  (`job_detail_screen.dart:645-646`) and `Colors.orange` (`home_screen.dart`,
  folder tile) bypass `AppColors`, so dark-mode contrast is unchecked
  (NFR-A11Y-01). Fix: add `AppColors.buildRunning`, `buildPaused`, and
  `folder` tokens. **Fixed (P12-09):** those tokens, in shades measured at
  3:1 or better for icons (WCAG 1.4.11) on both light and dark surfaces;
  plain amber and orange measure 1.6 to 2.2:1 on light. **Follow-up:** the
  ported `buildUnstable` (`Colors.orange`) is also 2.06:1 on light, but
  it's a SwiftUI-parity color used across many screens, so changing it is
  left for a design decision rather than done silently.
- **AUD-31 — Duplicated backend controllers:** `credentialsController`,
  `githubCredentialsController`, and `sonarqubeCredentialsController` are
  copy-pastes. Fix: a `makeCredentialController(Model, fields)` factory,
  done with AUD-23/24 so the fixes land once. **Fixed (P12-25):**
  `controllers/credentialControllerFactory.js`. The three controllers are
  now 15-line configurations, and the routes are unchanged.
- **AUD-32 — Duplicated URL normalisation:** `base = url.endsWith('/') ? …`
  appears in 11 methods. Fix: an `_withSlash()` helper, folded into the
  AUD-11 `guard` refactor.
- **AUD-33 — Search UX:** results don't show which folder a job is in, and
  the empty state isn't inside a scrollable, so pull-to-refresh is
  impossible. Tracked by P11-06.
- **AUD-34 — Sanitizer edge cases:** CRLF logs keep `\r`, and an escape
  sequence split across two progressive-text chunks leaks. Tracked by
  P11-11.
- **AUD-35 — Doc drift:** `CLAUDE.md` §1 says the backend uses "JWT bearer",
  but it actually reads `x-auth-token` (see `backend_api_client.dart` doc
  comment). Fix: correct `CLAUDE.md` §1. **Fixed (P12-11):** also in
  `api-reference.md` §1 and `architecture.md` §2.
- **AUD-36 — Workspace leftovers:** 1.2 GB `JobTrigger-Frontend/build/`,
  `coverage/` in both packages, a stray `.DS_Store`, an unrelated
  `.github/modernize/java-upgrade/` tool directory (there is no Java in this
  repo), and an empty `JobTrigger-Backend/public/images/` that
  `server.js` never serves. All were untracked or git-ignored, so the removal
  (2026-09-29, alongside this audit) produces no commit diff. No tracked file
  was found to be unnecessary: the `macos/` target is the documented
  local-dev target (see `secure_storage_service.dart`), and the
  `RunnerTests` stubs are referenced by the Xcode projects.

## Out of scope / verified OK

- **Dependency hygiene — `workmanager` 0.10.10 writes a marker file.**
  `Workmanager.executeTask` writes `wm_execute_task_marker` (the text
  "executeTask called <timestamp>") to the system temp directory on every
  background run, apparently debugging code left in the release. It holds no
  app data and sits in the app's own sandbox, so it's not a leak. Re-check on
  the next `workmanager` upgrade (found 2026-09-30, P11-24).

- Jenkins CSRF crumb plus session cookie handling (`jenkins_client_factory.dart`)
  was reviewed and is correct, including the single-retry on 403.
- JWT storage uses `flutter_secure_storage` correctly. Only AUD-01's
  separate password key is wrong.
- Tracked `.env.example` was not opened, per `CLAUDE.md` §8.
