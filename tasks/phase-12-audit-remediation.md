# Phase 12 — Audit Remediation (Epic AUDIT)

Goal: close every finding in `docs/audit/2026-09-29-workspace-audit.md`.
The audit document is the **tracker of record**: when a task here lands,
update the matching `AUD-##` status there (with the commit) in the same
change.

Same cadence as every other phase: plan, approval, implementation, review
(`CLAUDE.md` §9). Commits reference both ids, e.g.
`fix(frontend): stop persisting login password [P12-01][AUD-01]`.

**Recommended scheduling:** P12-01 … P12-05 are small, serious, and
frontend-only (two of them Critical). Do them **before** starting Phase 11
Part C. P12-04 is also a prerequisite for Phase 11, since every new
repository method uses its guard.

## Delivered by Phase 11 (not duplicated here)

AUD-08 (P11-04), AUD-10 (P11-05), AUD-12 (P11-11), AUD-13 (P11-11), AUD-18
(P11-04), AUD-19 (P11-05), AUD-20 (P11-05), AUD-27 (P11-04), AUD-33
(P11-10), and AUD-34 (P11-11).

## Frontend and tooling

- [x] P12-01 **AUD-01 (Critical).** Stop persisting the login password.
      Remember only the email, clear saved values when "Remember me" is
      unchecked, and delete the legacy `login_saved_password` key on
      startup. Move the logic from `LoginScreen` into a notifier with
      tests.
- [x] P12-02 **AUD-02 (Critical).** Declare `INTERNET` in the main Android
      manifest, and add a CI step asserting the permission in the release
      manifest.
- [x] P12-03 **AUD-16.** Run CI on `flutter-migration` (and on all PRs to
      `develop`).
- [x] P12-04 **AUD-11 and AUD-32.** Add a shared repository guard mapping
      `DioException` to `fromDioException` and any other exception to a new
      `UnexpectedResponseFailure` (user-safe copy). Apply it to the
      Jenkins, GitHub, and SonarQube repositories and to
      `testJenkinsConnection`. Add a `_withSlash` helper. Tests cover an
      HTML 200 body, a malformed JSON shape, and a malformed server URL.
- [x] P12-05 **AUD-09.** Key history rows by build URL. Add a test for
      colliding job names.
- [ ] P12-06 **AUD-14.** Jenkins URL validation (scheme and host,
      normalised), an inline `http://` warning, and a specific message for
      platform cleartext blocks. **Product decision needed:** allow LAN
      `http://` in release builds (Android network security config and iOS
      `NSAllowsLocalNetworking`) or HTTPS-only.
- [x] P12-07 **AUD-22.** Add Android `<queries>` for `https` and `mailto`,
      and show a toast when a link can't be opened.
      *Done 2026-09-30:* also `http`, since a LAN Jenkins' token page is
      often plain HTTP. `LinkLauncher` (`core/platform`, overridable) and
      `openExternalLink` are used by App Info and the server sheet's "Create
      an API token" link. Covered by 3 widget tests.
- [x] P12-08 **AUD-21.** Stream artifacts to a temp file with a per-request
      timeout, progress, and a size warning; share via `XFile`. **Needs
      `path_provider` as a direct dependency** (shared approval with
      P11-23). *Done 2026-09-30:* `HEAD` for the size, then `dio.download`
      with progress; confirmation above 100 MB; the temp file is deleted
      after sharing. Details are in the audit entry. 11 tests (6
      repository, 5 notifier).
- [x] P12-09 **AUD-28, AUD-29, AUD-30.** Clear user-scoped prefs on logout,
      key artifact state by build and path, and replace hardcoded colors
      with `AppColors` tokens. *Done 2026-09-30:* `clearUserScopedPrefs`
      (`data/cache`) runs on logout. It keeps device preferences and the
      opt-in remembered email, and invalidates build watches, which stops
      the background check. `artifactDownloadNotifierProvider(buildUrl,
      relativePath)`. The `buildRunning`, `buildPaused`, and `folder`
      tokens are contrast-checked. The `buildUnstable` contrast is noted
      in the audit as a design follow-up.
