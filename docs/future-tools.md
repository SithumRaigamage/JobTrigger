# JobTrigger — Future Tools Roadmap

Written 2026-11-16. A **proposal**, not a plan of record: nothing here is
promoted. Status of record stays in `tasks/README.md`; the longer candidate
list lives in `tasks/backlog.md` ("More CI/CD tools").

This document does four things:

1. Lists every tool that already has an epic doc, with its status.
2. Adds the tools that were **missing** from the backlog list (section 4).
3. Proposes a release order after the first release. Release 1.0 ships all
   three built tools together (Jenkins, SonarQube and GitHub Actions); from
   GitLab CI onward the owner's plan is one tool at a time.
4. Keeps one numbered catalogue of **all 164 tools** — built, specced,
   backlogged or newly added — in section 7 (`T-001`…`T-164`).

Every new tool is outside the original feature matrix, so each one still
needs its own scope approval (`CLAUDE.md` §7), an epic doc in
`docs/user-stories/<tool>/`, and a phase file before any code.

## 1. Where things stand

| Tool | Category | Status | Epic doc |
|---|---|---|---|
| Jenkins | CI | **Done and frozen** (`CLAUDE.md` §11) — ships in 1.0 | `user-stories/jenkins/` |
| SonarQube | Code quality | Development-complete (Phase 10), owner device checks M-03/M-04 — ships in 1.0 | `user-stories/sonarqube/14-sonarqube.md` |
| GitHub Actions | CI | Development-complete, owner token/device checks M-06 — ships in 1.0 | `user-stories/github-actions/12-github-actions.md` |
| GitLab CI | CI | Epic doc only | `user-stories/gitlab/13-gitlab-ci.md` |
| CircleCI | CI | Epic doc only | `user-stories/circleci/15-circleci.md` |
| Azure DevOps Pipelines | CI/CD | Epic doc only (2026-11-14) | `user-stories/azure-devops/19-azure-devops.md` |
| Argo CD | GitOps / CD | Epic doc only (2026-11-14) | `user-stories/argocd/20-argocd.md` |
| Bitrise | Mobile CI | Epic doc only (2026-11-14) | `user-stories/bitrise/21-bitrise.md` |
| Codemagic | Mobile CI | Epic doc only (2026-11-14) | `user-stories/codemagic/22-codemagic.md` |

## 2. What makes a tool a good fit

A tool earns a place in JobTrigger when most of these are true:

- **Phone-shaped actions.** Something worth doing away from a laptop:
  trigger, approve, cancel, roll back, acknowledge, check a gate.
- **A remote API with token auth.** CLI-only tools only count in their
  hosted or server form (backlog rule from 2026-10-23).
- **Status that changes.** Runs, deployments, alerts or gates someone
  wants to watch, not static settings.
- **Demand.** Requests through the app's "Need another tool? Tell us" link
  and the website decide order between tools of equal fit.
- **Fits the existing pattern.** One `CiTool` value, one backend credential
  type (encrypted at rest like the others), one setup-portal form, its own
  feature folders and tool-specific `AppFailure` cases (§11 — never change
  a shared case).

## 3. Proposed release order

| Wave | Tools | Why this order |
|---|---|---|
| 0 (now) | Jenkins → SonarQube → GitHub Actions | Owner's order. GitHub Actions only needs verification. |
| 1 — biggest CI share | GitLab CI, Azure DevOps Pipelines, Bitbucket Pipelines | Covers most teams not on Jenkins or GitHub. GitLab and Azure DevOps epics already exist. |
| 2 — deploy | Argo CD, Vercel, Render, Netlify, Coolify | "Is it live?" is the next question after "did it build?". Render and Vercel are the owner's own hosts, so they can be tested daily. Coolify is supported by the only multi-tool competitor (`docs/market/competitive-analysis.md`). |
| 3 — mobile release | Bitrise, Codemagic, Expo EAS, App Store Connect (TestFlight), Google Play Console | Mobile developers are the most likely to manage builds from a phone. Installable artifacts are a strong demo. |
| 4 — DevSecOps | Snyk, OWASP Dependency-Track, DefectDojo, Semgrep AppSec Platform, GitHub code scanning | Pairs with SonarQube into a "security and quality" bundle, and with the owner's DevSecOps research. |
| 5 — operate | PagerDuty, Grafana / Alertmanager, Uptime Kuma, GlitchTip, incident.io | Closes the loop from deploy to alert. GlitchTip is already in the owner's DevOps lab (Emergency E3). |
| Later | Everything else in section 4 and `tasks/backlog.md` | By demand. |

