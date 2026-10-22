# Phase 13 — Second Audit Remediation (Epic AUDIT-2)

Goal: close every finding in the second workspace audit — `AUD-42` …
`AUD-66`, plus the unnumbered §11/§13/§14/§16/§19 items. The findings
were recorded in `docs/audit/2026-10-20-workspace-audit.md` and
re-verified in `docs/audit/2026-10-22-workspace-audit.md`.

The 2026-10-20 document is **deleted**: every finding in it is closed,
and the 2026-10-22 document carries the status of record. This file is
the tracker of record for the work.

Approved 2026-10-20: the user asked for every finding to be fixed on one
branch (`feature/audit-2026-10-20-remediation`), committed and pushed one
by one. The audit's "Recommended fix" sections are the plan; backend-track
items are covered by that explicit request (`CLAUDE.md` §7, NFR-SEC-05).
Commits reference both ids, e.g. `fix(app): … [P13-04][AUD-45]`.

**Definition of done (new, from AUD-42):** a task is `done` only when CI
is green on the commit that closes it, not just a local run.

## Gates and configuration

- [x] P13-01 **AUD-42.** Stop tests from reaching the real `workmanager`
      plugin (shared fake scheduler in the test harness), so Flutter CI is
      green on Linux.
- [x] P13-02 **AUD-43.** Release builds refuse to start without an `https`
      `BACKEND_BASE_URL`; `cd.yml` and `docs/deployment.md` pass
      `--dart-define-from-file=config/prod.json`.
- [x] P13-03 **AUD-44 (backend).** `npm audit fix`; `TRUST_PROXY` accepts
      only a positive hop count, otherwise the server refuses to start.

## Security and correctness

- [x] P13-04 **AUD-45.** Notification taps carry the watch's server and go
      through the open-link confirm-and-switch flow; the Jenkins client
      refuses requests to any host but its own.
- [x] P13-05 **AUD-46.** Editing the active Jenkins server, GitHub
      credential, or SonarQube credential takes effect immediately.
- [x] P13-06 **AUD-47 (client + backend).** Only a 401 from `/refresh`
      ends a session; the refresh limiter is keyed by user, not IP.
- [x] P13-07 **AUD-48 (client + backend).** Delete account (cascade) and
      change password (bumps `tokenVersion`). Password *reset* needs an
      email provider — a product decision — and stays open as US-AUTH-08.
- [x] P13-08 **AUD-49.** Build-watch checks never overlap and merge by key,
      so a watch added or removed mid-check isn't lost or resurrected.
- [x] P13-09 **AUD-50.** Artifact file names are reduced to a safe basename.
- [x] P13-10 **AUD-51.** Routes that need an `extra` redirect to Home when
      opened without one; the router has an error screen.
- [x] P13-11 **AUD-52.** SonarQube base URLs get the same validation and
      `http://` warning as Jenkins URLs.
- [x] P13-12 **AUD-53.** Turning off the app lock or the sensitive-action
      re-prompt requires authenticating first.
- [x] P13-13 **AUD-54.** With the app lock on, the home-screen widget and
      build notifications don't show job names.
- [x] P13-14 **AUD-55 (backend).** Constant-work login for unknown emails;
      per-email failed-login limit.
- [x] P13-15 **AUD-56.** iOS privacy manifests for the app and the widget.
- [x] P13-16 **AUD-57.** iOS debug build (no codesign) in push CI.
- [x] P13-17 **AUD-58 (backend).** The seed script refuses non-local
      databases unless explicitly forced.
- [x] P13-18 **AUD-59.** Pipeline controls: workflow `permissions`, pinned
      actions, secret scan, pub SCA, generated-code drift check, image scan.
- [x] P13-19 **AUD-61.** Reconcile status documents.
- [x] P13-20 **AUD-62.** Accessibility guideline tests on the main screens;
      a light-mode unstable color that meets 3:1.
- [x] P13-21 **AUD-63 (backend).** One undecryptable credential no longer
      fails the whole list.
- [x] P13-22 **AUD-64 + §16.** Hygiene: debug log headers off, archive
      `migrate.js`, backup exclusions, trigger re-entrancy guard, stop log
      polling a deleted build, bind local Mongo to `127.0.0.1`.
- [x] P13-23 **§13 (backend).** `userId` indexes on credential collections.
- [x] P13-24 **§11.** `core/network` no longer imports `presentation`.
- [x] P13-25 **§14.** Lean pinned-job status query.
- [x] P13-26 **§19 (backend).** Request ids and structured error logs.
- [x] P13-27 **AUD-66.** The repository carries no credential material: a
      token-shaped value in the tree is a failing test, and the reviewed
      fixtures live in `.secret-material-allowlist`.

## Not code (tracked, not done here)

- **AUD-66, owner action: revoke the Jenkins API token.** A local Jenkins
  API token from the SwiftUI era was committed to this repository's public
  history, and a second one appeared in a curl example that has since been
  deleted. The files are gone from the tree and the history is not
  rewritten, so the token has to be revoked in the Jenkins itself — in
  that Jenkins's user settings, not here. The repository-side guard
  (P13-27) prevents a recurrence; it cannot un-leak what was published.
  Until the token is revoked, treat it as live.
- Branch protection on `develop` / `flutter-migration` (repository setting,
  owner action).
- Domain ownership of `jobtrigger.app` / `jobtrigger.dev` (verify before
  any release; `release-checklist.md`).
- Crash-reporting choice (BACKLOG-07).
- AUD-60 (staged blank plugin registrant): fixed in the index on
  2026-10-20; nothing to commit.