- [x] P12-10 **AUD-15.** Release signing read from a git-ignored
      `key.properties`, falling back to debug with a Gradle warning.
      Document it in `docs/deployment.md`. *Done 2026-09-30:* plus a
      fail-fast on an incomplete file. All three paths were verified
      (details in the audit entry).
- [x] P12-11 **AUD-35.** Correct `CLAUDE.md` §1's backend auth description
      (`x-auth-token`, not bearer). *Done 2026-09-30,* along with the same
      drift in `api-reference.md` §1 and `architecture.md` §2.

## Backend track

These change `JobTrigger-Backend/`. Per `CLAUDE.md` §7 and `NFR-SEC-05`,
**each needs explicit approval** before work starts, even though this phase
file lists them.

- [x] P12-20 **AUD-07.** `npm audit fix`, and an
      `npm audit --audit-level=high` gate in `nodejs-test.yml`.
      *Done 2026-09-30:* 11 findings to 0 (`mocha` 12 for the dev-only
      high), tests unchanged and passing, with the CI gate added.
- [x] P12-21 **AUD-17.** Node 22 LTS or later in the Dockerfile and CI;
      container runs as `USER node`, with `NODE_ENV=production` and a
      `HEALTHCHECK`. *Done 2026-09-30:* the health check uses a new
      DB-aware `GET /healthz`. Verified on a local image build.
- [x] P12-22 **AUD-04** plus the validation part of AUD-26. Reject
      non-string auth fields, `mongoose.set('sanitizeFilter', true)`,
      server-side email format check, and a minimum password length of 8
      (the client validation in `auth_validation.dart` is updated to
      match). *Done 2026-09-30:* also a 72-byte maximum (bcrypt), and
      emails trimmed and lower-cased before lookup. Format and length rules
      apply only at signup, so older accounts can still log in. 7 new
      mocha tests (67 passing); the "at least 6" test moves to 8 with the
      policy.
- [x] P12-23 **AUD-06 and AUD-25.** A central error handler (log
      server-side, return a generic body), a CORS allow-list from env,
      `helmet` (**new backend dependency**), and fail-fast on missing
      `JWT_SECRET` or `MONGODB_URI`. *Done 2026-09-30:* plus JSON 404s and
      a 400 for malformed JSON. `CORS_ORIGINS` is documented in
      `dev-setup.md`. 8 new mocha tests (75 passing).
- [x] P12-24 **AUD-05.** `express-rate-limit` (**new backend dependency**)
      on `/api/auth/*`, returning 429. The client shows specific copy for
      `ServerFailure(429)`. *Done 2026-09-30:* the login limiter counts
      failures only. Limits and `TRUST_PROXY` come from env (documented
      in `dev-setup.md`). 2 mocha tests with a small probe limiter, and 2
      client tests.
- [x] P12-25 **AUD-23, AUD-24, AUD-31.** A credential-controller factory
      shared by the Jenkins, GitHub, and SonarQube controllers:
      `{ timestamps: true }`, `runValidators`, `{ _id, userId }`-scoped
      queries returning 404, and an atomic default switch. The existing
      mocha tests must pass unchanged, plus new tests for each fix.
      *Done 2026-09-30:* all existing tests pass unchanged except the
      nine ownership assertions, which moved from 401 to 404 as AUD-24
      requires. 15 new tests (5 behaviours × 3 routes); 92 passing.
- [x] P12-26 **AUD-03 (Critical).** AES-256-GCM field encryption for tool
      secrets (key from `CREDENTIALS_ENCRYPTION_KEY`, with a key-id prefix
      for rotation), a migration script for existing rows, and docs in
      `deployment.md` and `database-migrations.md`. The API contract to the
      client is unchanged.
      *Done 2026-09-30 (approved that day):* details in the audit entry.
      100 mocha tests pass. **Deploy note:** every environment, including
      local `.env` files, needs `CREDENTIALS_ENCRYPTION_KEY` before the
      server will start, then one `npm run encrypt-credentials` run.
- [ ] P12-27 **AUD-26 session hardening.** `tokenVersion` on `User`
      (logout-all and password-change revocation), and a shorter access
      token with a refresh endpoint. **Contract change:** needs a matching
      client task in the backend client and `AuthNotifier`, planned
      together.