## 4. Tools added on 2026-11-16

These were not in the backlog list before. API notes are a starting point:
each must be checked against the vendor's current API docs when its epic
doc is written, the same way the Bitrise and Codemagic epics were.

### 4.1 Deploy and hosting platforms

| Tool | What a phone user would do | API notes (verify at epic time) |
|---|---|---|
| Vercel | See deployments per project, promote or roll back, redeploy, read build logs | REST API, bearer token, team scoping |
| Netlify | Deploy status, retry a deploy, lock/unlock auto-publish, publish an earlier deploy | REST API, personal access token |
| Render | Service and deploy status, manual deploy, rollback, suspend/resume, logs | REST API, API key |
| Railway | Deployment status, redeploy, restart, logs | GraphQL API, token |
| Fly.io | App and machine status, restart a machine, release history | Machines REST API, token |
| Heroku | Release history, rollback, restart dynos, scale | Platform API, token |
| Cloudflare Pages / Workers Builds | Build status, retry, roll back a deployment | REST API, scoped API token |
| DigitalOcean App Platform | Deployment status, redeploy, logs | REST API, token |
| AWS Amplify Hosting | Branch builds, start or stop a job | AWS API, IAM credentials (signing — larger effort) |
| Coolify | Self-hosted deploy status, redeploy, restart | REST API, token |
| Dokploy | Self-hosted deploy status, redeploy | REST API, token |

### 4.2 Mobile build and release

| Tool | What a phone user would do | API notes |
|---|---|---|
| Expo EAS | Build and submission status, start a build, install the artifact | Expo API, access token |
| Appcircle | Build status, trigger, distribute to testers | REST API, token |
| Firebase Test Lab | Test matrix results for a build | Google Cloud API, service account (larger effort) |

### 4.3 Security and DevSecOps

| Tool | What a phone user would do | API notes |
|---|---|---|
| OWASP Dependency-Track | Project risk score, new critical findings, policy violations | REST API, API key (self-hosted, free) |
| DefectDojo | Open findings by severity, accept or close a finding | REST API, token (self-hosted, free) |
| Semgrep AppSec Platform | New findings on a project, triage | REST API, token |
| GitHub code scanning and secret scanning | Open alerts per repository | Extension of the GH epic; needs extra token scopes, so it must be shown clearly in the token guide |
| Trivy Operator | Vulnerability reports from a cluster | Read through the Kubernetes integration, not a separate tool |

### 4.4 Testing services

| Tool | What a phone user would do | API notes |
|---|---|---|
| BrowserStack | Automate build and session results | REST API, username + access key |
| Sauce Labs | Job results, video link | REST API, username + access key |
| Cypress Cloud | Run results, flaky tests | API, record key / token |
| Allure TestOps / ReportPortal | Launch results and trends | REST API, token |

### 4.5 Feature flags and release control

| Tool | What a phone user would do | API notes |
|---|---|---|
| LaunchDarkly | Flip a flag (kill switch), see who changed it | REST API, access token |
| Unleash | Toggle a feature per environment | Admin API, token (self-hostable) |
| Flagsmith | Toggle a feature per environment | REST API, token (self-hostable) |
| GrowthBook | Flag and experiment status | REST API, secret key (self-hostable) |

Flag toggles are production changes: they need the two-step confirm
(`docs/product-improvements.md`, IMP-24) and an entry in the planned audit
log (`docs/implemented/improvement-plan.md`, "Later").

### 4.6 Uptime, observability and incidents

