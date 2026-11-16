# JobTrigger — Improvement Plan

Written 2026-11-14. Covers the whole product: the Flutter app
(`JobTrigger-Frontend`), the website and setup portal (`JobTrigger-Web`) and
the backend (`JobTrigger-Backend`). The website and the app are both primary:
people set up their servers on the web and use them on the phone.

No new CI tools are in this plan except under "Later". The epic docs for
them already exist (`docs/user-stories/`).

Every "Already done" line below was checked against the code on 2026-11-14,
not only against the task files. Where an earlier summary was wrong, the
correction is noted.

**Status 2026-11-16: every developer-actionable item in this plan is built.**
That is the unified dashboard (NR-02), log section folding (NR-01), QR-code
pairing (NR-03) and the website's analytics events (P20-30/NR-05), on top of
the Emergency work and the error copy that were already in place. What is
left cannot be done from the codebase alone: store and RevenueCat accounts
(P20-40..42), APNs/FCM for server push, the real values for
`site-details.ts`, and the production deploy. Each line says which. Tracker:
`tasks/phase-22-next-release.md`.

## Already done

Checked in the code, not only in the task files.

**App (Flutter)**
- Jenkins, complete and frozen (`CLAUDE.md` §11): job tree, parameters,
  trigger, live status, cancel, logs, history, pipeline stages, input
  approval, tests, artifacts, replay, queue, nodes (Phases 4–7, 11).
- On-device notifications when a watched build finishes
  (`presentation/features/notifications/`, `workmanager`,
  `flutter_local_notifications`; US-JX-10).
- Pinned jobs and a home-screen widget, on both iOS (`ios/PinnedJobsWidget`)
  and Android (`presentation/features/home_widget/`; US-JX-23).
- Deep links (`presentation/features/open_link/`; US-JX-19). Android's
  "share a Jenkins link into the app" is still in `tasks/backlog.md`.
- Biometric app lock (`presentation/features/app_lock/`; US-JX-21).
- Offline job tree cache (US-JX-20), console search and colours, test
  details, build trends (Phase 11).
- **GitHub Actions is built, not half-built.** It is enabled on the
  tool-selection screen (`CiTool.isAvailable` includes `githubActions`),
  with credentials, repositories, runs, trigger, live status, cancel,
  jobs and steps, job logs, per-workflow history and the cross-repo feed
  (P8-00..25). *Correction: an earlier summary called these screens
  unfinished. What is left is verification, not building (see Emergency
  E5).*
- SonarQube: credentials, projects, quality gate, measures, issues,
  analysis history (P10-00..13, P10-16).
- New design system (Phase 14) and the iPhone fixes from real testing
  (Phase 19).

**Website and portal (Next.js)**
- Marketing pages, sign-up and sign-in, and the setup portal for Jenkins,
  GitHub and SonarQube credentials (Phase 15). Saved secrets show only as
  `••••` plus the last four characters (`domain/mask.ts`).
- Password reset by email, web only (P20-73, P20-74).
- Privacy, terms, security and support pages (P15-10), including the
  anonymous analytics section (P20-79). *Note: the pages exist, but they
  still show placeholders. See Emergency E1.*

**Backend**
- **Credential encryption at rest is already done.** AES-256-GCM, key from
  the environment (`CREDENTIALS_ENCRYPTION_KEY`), key ids for rotation,
  the field name bound in so a secret can't be moved to another field, a
  backfill/rotation script (`scripts/encrypt-credentials.js`) and a startup
  audit for unreadable key ids (AUD-03, AUD-63). Applied to Jenkins
  `password` and `paramToken`, the GitHub `token` and the SonarQube `token`.
  *Correction: an earlier summary called this the top emergency. It isn't
  missing; what's left is the production setup and one hardening question
  (Emergency E4).*
- Logging rules that forbid secrets in logs (`lib/logger.js`), plus
  `security/secretMaterialScan.js`.
- Two security audits, all findings fixed (Phases 12 and 13).

## Planned but not built

- **Subscriptions (Phase 20)** — the app's paywall, subscription screen,
  gates and billing client are built (P20-20..27, P20-84), the backend has
  plans, limits, RevenueCat and Paddle webhooks, the mailer and analytics,
  and the site has plans, pricing, billing and the student plan. What is
  left is store and RevenueCat setup (P20-40..42, owner) and the sandbox and
  production passes (P20-51..63).
