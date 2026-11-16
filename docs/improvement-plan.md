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

- **Subscriptions (Phase 20)** — in progress on `feat/subscription-billing`:
  26 of 57 tasks done (plans, limits, RevenueCat and Paddle webhooks,
  mailer, analytics). The app's paywall and purchase screens are not built.
  *The tracker in `tasks/README.md` still says "todo, waiting for approval",
  but P20-00 was approved on 2026-11-12. Update it when the branch merges.*
- **Website go-live** — the portal works, but it needs the backend deployed
  at a public `https://` address (P15-22), Vercel connected, and the store
  links (P15-24).
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

## Next release

- A unified home dashboard: failing builds, running jobs and pinned items
  across Jenkins, GitHub Actions and SonarQube on one screen.
- "Jump to first error" in logs, and folding of noisy log sections.
- Subscriptions in the app (finish Phase 20).
- Website go-live (P15-22, P15-24).
- Server push notifications for failures and approvals (BACKLOG-02).
- QR-code pairing between the website and the app, so nobody types a
  server URL on a phone.
- Clearer error copy for a bad token, an unreachable server and an expired
  session, in both the app and the portal.

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
