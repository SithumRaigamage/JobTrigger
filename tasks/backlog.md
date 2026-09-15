# Backlog (explicitly out of scope for this migration)

These are ideas or extensions that came up while planning the migration but
are **not** part of reaching feature parity. Don't build these under a
Phase 0–6 task without first moving the item here into an actual phase file
— keeping them separate is what prevents the rewrite from scope-creeping.

- Real GitLab CI / SonarQube / CircleCI integrations (tool-selection cards
  for these stay disabled placeholders through v1). GitHub Actions was
  promoted out of this item 2026-09-14 — see `tasks/phase-8-github-actions.md`
  and `docs/user-stories/github-actions/12-github-actions.md`. GitLab CI,
  SonarQube, and CircleCI got their own epic docs on 2026-09-15 —
  `docs/user-stories/gitlab/13-gitlab-ci.md`,
  `docs/user-stories/sonarqube/14-sonarqube.md`,
  `docs/user-stories/circleci/15-circleci.md` — but remain deferred here
  for actual implementation, same as GH was before 2026-09-14.
- Push notifications for build completion/failure.
- Widget/home-screen extension for build status at a glance.
- Multi-account support (switching between multiple backend user accounts,
  not just multiple Jenkins servers).
- Offline caching of the job tree for airplane-mode browsing.
- Biometric unlock (Face ID / fingerprint) gating app access.
- Crash reporting / analytics tool selection (flagged in P6-08 — pick a
  tool with the team before treating this as committed scope). Asked
  directly during Phase 6; user chose to skip for now rather than commit
  to Firebase Crashlytics or Sentry. Revisit before public release
  (P6-13).
- Backend rewrite or migration off MongoDB/Express — out of scope entirely;
  this migration only changes the client.
- Settings screen "Backend Server Status" live connectivity indicator
  (old `SettingsView.swift`'s online/offline health-check row) — no phase
  task names it; flagged during P6-03 rather than built silently.