| Tool | What a phone user would do | API notes |
|---|---|---|
| GlitchTip | New issues per project, resolve or ignore | Sentry-compatible API, token (already self-hosted by the owner) |
| Uptime Kuma | Monitor status, pause a monitor | Self-hosted; API surface is limited, check before committing |
| UptimeRobot | Monitor status, pause/resume | REST API, API key |
| Better Stack | Monitors and incidents, acknowledge | REST API, token |
| incident.io | Open incidents, acknowledge, update status | REST API, key |
| Atlassian Statuspage | Post or update an incident on a status page | REST API, key |
| New Relic | Alert violations, entity health | NerdGraph (GraphQL), user key |

### 4.7 Issue tracking (link a failed build to work)

| Tool | What a phone user would do | API notes |
|---|---|---|
| Jira | Create an issue from a failed build with the log excerpt and link | REST API, API token |
| Linear | Same, for Linear teams | GraphQL API, key |
| GitHub Issues | Same, reusing the GitHub Actions token | REST API, existing token |

These are "actions on a build", not tools in the tool picker.

### 4.8 Data and ML pipelines

| Tool | What a phone user would do | API notes |
|---|---|---|
| Apache Airflow (self-hosted, Astronomer, MWAA, Cloud Composer) | DAG run status, trigger a DAG, clear a failed task, task logs | Stable REST API, basic auth or token |
| Dagster+ | Run status, launch a run | GraphQL API, token |
| Prefect Cloud | Flow run status, start a deployment | REST API, key |
| Kubeflow Pipelines | Run status, start a run | REST API, cluster auth (larger effort) |

Data engineers have the same "is my pipeline green?" need and almost no
mobile options. A new audience, not a new screen design.

### 4.9 Containers, registries and platform

| Tool | What a phone user would do | API notes |
|---|---|---|
| AWS ECR | Latest image tags, scan findings | AWS API, IAM signing |
| Google Artifact Registry | Latest versions, vulnerability scan | Google Cloud API, service account |
| Quay.io | Tags, security scan status | REST API, token |
| Backstage | Component ownership and links to its CI/CD | REST API, token; works as a "jump to the right tool" index |

### 4.10 Workflow automation

| Tool | What a phone user would do | API notes |
|---|---|---|
| n8n | Workflow executions, failed runs, activate/deactivate | Public REST API, API key (self-hostable) |

### 4.11 Second batch (added later on 2026-11-16)

Same rule: API notes are a starting point, checked again when the epic doc
is written.

