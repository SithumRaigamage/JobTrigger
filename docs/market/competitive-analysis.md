# Competitive analysis — mobile CI/CD apps

**Date:** 2026-10-24 · **Scope:** App Store and Google Play apps that let
you trigger, watch, or inspect CI/CD builds from a phone.
**Status:** desk research from public store listings and vendor pages.
Re-check before quoting anything externally (see [Method and limits](#method-and-limits)).

## 1. Summary

Apps like JobTrigger exist, but **every one found covers a single CI tool,
and most ship on only one platform**. No app found combines Jenkins,
GitHub Actions, and SonarQube; none ships the same multi-tool app on iOS
*and* Android; and none lets you set servers up from a laptop.

| Question | Answer |
|---|---|
| Is there a direct, like-for-like competitor? | **No.** The closest are single-tool Jenkins apps. |
| Strongest Jenkins rival on iPhone | **Jenkins View** — new (2026), broad Jenkins feature set, iPhone only. |
| Strongest Jenkins rival on Android | **JenBoard** — notifications and a home-screen widget, Android only. |
| Strongest GitHub Actions rival | **GitHub Mobile** — official, free, both platforms. |
| SonarQube on mobile | **Nothing exists**, official or third-party. |
| Only multi-tool app | **CI/CD** (iOS) — GitHub Actions, Coolify, Xcode Cloud; **no Jenkins**. |

**JobTrigger's position:** *the one app for your whole CI estate, on
either phone, set up from your laptop.* The Jenkins depth matters, but the
defensible part is the combination: several tools, both platforms, and
web setup with sync across devices.

## 2. Landscape

```
                     Single tool                    Several tools
              ┌──────────────────────────────┬───────────────────────────┐
  One         │ Jenkins View (iOS)           │ CI/CD (iOS)               │
  platform    │ Servebot (iOS)               │   GitHub Actions, Coolify,│
              │ JenBoard (Android)           │   Xcode Cloud — no Jenkins│
              │ gStat, Action Status (iOS)   │                           │
              │ Bitrise clients (each one)   │                           │
              ├──────────────────────────────┼───────────────────────────┤
  iOS +       │ GitHub Mobile (official)     │                           │
  Android     │ GitFlow                      │   ★ JobTrigger            │
              │ JKSCTL (basic, likely stale) │   (empty quadrant)        │
              └──────────────────────────────┴───────────────────────────┘
```

## 3. Competitor profiles

### 3.1 Jenkins

| App | Platform | Price | Strengths | Gaps vs JobTrigger | Signal |
|---|---|---|---|---|---|
| **Jenkins View** | iPhone | Free (optional tips) | Several servers; jobs, folders, favourites; console with search/share; pipeline stages; replay/rerun; artifacts; queue and nodes | iPhone only; Jenkins only; push notifications and widgets not listed; parameterised triggers unclear | **Very active** — v1.0 late May 2026, v2.1 June 2026. Main iPhone threat. |
| **JenBoard** | Android | Free | Several servers, console, **push notifications, home-screen widget**, stats; says credentials stay on the device | Android only; Jenkins only | Active. Main Android threat. |
| **Servebot for Jenkins** | iPhone | Free with ads; Pro $1.99 | Trigger builds, logs, queue/history, several servers, server commands (restart/pause) | iPhone only; ads; no ratings shown yet | v1.0 Feb 2025, v1.1.1 since. Small. |
| **JKSCTL** | iOS + Android | — | View jobs/history, start/stop builds | Basic feature set | Probably unmaintained. |
| **MobiLab "Jenkins"** | Android | — | Jobs, parameterised triggers, console, tests | — | **Abandoned** (developer says unsupported). |

### 3.2 GitHub Actions

| App | Platform | Notes |
|---|---|---|
| **GitHub Mobile** (official) | iOS + Android | Actions since Oct 2022: workflow list, runs, jobs, logs of completed steps, rerun (job / failed / all), cancel, completion notifications. Can't approve deployments that need manual sign-off from the run screen. Free; the default choice for GitHub-only users. |
| **GitFlow** | iOS + Android | Run history and build status via a personal access token; Google Play listing says it can trigger workflows. iOS 18+. |
| **gStat** | iOS | Status monitoring, re-run failed, `workflow_dispatch` with inputs. |
| **Action Status** | iOS | Status-focused. |
| **Actioneer** | **Mac only** | Dispatch, cancel, re-run, logs, desktop alerts. Free. Not a phone competitor. |

### 3.3 Multi-tool

| App | Platform | Tools | Notes |
|---|---|---|---|
| **CI/CD** | iOS | GitHub Actions, Coolify, Xcode Cloud | Free. The only multi-provider app found. No Jenkins, no Android. Watch it: it validates the "one app" idea and could add Jenkins. |

### 3.4 Other tools (context)

| Tool | Mobile options found |
|---|---|
| GitLab CI | General GitLab clients with a pipeline view: GitlabUp, GLab (iOS), Comeet (Android). Gitalchemy is Android/desktop only, no iOS plans. |
| Bitrise | Third-party clients: Buildio, BuildRise (iOS); BuildRadar, Bitmagic (Android). |
| SonarQube | **None.** SonarSource's mobile page is about analysing mobile code, not a mobile client. A SonarSource community answer pointed app builders at the Web API. |
| CircleCI, Azure DevOps | No official mobile app found. |

## 4. Feature comparison

✓ listed in the store listing · ✗ not offered · ? not stated · ◐ partial or
in progress. JobTrigger status follows `tasks/README.md` and the
"Feature availability" table in [epic WEB](../user-stories/web/17-website.md).

| Capability | **JobTrigger** | Jenkins View | JenBoard | Servebot | GitHub Mobile | CI/CD |
|---|---|---|---|---|---|---|
| iOS | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ |
| Android | ✓ | ✗ | ✓ | ✗ | ✓ | ✗ |
| Jenkins | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| GitHub Actions | ◐ (repos, workflows; runs soon) | ✗ | ✗ | ✗ | ✓ | ✓ |
| SonarQube | ◐ (servers saved; projects soon) | ✗ | ✗ | ✗ | ✗ | ✗ |
| Several servers | ✓ | ✓ | ✓ | ✓ | n/a | ? |
| Trigger with parameters (all types, masked secrets) | ✓ | ? | ? | ◐ | ✓ (dispatch) | ? |
| Live console | ✓ | ✓ | ✓ | ✓ | ◐ (completed steps) | ? |
| Pipeline stages / test results | ✓ | ✓ (stages) | ? | ? | ◐ | ? |
| Replay / rerun | ✓ | ✓ | ? | ? | ✓ | ? |
| Queue and nodes | ✓ | ✓ | ? | ✓ (queue) | n/a | ? |
| Build notifications | ✓ (local) | ? | ✓ | ? | ✓ | ? |
| Home-screen widget | ✓ | ? | ✓ | ? | ? | ? |
| Biometric app lock | ✓ | ? | ? | ? | ? | ? |
| **Set up from a laptop (web)** | ✓ (planned site, US-WEB-10…17) | ✗ | ✗ | ✗ | n/a | ✗ |
| **Servers sync across devices** | ✓ | ✗ | ✗ (on device) | ? | n/a (GitHub account) | ? |
| Credentials | Encrypted on backend + device secure storage | ? | **On device only** | ? | GitHub account | ? |
| Price | TBD | Free | Free | Free + $1.99 Pro, ads | Free | Free |

## 5. Where JobTrigger wins

1. **Several tools in one app.** No competitor combines Jenkins with
   GitHub Actions, and nobody does SonarQube.
2. **The same app on both platforms.** The best Jenkins apps are each
   locked to one store.
3. **Web setup.** Pasting tokens on a laptop and finding them on the
   phone is unique, and it removes the worst onboarding step every
   competitor has.
4. **Sync across devices** through the account.
5. **Jenkins breadth in one place:** parameterised triggers with masked
   secrets, stages, tests, notifications, widget, nodes, queue, app lock.
6. **First SonarQube client** on mobile, once P10 ships.

## 6. Threats and risks

| Risk | Why it matters | Response |
|---|---|---|
| **Jenkins View** moves fast on iPhone | Polished, free, frequent releases | Lead with multi-tool + Android + web setup, not Jenkins features alone. |
| **GitHub Mobile** is free and official | Hard to win GitHub-only users | Position GitHub support as "in the same app as Jenkins", not "better than GitHub Mobile". |
| **"Credentials stay on your device"** (JenBoard) | DevOps users distrust a backend holding tokens | The Security page (US-WEB-05) must explain encryption at rest, direct-to-CI traffic, masking on the web, and least-privilege tokens. Consider a device-only mode later (§8). |
| **CI/CD** adds Jenkins + Android | Would occupy the empty quadrant | Ship GitHub runs/logs (P8) and get to the stores early. |
| Free and cheap competitors | Price anchor near $0–$2 | See pricing notes (§7.3). |
| Self-hosted Jenkins behind a VPN | Every mobile client has this; users blame the app | Already handled in Support copy; keep the "can't reach server" errors clear. |

## 7. Recommendations

### 7.1 Product

- **Finish GitHub Actions runs, logs and history (P8)** before or soon
  after launch. It's the feature that makes "multi-tool" real.
- **Ship SonarQube quality gates (P10)** — the first mobile client is a
  clear "only JobTrigger does this" line.
- Keep parity on the basics competitors list: rerun/replay, console
  search, notifications, widget — already done.
- Watch-list items from competitors not yet in JobTrigger: **server
  commands** (Servebot: restart, quiet-down — admin scope, needs a
  decision like PIPE/JX), **build statistics** (JenBoard), approving
  GitHub deployments (a known GitHub Mobile gap).

### 7.2 Website and store messaging

- Headline idea: **"Jenkins, GitHub Actions and SonarQube — one app,
  iPhone and Android."**
- Proof points, in order: several tools · both platforms · set up from
  your laptop · parameterised triggers with masked secrets.
- Avoid claims that need a qualifier while features are pre-launch
  (US-WEB-22 / WEB-B7).
- A short, honest "How JobTrigger compares" table on the Integrations
  or Features page is a credible differentiator. Name categories
  ("single-tool apps"), not competitors, to avoid trademark and accuracy
  problems.

### 7.3 Pricing (to decide)

The market anchors at **free**. Options:

| Model | Fit |
|---|---|
| Free, with a paid tier for several tools / several servers / widget | Matches the market, monetises the differentiator. |
| Free for one tool, paid for the multi-tool bundle | Clear story, but the free tier then competes with single-tool apps. |
| One-time purchase | Simple; weak for ongoing backend costs (credential sync). |

The backend (sync, web setup) is an ongoing cost that competitors without
a backend don't have — a reason to have *some* paid tier.

### 7.4 App store optimisation

- Keywords competitors rank on: *jenkins, jenkins client, ci, cd,
  github actions, build monitor, pipeline, devops*. Add *sonarqube,
  quality gate* (no competition).
- Title pattern: "JobTrigger — Jenkins & GitHub CI".
- Screenshots: lead with the multi-tool home and the web-setup flow,
  since those are the differences.

## 8. Ideas for the backlog

Not committed scope; each would need its own story and approval
(`CLAUDE.md` §7).

- **Device-only mode:** keep a server's token on the phone only, opting
  out of sync, to answer the "credentials stay on device" pitch.
- **Comparison section on the website** (marketing, epic WEB).
- **GitLab CI next** — clients exist but none is CI-first or multi-tool.
- **Server commands** (restart / quiet down) — admin scope, needs a
  product decision.

## 9. What to monitor

Re-run this research **before launch** and **quarterly** after:

- Jenkins View — Android release? notifications/widgets?
- CI/CD — Jenkins or Android support?
- GitHub Mobile — Actions changes.
- Any SonarQube mobile client appearing.
- New multi-tool apps (search: "CI dashboard app", "build monitor").

## Method and limits

- Searched the web and read App Store and Google Play listings on
  2026-10-24.
- Store pages show **no download counts**, and most apps above had too
  few ratings to display a score, so market size and traction are
  **not measured** here.
- Some update dates on store pages show no year; "?" in the matrix means
  the listing doesn't say, not that the feature is missing.
- Feature claims are the developers' own listing text, not tested.

## Sources

- [Jenkins View — App Store](https://apps.apple.com/in/app/jenkins-view/id6772649850)
- [JenBoard — Google Play](https://play.google.com/store/apps/details?id=com.mintsoft.jenboard&hl=en)
- [Servebot for Jenkins — App Store](https://apps.apple.com/us/app/servebot-for-jenkins/id6740207367)
- [JKSCTL — App Store](https://apps.apple.com/us/app/jksctl-mobile-ci-for-jenkins/id6443540584)
- [MobiLab Jenkins — Google Play](https://play.google.com/store/apps/details?id=com.mobilabsolutions.jenkins.app&hl=en_AU&gl=US)
- [Introducing Actions on GitHub Mobile — GitHub Changelog](https://github.blog/changelog/2022-10-04-introducing-actions-on-github-mobile/)
- [Bringing GitHub Actions to GitHub Mobile — GitHub Blog](https://github.blog/news-insights/product-news/bringing-github-actions-to-github-mobile/)
- [GitFlow — Google Play](https://play.google.com/store/apps/details?id=com.gitflow.app) · [GitFlow — App Store](https://apps.apple.com/in/app/gitflow-github-actions/id6767349770)
- [gStat — App Store](https://apps.apple.com/th/app/gstat/id6478747440?l=th)
- [Action Status — App Store](https://apps.apple.com/us/app/action-status/id1498761533)
- [Actioneer — App Store](https://apps.apple.com/us/app/actioneer-command-your-ci/id6753989681?mt=12)
- [CI/CD — App Store](https://apps.apple.com/us/app/ci-cd/id6746098668)
- [GitlabUp](https://apps.apple.com/us/app/gitlabup-gitlabci-manager/id1491748785) · [GLab](https://apps.apple.com/ng/app/glab-gitlab-code-review/id6772132185) · [Comeet](https://play.google.com/store/apps/details?id=com.monokaijs.comeet&hl=en_US) · [Gitalchemy](https://www.gitalchemy.app/)
- [Buildio](https://apps.apple.com/us/app/buildio-bitrise-client/id1598605988) · [BuildRise](https://apps.apple.com/us/app/buildrise-bitrise-client/id6737528125) · [BuildRadar](https://play.google.com/store/apps/details?id=com.tdrk18.bitbox&hl=en_US) · [Bitmagic](https://play.google.com/store/apps/details?id=com.bitrise.app&hl=en)
- [SonarSource — mobile developers](https://www.sonarsource.com/solutions/mobile-developers/) · [SonarSource community thread](https://community.sonarsource.com/t/integration-hybrid-application-mobile-with-sonarqube/2500)
- [Watch GitHub Actions from your phone (Cosyra)](https://cosyra.com/guides/watch-ci-from-phone.html)
