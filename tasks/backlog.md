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
  - *Code quality and security:* SonarQube (integrated, see
    `tasks/phase-10-sonarqube.md`), Snyk, Codecov, Coveralls, Checkmarx, Veracode, GitGuardian,
    Dependabot.
  - *Artifacts and registries:* JFrog Artifactory, Sonatype Nexus, Harbor,
    Docker Hub, GitHub Container Registry.
  - *Mobile CI and release:* Bitrise, Codemagic, Xcode Cloud, App Store
    Connect, Google Play Console, Firebase App Distribution.
  - *Monitoring and incidents:* Datadog, Grafana, Prometheus /
    Alertmanager, PagerDuty, Sentry.
  - *Added 2026-11-16* (details, release order and tools not to add:
    `docs/future-tools.md`):
    - *Deploy and hosting:* Vercel, Netlify, Render, Railway, Fly.io,
      Heroku, Cloudflare Pages / Workers Builds, DigitalOcean App
      Platform, AWS Amplify Hosting, Coolify, Dokploy.
    - *Mobile:* Expo EAS, Appcircle, Firebase Test Lab.
    - *Security:* OWASP Dependency-Track, DefectDojo, Semgrep AppSec
      Platform, GitHub code scanning / secret scanning, Trivy Operator.
    - *Testing services:* BrowserStack, Sauce Labs, Cypress Cloud,
      Allure TestOps / ReportPortal.
    - *Feature flags:* LaunchDarkly, Unleash, Flagsmith, GrowthBook.
    - *Uptime and incidents:* GlitchTip, Uptime Kuma, UptimeRobot,
      Better Stack, incident.io, Atlassian Statuspage, New Relic.
    - *Issue tracking (build actions):* Jira, Linear, GitHub Issues.
    - *Data and ML pipelines:* Apache Airflow, Dagster+, Prefect Cloud,
      Kubeflow Pipelines.
    - *Registries and platform:* AWS ECR, Google Artifact Registry,
      Quay.io, Backstage.
    - *Workflow automation:* n8n.
    - *Second batch:* AppVeyor, Buddy, Dagger Cloud, Depot, Gradle
      Develocity, BuildBuddy, Nx Cloud, Unity Build Automation, Google
      Cloud Run, Google Cloud Deploy, AWS CloudFormation, AWS Elastic
      Beanstalk, Firebase Hosting, Kargo, Flagger, Statsig, ConfigCat,
      PostHog, Mend, Aikido Security, Socket, JFrog Xray, Wiz, Cortex
      Cloud, HashiCorp Vault (health only), Infisical (sync status only),
      Cloudsmith, Azure Container Registry, Chromatic, Percy, LambdaTest,
      Currents, Grafana Cloud k6, Lighthouse CI server, Splunk On-Call,
      Grafana Cloud IRM, Dynatrace, Honeycomb, Elastic Observability,
      Zabbix, Checkly, Healthchecks.io, Cronitor, Jira Service
      Management, ServiceNow change approvals, dbt Cloud, Databricks
      Jobs, Temporal Cloud, Weights & Biases.
    - Full numbered catalogue of all 164 tools: `docs/future-tools.md` §7.
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
- ~~Password reset by email (US-AUTH-08, from AUD-48 / P13-07).~~
  Promoted 2026-11-12 → `phase-20-subscriptions.md` P20-72..74 (Mailpit in
  development; production provider when the backend deploys). Original
  note: deferred 2026-10-23: the backend has no email provider, and
  choosing one is a product decision. Needs a provider, single-use 15-minute tokens, no
  account enumeration, and a `tokenVersion` bump on reset — see the story
  in `docs/user-stories/shared/01-authentication.md`.
- Crash reporting / analytics tool selection (flagged in P6-08 — pick a
  tool with the team before treating this as committed scope). Asked
  directly during Phase 6; user chose to skip for now rather than commit
  to Firebase Crashlytics or Sentry. Revisit before public release
  (P6-13).
  **Done 2026-11-14 as Phase Emergency E3** (GlitchTip; `docs/error-reporting.md`).