| Tool | Category | What a phone user would do | API notes |
|---|---|---|---|
| AppVeyor | CI | Build status for Windows/.NET projects, rebuild | REST API, token |
| Buddy | CI/CD | Pipeline runs, run or retry, approvals | REST API, token |
| Dagger Cloud | Pipeline traces | Trace status of Dagger pipeline runs | API, token |
| Depot | Remote builds | Container and CI build status, cache usage | API, token |
| Gradle Develocity | Build insight | Build scans: failures, slow tasks | REST API, access key |
| BuildBuddy | Bazel builds | Invocation status and failed targets | API, key |
| Nx Cloud | Monorepo CI | Run status and cache hits | API, token |
| Unity Build Automation | Game builds | Build status, start a build, install the artifact | REST API, key |
| Google Cloud Run | Deploy | Revisions, traffic split, roll back to a revision | Google Cloud API, service account (larger effort) |
| Google Cloud Deploy | CD | Release and rollout status, approve a rollout | Google Cloud API, service account |
| AWS CloudFormation | Infrastructure | Stack status, failed resource reason | AWS API, IAM signing |
| AWS Elastic Beanstalk | Deploy | Environment health, recent events | AWS API, IAM signing |
| Firebase Hosting | Deploy | Releases per site, roll back | Firebase API, service account |
| Kargo | GitOps promotion | Freight and promotions between stages, approve a promotion | Kubernetes API (CRDs) |
| Flagger | Progressive delivery | Canary status and analysis | Kubernetes API (CRDs) |
| Statsig | Feature flags | Gate status, kill switch | Console API, key |
| ConfigCat | Feature flags | Toggle a setting per environment | Public management API, basic auth |
| PostHog | Feature flags | Flag status and rollout percentage | REST API, personal key (self-hostable) |
| Mend | Dependency security | New vulnerable dependencies per project | API, token |
| Aikido Security | Security platform | Open issues by severity | REST API, OAuth client |
| Socket | Supply-chain security | Alerts on risky packages in a repository | REST API, key |
| JFrog Xray | Artifact scanning | Violations on builds and artifacts | Via the Artifactory platform API |
| Wiz | Cloud security | Critical issues on cloud resources | GraphQL API, service account |
| Cortex Cloud (formerly Prisma Cloud) | Cloud security | Alerts and policy violations | REST API, access key |
| HashiCorp Vault | Secrets | Health and seal status only — never read secrets | REST API, token with a health-only policy |
| Infisical | Secrets | Secret sync status and failures, never values | REST API, machine identity |
| Cloudsmith | Registry | Package versions, sync and scan status | REST API, key |
| Azure Container Registry | Registry | Repositories, latest tags | Azure API, service principal |
| Chromatic | Visual testing | Builds waiting for review, accept or deny changes | API, token |
| Percy | Visual testing | Builds with visual changes to review | REST API, token |
| LambdaTest | Cross-browser testing | Test session results | REST API, username + key |
| Currents | Playwright / Cypress dashboard | Run results, flaky tests | REST API, key |
| Grafana Cloud k6 | Load testing | Load test run results, thresholds passed | REST API, token |
| Lighthouse CI server | Web performance | Performance score per build | Self-hosted API |
| Splunk On-Call | Incidents | Acknowledge and resolve incidents | REST API, key |
| Grafana Cloud IRM | On-call and incidents | Alert groups, acknowledge, who's on call | API, token |
| Dynatrace | Observability | Open problems, root cause | REST API, token |
| Honeycomb | Observability | Triggered alerts and SLO burn | REST API, key |
| Elastic Observability | Observability | Active alerts | Kibana API, key |
| Zabbix | Monitoring | Current problems, acknowledge | JSON-RPC API, token |
| Checkly | Synthetic monitoring | Failing checks, trigger a check run | REST API, key |
| Healthchecks.io | Cron monitoring | Late or down cron jobs, pause a check | REST API, key (self-hostable) |
| Cronitor | Cron monitoring | Failing jobs and monitors | REST API, key |
| Jira Service Management | Incidents and on-call | Alerts and incidents (the Opsgenie replacement) | REST API, API token |
| ServiceNow | Change management | Approve or reject a change request tied to a deployment | REST API, OAuth (enterprise effort) |
| dbt Cloud | Data pipelines | Job runs, trigger a run, failed models | REST API, token |
| Databricks Jobs | Data and ML | Job run status, run now, repair a run | REST API, token |
| Temporal Cloud | Workflow engine | Failed workflow executions | API, key (larger effort) |
| Weights & Biases | ML experiments | Training run status and alerts | API, key |

## 5. Tools not to add

| Tool | Reason |
|---|---|
| Microsoft App Center | Retired by Microsoft in 2025. |
| Opsgenie | Atlassian ended new sales on 4 June 2025 and support ends on 5 April 2027, when access and the REST APIs stop. Point users to Jira Service Management or PagerDuty instead. |
| Fastlane, Trivy CLI, kubectl, Ansible CLI | Command-line only. They come in through the server or hosted product that runs them (Bitrise, AWX, the Kubernetes integration). |

## 6. How to promote a tool

The same steps every earlier tool went through, kept here so nothing is
skipped:

1. Owner approves the tool's scope (`CLAUDE.md` §7).
2. Epic doc in `docs/user-stories/<tool>/`, API checked against current
   vendor docs, following the story template in
   `docs/user-stories/README.md`.