- **Website go-live** — the portal works, but it needs the backend deployed
  at a public `https://` address (P15-22), Vercel connected, the real values
  in `site-details.ts` (PE-03), and the store links (P15-24).
- **Server push notifications** (BACKLOG-02) — only on-device notifications
  exist.
- **Store release** — icons and screenshots, TestFlight / Play internal
  testing, dogfooding, public release (`tasks/release-checklist.md`).

## Emergency (now, before release)

The full plans are in `tasks/phase-emergency.md`. In order of risk to the
release:

1. **E1 Privacy policy is not usable yet.** The app's "Privacy policy" link
   comes from the backend seed, which is `https://example.com/privacy`.
   The website page still shows `[COMPANY NAME]`, `[PRIVACY EMAIL]` and
   `[DATE]`. Both app stores require a working privacy URL.
2. **E2 No demo mode.** App Review (and any new user) can't try the app
   without their own Jenkins server that the phone can reach. That is a
   likely store rejection.
3. **E3 No crash or error reporting** in the app, website or backend. It
   was skipped on purpose in Phase 6 "until before public release". That
   point is now.
4. **E4 Credential encryption: production setup and one hardening step.**
   The code is done. Left: the production key in a secret manager, the
   backfill on the production database, and not sending every decrypted
   secret in credential *list* responses.
5. **E5 GitHub Actions: verify, don't hide.** Finish the remaining checks
   (P8-20 tests, P8-26 auth isolation, P8-27 full test pass with a real
   token) so it can ship as a supported tool.

*(2026-11-16: all five are dev-complete. What each still needs is an owner
step — E1's real values in `site-details.ts` (PE-03), E3's GlitchTip DSNs
(PE-19c), E4's production key and backfill (PE-30/31), E5's real-token
checks (PE-41/42) and the App Review account (PE-18). Detail in
`tasks/phase-emergency.md`.)*

## Next release

- A unified home dashboard: failing builds, running jobs and pinned items
  across Jenkins, GitHub Actions and SonarQube on one screen.
  *(Done 2026-11-16 — NR-02, `tasks/phase-22-next-release.md`.)*
- "Jump to first error" in logs, and folding of noisy log sections.
  *(Folding done 2026-11-16 (NR-01, `tasks/phase-22-next-release.md`); jump
  to first error was already built.)*
- Subscriptions in the app (finish Phase 20). *(App and site built; left:
  store/RevenueCat setup and the sandbox passes, all owner actions. Site
  analytics events done 2026-11-16, P20-30.)*
- Website go-live (P15-22, P15-24).
- Server push notifications for failures and approvals (BACKLOG-02).
  *(2026-11-16 — NR-06: the backend half is built and tested (device
  registry, FCM HTTP v1 sender, no-op without credentials). Left, in
  `tasks/phase-22-next-release.md` NR-06b: the Firebase project and its
  keys (owner), the app's token upload and permission prompt (a new package
  and Firebase config files, needing approval), and a server-side trigger
  — which means the backend polling Jenkins, a deliberate architecture
  change. On-device notifications remain the only ones until then.)*
- QR-code pairing between the website and the app, so nobody types a
  server URL on a phone. *(Done 2026-11-16 — NR-03: a code per saved Jenkins
  server on `/servers`, opened by the phone's own camera app; no camera
  package needed.)*
- Clearer error copy for a bad token, an unreachable server and an expired
  session, in both the app and the portal. *(Checked 2026-11-16: already
  built in both; re-check on the iPhone before closing.)*

## Later

- Team workspaces: shared servers and roles (needs a backend data-model
  change).
- AI summaries of why a build failed.
- Flaky-test detection.
- iPad layout, Apple Watch alerts, localisation.
- An audit log of who triggered what.
- Multi-account support (`tasks/backlog.md`).
- New tools, each from its epic doc: GitLab CI, CircleCI, Azure DevOps,
  Argo CD, Bitrise, Codemagic.

More proposals (2026-11-16, none promoted): 164 tools and their order in
`docs/future-tools.md` (T-001…164), product improvements in
`docs/product-improvements.md` (IMP-01…156), community ideas in
`docs/community-plan.md` (COM-01…157).
