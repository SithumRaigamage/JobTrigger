# Backlog (explicitly out of scope for this migration)

These are ideas or extensions that came up while planning the migration but
are **not** part of reaching feature parity. Don't build these under a
Phase 0–6 task without first moving the item here into an actual phase file
— keeping them separate is what prevents the rewrite from scope-creeping.

- Real GitLab CI / CircleCI integrations (tool-selection cards for these
  stay disabled placeholders through v1). GitHub Actions was promoted out
  of this item 2026-09-14 — see `tasks/phase-8-github-actions.md` and
  `docs/user-stories/github-actions/12-github-actions.md`. GitLab CI,
  SonarQube, and CircleCI got their own epic docs on 2026-09-15 —
  `docs/user-stories/gitlab/13-gitlab-ci.md`,
  `docs/user-stories/sonarqube/14-sonarqube.md`,
  `docs/user-stories/circleci/15-circleci.md`. SonarQube was itself
  promoted out of this item 2026-09-15 — see `tasks/phase-10-sonarqube.md`.
  GitLab CI and CircleCI remain deferred here for actual implementation.
- **More CI/CD tools** (listed 2026-10-23 at the owner's request). Kept
  here, not in the app: the tool-selection screen shows only tools that
  work, plus a "Need another tool? Tell us" link that emails support, so
  requests decide what's built next. Each tool is its own epic
  (credentials, client, screens, tests) and joins `CiTool` only when built.
  Only tools with a remote API qualify; CLI-only tools come in their hosted
  or server form.
  - *CI and build:* GitLab CI, CircleCI, Azure DevOps Pipelines, Bitbucket
    Pipelines, TeamCity, Bamboo, Travis CI, Buildkite, Drone / Harness CI,
    Woodpecker CI, Concourse, GoCD, Semaphore, Codefresh, AWS CodeBuild /
    CodePipeline, Google Cloud Build, Gitea / Forgejo Actions, Tekton.
  - *Deployment and GitOps:* Argo CD, Argo Workflows / Rollouts, Flux,
    Spinnaker, Harness CD, Octopus Deploy, AWS CodeDeploy.
  - *Infrastructure as code:* HCP Terraform, Pulumi Cloud, Spacelift, env0,
    Scalr, Atlantis.
  - *Configuration and automation:* Ansible AWX / Automation Platform,
    Rundeck, Puppet Enterprise, Chef Automate, Salt.
  - *Containers and orchestration:* Kubernetes, OpenShift, Rancher, Nomad,
    Portainer, AWS ECS.
  - *Code quality and security:* SonarQube (backend credentials already
    exist), Snyk, Codecov, Coveralls, Checkmarx, Veracode, GitGuardian,
    Dependabot.
  - *Artifacts and registries:* JFrog Artifactory, Sonatype Nexus, Harbor,
    Docker Hub, GitHub Container Registry.
  - *Mobile CI and release:* Bitrise, Codemagic, Xcode Cloud, App Store
    Connect, Google Play Console, Firebase App Distribution.
  - *Monitoring and incidents:* Datadog, Grafana, Prometheus /
    Alertmanager, PagerDuty, Sentry.
- Push notifications for build completion/failure. *(Local, on-device
  notifications promoted 2026-09-29 → `phase-11-jenkins-extended.md`
  P11-24 / US-JX-10; true server push remains here.)*
- ~~Widget/home-screen extension for build status at a glance.~~ Promoted
  2026-09-29 → P11-26 / US-JX-23.
- Multi-account support (switching between multiple backend user accounts,
  not just multiple Jenkins servers).
- ~~Offline caching of the job tree for airplane-mode browsing.~~ Promoted
  2026-09-29 → P11-23 / US-JX-20.
- ~~Biometric unlock (Face ID / fingerprint) gating app access.~~ Promoted
  2026-09-29 → P11-25 / US-JX-21.
- Website "notify me when it launches" email signup (epic WEB, decided
  out of launch scope 2026-10-24). Needs a backend endpoint to store
  emails, rate limiting, an unsubscribe path, and a privacy-policy change
  (US-WEB-06) — backend track. Until then, "coming soon" copy on the site
  links to the changelog (US-WEB-22).
- Website launch date in the download section (epic WEB). The site says
  "Coming soon" with no date until a release date is committed in
  `release-checklist.md`; then flip the `app-store` status (US-WEB-22).
- Password reset by email (US-AUTH-08, from AUD-48 / P13-07). Deferred
  2026-10-23: the backend has no email provider, and choosing one is a
  product decision. Needs a provider, single-use 15-minute tokens, no
  account enumeration, and a `tokenVersion` bump on reset — see the story
  in `docs/user-stories/shared/01-authentication.md`.
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
- Android "share a Jenkins link into JobTrigger" (US-JX-19). Needs a
  share-intent plugin such as `receive_sharing_intent`, which isn't in
  `CLAUDE.md` §3. The `jobtrigger://` scheme covers the need (P11-22; its in-app paste
  action was removed in P19-06 — Home's "Open Jenkins link" now opens the
  server in the browser). Also: a deep link opened
  while signed out is dropped at login; resuming it after sign-in is a
  small follow-up.