3. Phase file in `tasks/` and a row in the `tasks/README.md` status table.
4. Backend credential type, encrypted at rest with `security/secretCipher`.
5. Setup-portal form in `JobTrigger-Web/`, with the masked-secret display.
6. App: `CiTool` value, feature folders, tool-specific `AppFailure`
   cases, repository fakes and tests. `isAvailable` flips only when the
   tool is verified against a real account.
7. Website "Coming soon" state until the release ships (US-WEB-22).
8. Whole suite green: `flutter analyze`, `flutter test`, `npm test` (§11).

## 7. Full catalogue (164 tools)

One numbered list of every tool in this document, the epic docs and
`tasks/backlog.md`. "Source" says where the tool first appeared. Section 3
gives the order; everything not in a wave is ordered by demand.

### CI and build

| ID | Tool | Source / status |
|---|---|---|
| T-001 | Jenkins | done (first release) |
| T-002 | GitHub Actions | built, verifying |
| T-003 | GitLab CI | epic doc |
| T-004 | CircleCI | epic doc |
| T-005 | Azure DevOps Pipelines | epic doc |
| T-006 | Bitbucket Pipelines | backlog (2026-10-23) |
| T-007 | TeamCity | backlog (2026-10-23) |
| T-008 | Bamboo | backlog (2026-10-23) |
| T-009 | Travis CI | backlog (2026-10-23) |
| T-010 | Buildkite | backlog (2026-10-23) |
| T-011 | Drone / Harness CI | backlog (2026-10-23) |
| T-012 | Woodpecker CI | backlog (2026-10-23) |
| T-013 | Concourse | backlog (2026-10-23) |
| T-014 | GoCD | backlog (2026-10-23) |
| T-015 | Semaphore | backlog (2026-10-23) |
| T-016 | Codefresh | backlog (2026-10-23) |
| T-017 | AWS CodeBuild / CodePipeline | backlog (2026-10-23) |
| T-018 | Google Cloud Build | backlog (2026-10-23) |
| T-019 | Gitea / Forgejo Actions | backlog (2026-10-23) |
| T-020 | Tekton | backlog (2026-10-23) |
| T-021 | AppVeyor | added 2026-11-16 |
| T-022 | Buddy | added 2026-11-16 |
| T-023 | Dagger Cloud | added 2026-11-16 |
| T-024 | Depot | added 2026-11-16 |
| T-025 | Gradle Develocity | added 2026-11-16 |
| T-026 | BuildBuddy | added 2026-11-16 |
| T-027 | Nx Cloud | added 2026-11-16 |
| T-028 | Unity Build Automation | added 2026-11-16 |

### Deployment, GitOps and hosting

| ID | Tool | Source / status |
|---|---|---|
| T-029 | Argo CD | epic doc |
| T-030 | Argo Workflows / Rollouts | backlog (2026-10-23) |
| T-031 | Flux | backlog (2026-10-23) |
| T-032 | Spinnaker | backlog (2026-10-23) |
| T-033 | Harness CD | backlog (2026-10-23) |
| T-034 | Octopus Deploy | backlog (2026-10-23) |
| T-035 | AWS CodeDeploy | backlog (2026-10-23) |
| T-036 | Vercel | added 2026-11-16 |
| T-037 | Netlify | added 2026-11-16 |
| T-038 | Render | added 2026-11-16 |
| T-039 | Railway | added 2026-11-16 |
| T-040 | Fly.io | added 2026-11-16 |
| T-041 | Heroku | added 2026-11-16 |
| T-042 | Cloudflare Pages / Workers Builds | added 2026-11-16 |
| T-043 | DigitalOcean App Platform | added 2026-11-16 |
| T-044 | AWS Amplify Hosting | added 2026-11-16 |
| T-045 | Coolify | added 2026-11-16 |
| T-046 | Dokploy | added 2026-11-16 |
| T-047 | Google Cloud Run | added 2026-11-16 |
| T-048 | Google Cloud Deploy | added 2026-11-16 |
| T-049 | AWS Elastic Beanstalk | added 2026-11-16 |
| T-050 | Firebase Hosting | added 2026-11-16 |
| T-051 | Kargo | added 2026-11-16 |
| T-052 | Flagger | added 2026-11-16 |