- Backend rewrite or migration off MongoDB/Express — out of scope entirely;
  this migration only changes the client.
- Settings screen "Backend Server Status" live connectivity indicator
  (old `SettingsView.swift`'s online/offline health-check row) — no phase
  task names it; flagged during P6-03 rather than built silently.
- Android "share a Jenkins link into JobTrigger" (US-JX-19). Needs a
  share-intent plugin such as `receive_sharing_intent`, which isn't in
  `CLAUDE.md` §3. The `jobtrigger://` scheme covers the need (P11-22; its in-app paste
  action was removed in P19-06 — Home's "Open Jenkins link" now opens the
  server in the browser). ~~Also: a deep link opened while signed out is
  dropped at login.~~ **Fixed 2026-11-17:** `app_router.dart`'s `redirect`
  keeps the blocked location and restores it the moment sign-in completes,
  so a pairing code scanned on a fresh install lands on the pairing sheet;
  `test/presentation/navigation/app_router_test.dart` covers it.

## Owner actions waiting (added 2026-11-16)

Not product scope: steps only the owner can do (accounts, tokens, a real
device, legal details) or that wait for the deployment. Each points at the
task it unblocks; tick the task there, not here.

**Now (development can't close without them)**
- GlitchTip: create the organization, a team and the projects
  `jobtrigger-app`, `jobtrigger-web`, `jobtrigger-backend` at
  http://localhost:3005 (lab `custom-devops-stack`, bound to the Wi-Fi address
  since 2026-11-16), and hand the DSNs to the app config and the web/backend
  `.env` files. Unblocks PE-19c/19d and delivery of every crash report (E3).
- GitHub: a fine-grained token on one test repo (read + Actions write) for
  the live checks P8-26/P8-27 = PE-41/PE-42. Closes Phase 8 and the emergency
  phase.
- SonarQube: a user token from the lab SonarQube (My Account → Security),
  added in the app against `http://<Mac Wi-Fi address>:9000`, then the
  P10-14 session check and the P10-15 real-server pass on the iPhone.
- iPhone: install the PE-06/PE-27 build with `scripts/run-on-iphone.sh`
  (the build passed with no phone attached; the install is unverified).
- App Store Connect / Play Console: enter the privacy and Data safety
  answers recorded in `release-checklist.md` (PE-27).

**At release (after all development; deployment is on hold)**
- Backend on Render: `docs/deployment-render.md` RD-01..RD-11, including the
  production key and backfill (PE-30/PE-31).
- Production crash reporting host (hosted GlitchTip or self-hosted), and its
  DSNs.
- Legal details in `JobTrigger-Web/src/content/site-details.ts` and legal
  review of the privacy policy and terms (PE-03, PE-04).
- App Review account and the "in-app demo needs no account" line in the
  store descriptions (PE-18); store accounts, artwork, TestFlight and Play
  testing (`release-checklist.md`); store links on the website (P15-24).
- Billing setup: App Store Connect and Play payments, RevenueCat, Paddle
  (P20-40..42, P20-85), then the sandbox passes (P20-51/52).

## Owner actions waiting: subscriptions and releases (added 2026-11-16)

Things only the owner can do; the code around them is done or deliberately
left alone.

- **Android build unverified until the NDK is reinstalled** (noted
  2026-11-16). The Android NDK 28.2.13676358 install was interrupted by a
  slow connection and the owner will reinstall it on a fast one. Until then,
  no Android build or run of the subscription work (P20-20..P20-27,
  including `purchases_flutter`) has been done; treat it as unverified.
- **Native home-screen widget "Upgrade to Pro" copy** — **written
  2026-11-17, unverified on a device.** On Free with billing on, the app
  writes an `upgradeRequired: true` snapshot with no jobs (P20-25); the iOS
  widget (`UpgradeView` in `ios/PinnedJobsWidget/PinnedJobsWidget.swift`)
  and the Android one (`R.id.widget_upgrade` in
  `PinnedJobsWidgetProvider.kt`, its layout and strings) now say "Upgrade to
  Pro — Pinned jobs need Pro. Open JobTrigger to upgrade." instead of their
  empty state. Still to check: add the widget on an iPhone after flipping a
  build to Free (`scripts/run-on-iphone.sh`), and on Android once the NDK is
  reinstalled. Do before enabling billing for users.
- **Paddle sandbox and CSP hosts** (P20-85, noted 2026-11-16). The billing
  page, its CSP allowance and the checkout/portal calls are built against
  Paddle's documented hosts but have never run against a real sandbox. After
  the first sandbox checkout, check the console for CSP violations and adjust
  `paddleHosts` in `JobTrigger-Web/src/security-headers.ts` if needed. Needs
  the owner's Paddle sandbox account and `PADDLE_CLIENT_TOKEN`.
- **Real RevenueCat/store checks** (P20-40..42, P20-51, noted 2026-11-16).
  The paywall, purchase, restore and downgrade locking have only run against
  fakes. Needs RevenueCat keys, store products and sandbox testers, then a
  pass on the iPhone (`scripts/run-on-iphone.sh`); Android needs the NDK and
  a device (see above).


## Owner to-dos for the 1.0 go-live (added 2026-11-21)

Still open after PRs #154–#157 were merged into `develop` on 2026-11-21. An
agent can't do any of these: each one needs an owner account, a secret or
a real value. The steps live in the `manually/` file and the workplan row
(`Releases/v1.0.0/workplan.md`); tick them there and here together. The
release branch `release/v1.0.0` is **not** to be re-cut until the owner says
so (owner, 2026-11-21).

**Website legal details (`JobTrigger-Web/src/content/site-details.ts`, workplan F2, PE-03)**
The owner's 2026-11-21 message had placeholders, not values. Each field is
still `null`, and `launch-readiness.test.ts` lists what's missing.
- [ ] `companyName`
- [ ] `securityEmail`
- [ ] `privacyEmail`
- [ ] `securityReplyDays` (a number of days)
- [ ] `backupRetention` (e.g. `"30 days"`; must match the production Atlas backup policy, workplan D2)
- [ ] `legalLastUpdated` (the date the site goes live)

**Manual tasks**
- [ ] **M-20** Atlas network lock-down (`manually/M-20-atlas-network-lockdown.md`, workplan D2): remove `0.0.0.0/0` from the dev project, add only a temporary Mac IP; production allows only the host's outbound ranges. Needs: the owner's Atlas login.
- [ ] **M-14** Production backend (`manually/M-14-production-backend.md`, workplan D1–D7): Render service, the `jobtrigger-prod` Atlas cluster, `CREDENTIALS_ENCRYPTION_KEY` in Render's secret manager, the encrypt-credentials run and `seedAppInfo.js`. Needs: Render account (paid plan for a static outbound IP), production Atlas cluster, DNS for the API hostname.
- [ ] **M-13** Website go-live (`manually/M-13-website-go-live.md`, workplan F1, F3, F4): connect Vercel, set its environment variables, attach the domain; store links after the listings are live. Needs: Vercel account, domain DNS, the `site-details.ts` values above.
- [ ] **M-19** Production mail (`manually/M-19-production-mail.md`): provider, SPF/DKIM/DMARC on `jobtrigger.app`, the support and student-application inboxes, SMTP secrets on the host; decide whether password reset is live in 1.0. Needs: a mail provider account, DNS access, the inboxes.
- [ ] **M-07** Crash-reporting DSNs (`manually/M-07-crash-reporting-dsn.md`, workplan D9): the three GlitchTip projects already exist (2026-11-17). Left: copy the DSNs into the three apps' `.env` files (agents may not touch `.env`, CLAUDE.md §8) and send the test crash from the iPhone. Production also needs a hosted GlitchTip and its DSNs (workplan D8).