### Infrastructure as code

| ID | Tool | Source / status |
|---|---|---|
| T-053 | HCP Terraform | backlog (2026-10-23) |
| T-054 | Pulumi Cloud | backlog (2026-10-23) |
| T-055 | Spacelift | backlog (2026-10-23) |
| T-056 | env0 | backlog (2026-10-23) |
| T-057 | Scalr | backlog (2026-10-23) |
| T-058 | Atlantis | backlog (2026-10-23) |
| T-059 | AWS CloudFormation | added 2026-11-16 |

### Configuration and automation

| ID | Tool | Source / status |
|---|---|---|
| T-060 | Ansible AWX / Automation Platform | backlog (2026-10-23) |
| T-061 | Rundeck | backlog (2026-10-23) |
| T-062 | Puppet Enterprise | backlog (2026-10-23) |
| T-063 | Chef Automate | backlog (2026-10-23) |
| T-064 | Salt | backlog (2026-10-23) |
| T-065 | n8n | added 2026-11-16 |

### Containers and orchestration

| ID | Tool | Source / status |
|---|---|---|
| T-066 | Kubernetes | backlog (2026-10-23) |
| T-067 | OpenShift | backlog (2026-10-23) |
| T-068 | Rancher | backlog (2026-10-23) |
| T-069 | Nomad | backlog (2026-10-23) |
| T-070 | Portainer | backlog (2026-10-23) |
| T-071 | AWS ECS | backlog (2026-10-23) |

### Code quality and security

| ID | Tool | Source / status |
|---|---|---|
| T-072 | SonarQube | development-complete (Phase 10); ships in 1.0 |
| T-073 | Snyk | backlog (2026-10-23) |
| T-074 | Codecov | backlog (2026-10-23) |
| T-075 | Coveralls | backlog (2026-10-23) |
| T-076 | Checkmarx | backlog (2026-10-23) |
| T-077 | Veracode | backlog (2026-10-23) |
| T-078 | GitGuardian | backlog (2026-10-23) |
| T-079 | Dependabot | backlog (2026-10-23) |
| T-080 | OWASP Dependency-Track | added 2026-11-16 |
| T-081 | DefectDojo | added 2026-11-16 |
| T-082 | Semgrep AppSec Platform | added 2026-11-16 |
| T-083 | GitHub code scanning / secret scanning | added 2026-11-16 |
| T-084 | Trivy Operator | added 2026-11-16 |
| T-085 | Mend | added 2026-11-16 |
| T-086 | Aikido Security | added 2026-11-16 |
| T-087 | Socket | added 2026-11-16 |
| T-088 | JFrog Xray | added 2026-11-16 |
| T-089 | Wiz | added 2026-11-16 |
| T-090 | Cortex Cloud (formerly Prisma Cloud) | added 2026-11-16 |
| T-091 | HashiCorp Vault (health only) | added 2026-11-16 |
| T-092 | Infisical (sync status only) | added 2026-11-16 |

### Artifacts and registries

| ID | Tool | Source / status |
|---|---|---|
| T-093 | JFrog Artifactory | backlog (2026-10-23) |
| T-094 | Sonatype Nexus | backlog (2026-10-23) |
| T-095 | Harbor | backlog (2026-10-23) |
| T-096 | Docker Hub | backlog (2026-10-23) |
| T-097 | GitHub Container Registry | backlog (2026-10-23) |
| T-098 | AWS ECR | added 2026-11-16 |
| T-099 | Google Artifact Registry | added 2026-11-16 |
| T-100 | Quay.io | added 2026-11-16 |
| T-101 | Cloudsmith | added 2026-11-16 |
| T-102 | Azure Container Registry | added 2026-11-16 |

### Mobile build and release

| ID | Tool | Source / status |
|---|---|---|
| T-103 | Bitrise | epic doc |
| T-104 | Codemagic | epic doc |
| T-105 | Xcode Cloud | backlog (2026-10-23) |
| T-106 | App Store Connect | backlog (2026-10-23) |
| T-107 | Google Play Console | backlog (2026-10-23) |
| T-108 | Firebase App Distribution | backlog (2026-10-23) |
| T-109 | Expo EAS | added 2026-11-16 |
| T-110 | Appcircle | added 2026-11-16 |
| T-111 | Firebase Test Lab | added 2026-11-16 |

### Testing services

| ID | Tool | Source / status |
|---|---|---|
| T-112 | BrowserStack | added 2026-11-16 |
| T-113 | Sauce Labs | added 2026-11-16 |
| T-114 | Cypress Cloud | added 2026-11-16 |
| T-115 | Allure TestOps | added 2026-11-16 |
| T-116 | ReportPortal | added 2026-11-16 |
| T-117 | Chromatic | added 2026-11-16 |
| T-118 | Percy | added 2026-11-16 |
| T-119 | LambdaTest | added 2026-11-16 |
| T-120 | Currents | added 2026-11-16 |
| T-121 | Grafana Cloud k6 | added 2026-11-16 |
| T-122 | Lighthouse CI server | added 2026-11-16 |

### Feature flags

| ID | Tool | Source / status |
|---|---|---|
| T-123 | LaunchDarkly | added 2026-11-16 |
| T-124 | Unleash | added 2026-11-16 |
| T-125 | Flagsmith | added 2026-11-16 |
| T-126 | GrowthBook | added 2026-11-16 |
| T-127 | Statsig | added 2026-11-16 |
| T-128 | ConfigCat | added 2026-11-16 |
| T-129 | PostHog | added 2026-11-16 |

### Monitoring, uptime and incidents

| ID | Tool | Source / status |
|---|---|---|
| T-130 | Datadog | backlog (2026-10-23) |
| T-131 | Grafana | backlog (2026-10-23) |
| T-132 | Prometheus / Alertmanager | backlog (2026-10-23) |
| T-133 | PagerDuty | backlog (2026-10-23) |
| T-134 | Sentry | backlog (2026-10-23) |
| T-135 | GlitchTip | added 2026-11-16 |
| T-136 | Uptime Kuma | added 2026-11-16 |
| T-137 | UptimeRobot | added 2026-11-16 |
| T-138 | Better Stack | added 2026-11-16 |
| T-139 | incident.io | added 2026-11-16 |
| T-140 | Atlassian Statuspage | added 2026-11-16 |
| T-141 | New Relic | added 2026-11-16 |
| T-142 | Splunk On-Call | added 2026-11-16 |
| T-143 | Grafana Cloud IRM | added 2026-11-16 |
| T-144 | Dynatrace | added 2026-11-16 |
| T-145 | Honeycomb | added 2026-11-16 |
| T-146 | Elastic Observability | added 2026-11-16 |
| T-147 | Zabbix | added 2026-11-16 |
| T-148 | Checkly | added 2026-11-16 |
| T-149 | Healthchecks.io | added 2026-11-16 |
| T-150 | Cronitor | added 2026-11-16 |
| T-151 | Jira Service Management | added 2026-11-16 |

### Work tracking and change management (build actions)

| ID | Tool | Source / status |
|---|---|---|
| T-152 | Jira | added 2026-11-16 |
| T-153 | Linear | added 2026-11-16 |
| T-154 | GitHub Issues | added 2026-11-16 |
| T-155 | ServiceNow change approvals | added 2026-11-16 |
| T-156 | Backstage | added 2026-11-16 |

### Data and ML pipelines

| ID | Tool | Source / status |
|---|---|---|
| T-157 | Apache Airflow | added 2026-11-16 |
| T-158 | Dagster+ | added 2026-11-16 |
| T-159 | Prefect Cloud | added 2026-11-16 |
| T-160 | Kubeflow Pipelines | added 2026-11-16 |
| T-161 | dbt Cloud | added 2026-11-16 |
| T-162 | Databricks Jobs | added 2026-11-16 |
| T-163 | Temporal Cloud | added 2026-11-16 |
| T-164 | Weights & Biases | added 2026-11-16 |

