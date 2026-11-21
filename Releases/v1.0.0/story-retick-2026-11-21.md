# User-story re-tick — 2026-11-21

Every acceptance criterion in the built epics was checked against the code
and its tests (app, backend, website). A criterion is ticked `[x]` only with
an `Evidence:` line naming the file and test that prove it; otherwise it
stays `[ ]` with an `Open:` line saying why. "Gaps fixed" counts the
criteria that needed a new test or a code fix on 2026-11-21 (each says
`Fixed 2026-11-21`).

Not covered: the docs-only epics (GitLab, CircleCI, Azure DevOps, Argo CD,
Bitrise, Codemagic), which have no code to check, and `shared/09` /
`shared/10`, which have no checkbox criteria. US-WEB-19's four criteria are
updated by PR #154 (option c), not here. US-JX-16's nine were already
ticked when #151 merged.

How the suites were run: `flutter analyze` and `flutter test` in
`JobTrigger-Frontend/`; the backend suite with mocha from a directory that
has no `.env` (so `server.js` loads none); the website's `npm run check` and
Playwright from a separate checkout that has no `.env.local`.

## Bugs found and fixed while proving the criteria

Each fix has a test that failed on the old code.

| Area | Bug | Fix |
|---|---|---|
| Credentials (Jenkins, GitHub, SonarQube) | The first credential saved without "Set as default" never became active; Home waited on a spinner until a restart | The active-credential notifiers adopt the saved/default/first one when a list arrives while none is active |
| Settings (all tools) | Swipe-to-delete hid the row before deleting: a failed delete looked like a success; a good one left a dismissed row in the tree | Delete inside `confirmDismiss`; the reloaded list removes the row |
| Jenkins server form | Empty name, username or secret went to the backend, which refuses them | Refused before any request (after the plan check) |
| Home (Jenkins) | A failed pull-to-refresh (not offline) replaced the loaded jobs with the error screen | The list stays; a "Refresh failed" toast says why |
| Job detail (Jenkins) | One failed 5 s poll replaced the job with the error screen | The last job stays; the next poll retries |
| Job detail (Jenkins) | With no estimated duration the progress bar sat at 0 % | Indeterminate bar |
| Job detail (Jenkins) | After an optimistic cancel nothing polled again, so ABORTED stayed even when Jenkins hadn't stopped or the build had finished | One confirmation poll after a cancel |
| Build log (Jenkins) | Following new output stopped short of the newest line with wrapped lines | Jump again until the end is reached |
| App Info | Showed the backend's version, not the installed one; a failed fetch hid everything | Installed version from `package_info_plus`; inline retry for the backend's links |
| App Info | `minSupportedVersion` was never read | "Update required" gate (never blocks on an outage or a bad value) |
| Auth | Login form flashed while the stored session was read; an unreadable keystore was an error; logout was one tap; a 401 logged out silently | Progress screen; "no session"; confirmation; "Your session has expired" |
| Tool selection | Tapping a "Coming next" tile did nothing | A toast says when it arrives |
| Job history | "End of history · 1 builds" | "1 build" |

## By epic

| File | Criteria | Ticked | Gaps fixed | Still open |
|---|---|---|---|---|
| `shared/00-design-system-glassmorphism.md` | 15 | 11 | 9 | 4 |
| `shared/01-authentication.md` | 24 | 20 | 6 | 4 |
| `shared/02-tool-selection.md` | 6 | 3 | 2 | 3 |
| `shared/08-profile-settings-app-info.md` | 13 | 12 | 8 | 1 |
| `shared/11-support.md` | 7 | 7 | 2 | 0 |
| `jenkins/03-credential-management.md` | 23 | 16 | 11 | 7 |
| `jenkins/04-job-tree-navigation.md` | 18 | 14 | 6 | 4 |
| `jenkins/05-job-detail-build-trigger.md` | 22 | 20 | 8 | 2 |
| `jenkins/06-build-logs.md` | 13 | 11 | 6 | 2 |
| `jenkins/07-build-history.md` | 7 | 7 | 4 | 0 |
| `jenkins/11-build-insights-pipeline.md` | 41 | 35 | 16 | 6 |
| `jenkins/16-jenkins-extended.md` | 101 | 90 | 3 | 11 |
| `github-actions/12-github-actions.md` | 42 | 32 | 7 | 10 |
| `sonarqube/14-sonarqube.md` | 99 | 90 | 2 | 9 |
| `web/17-website.md` | 76 | 52 | 0 | 20 |
| `billing/18-subscriptions.md` | 31 | 28 | 0 | 3 |
| **Total** | **538** | **448** | **90** | **86** |

## By story

| Story | Criteria | Ticked | Gaps fixed | Still open (why) |
|---|---|---|---|---|
| US-DESIGN-01 | 3 | 2 | 2 | 1 (not proven) |
| US-DESIGN-02 | 3 | 3 | 1 | 0  |
| US-DESIGN-03 | 3 | 1 | 1 | 2 (not as written; same platform limit as above for the OS toggle. The in-app s) |
| US-DESIGN-04 | 3 | 2 | 2 | 1 (device-only) |
| US-DESIGN-05 | 3 | 3 | 3 | 0  |
| US-AUTH-01 | 4 | 4 | 1 | 0  |
| US-AUTH-02 | 4 | 4 | 1 | 0  |
| US-AUTH-03 | 4 | 3 | 2 | 1 (device-only) |
| US-AUTH-04 | 3 | 1 | 1 | 2 (not proven; superseded) |
| US-AUTH-05 | 3 | 2 | 1 | 1 (not proven) |
| US-AUTH-06 | 3 | 3 | 0 | 0  |
| US-AUTH-07 | 3 | 3 | 0 | 0  |
| US-TOOL-01 | 3 | 0 | 0 | 3 (contradicts a deliberate design; not as written; partly superseded) |
| US-TOOL-02 | 3 | 3 | 2 | 0  |
| US-PROF-01 | 2 | 2 | 1 | 0  |
| US-PROF-02 | 3 | 3 | 3 | 0  |
| US-PROF-03 | 5 | 4 | 3 | 1 (superseded on purpose by P25-05) |
| US-PROF-04 | 3 | 3 | 1 | 0  |
| US-SUP-01 | 4 | 4 | 2 | 0  |
| US-SUP-02 | 1 | 1 | 0 | 0  |
| US-SUP-03 | 1 | 1 | 0 | 0  |
| US-SUP-04 | 1 | 1 | 0 | 0  |
| US-CRED-01 | 3 | 3 | 2 | 0  |
| US-CRED-02 | 4 | 2 | 2 | 2 (partly; saving without a test is allowed (`test/presentation/feature) |
| US-CRED-03 | 4 | 3 | 1 | 1 (contradicts the current design) |
| US-CRED-04 | 4 | 3 | 3 | 1 (partly) |
| US-CRED-05 | 4 | 2 | 0 | 2 (not applicable as built; partly) |
| US-CRED-06 | 4 | 3 | 3 | 1 (partly) |
| US-TREE-01 | 4 | 2 | 1 | 2 (browsing has no depth limit now (each folder loads on entry,; superseded on purpose) |
| US-TREE-02 | 4 | 3 | 0 | 1 (not built) |
| US-TREE-03 | 4 | 3 | 2 | 1 (partly) |
| US-TREE-04 | 3 | 3 | 1 | 0  |
| US-TREE-05 | 3 | 3 | 2 | 0  |
| US-JOB-01 | 4 | 3 | 2 | 1 (partly) |
| US-JOB-02 | 4 | 4 | 1 | 0  |
| US-JOB-03 | 5 | 4 | 1 | 1 (submission is allowed with empty values, but an empty field) |
| US-JOB-04 | 5 | 5 | 2 | 0  |
| US-JOB-05 | 4 | 4 | 2 | 0  |
| US-LOG-01 | 5 | 5 | 1 | 0  |
| US-LOG-02 | 4 | 4 | 4 | 0  |
| US-LOG-03 | 4 | 2 | 1 | 2 (not built; sharing mid-stream sends what is loaded so far, but nothing) |
| US-HIST-01 | 4 | 4 | 2 | 0  |
| US-HIST-02 | 3 | 3 | 2 | 0  |
| US-PIPE-01 | 5 | 4 | 2 | 1 (not proven) |
| US-PIPE-02 | 4 | 3 | 2 | 1 (partly) |
| US-PIPE-03 | 4 | 4 | 0 | 0  |
| US-PIPE-04 | 5 | 4 | 2 | 1 (replaced on purpose by US-JX-04) |
| US-PIPE-05 | 6 | 5 | 4 | 1 (partly) |
| US-PIPE-06 | 4 | 4 | 2 | 0  |
| US-PIPE-07 | 4 | 2 | 1 | 2 (not applicable as built; replaced on purpose by AUD-21) |
| US-PIPE-08 | 5 | 5 | 0 | 0  |
| US-PIPE-09 | 4 | 4 | 3 | 0  |
| US-JX-01 | 4 | 4 | 0 | 0  |
| US-JX-02 | 6 | 5 | 0 | 1 (not proven) |
| US-JX-03 | 5 | 4 | 0 | 1 (partly) |
| US-JX-04 | 5 | 5 | 0 | 0  |
| US-JX-05 | 3 | 3 | 0 | 0  |
| US-JX-06 | 4 | 3 | 0 | 1 (not proven) |
| US-JX-07 | 8 | 7 | 0 | 1 (partly) |
| US-JX-08 | 3 | 2 | 0 | 1 (partly) |
| US-JX-09 | 4 | 4 | 0 | 0  |
| US-JX-10 | 7 | 5 | 0 | 2 (partly; the background task is registered on Android and iOS only (`) |
| US-JX-11 | 4 | 4 | 0 | 0  |
| US-JX-12 | 4 | 4 | 0 | 0  |
| US-JX-13 | 3 | 3 | 0 | 0  |
| US-JX-14 | 3 | 3 | 0 | 0  |
| US-JX-15 | 3 | 3 | 0 | 0  |
| US-JX-16 | 9 | 9 | 0 | 0  |
| US-JX-17 | 3 | 3 | 0 | 0  |
| US-JX-18 | 3 | 2 | 2 | 1 (partly) |
| US-JX-19 | 5 | 5 | 0 | 0  |
| US-JX-20 | 3 | 2 | 0 | 1 (partly) |
| US-JX-21 | 6 | 6 | 0 | 0  |
| US-JX-22 | 3 | 3 | 1 | 0  |
| US-JX-23 | 3 | 1 | 0 | 2 (device-only) |
| US-GH-CRED-01 | 4 | 2 | 1 | 2 (not built; not built, and not added on purpose) |
| US-GH-CRED-02 | 4 | 3 | 2 | 1 (not proven for GitHub rows) |
| US-GH-CRED-03 | 2 | 1 | 1 | 1 (partly) |
| US-GH-CRED-04 | 3 | 3 | 3 | 0  |
| US-GH-REPO-01 | 3 | 0 | 0 | 3 (not built; not proven on screen; partly) |
| US-GH-REPO-02 | 3 | 1 | 0 | 2 (not proven on screen; partly) |
| US-GH-RUN-01 | 2 | 2 | 0 | 0  |
| US-GH-RUN-02 | 5 | 5 | 0 | 0  |
| US-GH-RUN-03 | 3 | 3 | 0 | 0  |
| US-GH-RUN-04 | 3 | 3 | 0 | 0  |
| US-GH-RUN-05 | 2 | 2 | 0 | 0  |
| US-GH-LOG-01 | 4 | 4 | 0 | 0  |
| US-GH-LOG-02 | 1 | 0 | 0 | 1 (partly) |
| US-GH-HIST-01 | 1 | 1 | 0 | 0  |
| US-GH-HIST-02 | 2 | 2 | 0 | 0  |
| US-SQ-CRED-01 | 5 | 4 | 0 | 1 (not built) |
| US-SQ-CRED-02 | 3 | 2 | 0 | 1 (not proven for SonarQube rows) |
| US-SQ-CRED-03 | 2 | 2 | 2 | 0  |
| US-SQ-CRED-04 | 2 | 1 | 0 | 1 (built differently on purpose) |
| US-SQ-PROJ-01 | 6 | 6 | 0 | 0  |
| US-SQ-PROJ-03 | 4 | 4 | 0 | 0  |
| US-SQ-QUALITY-01 | 4 | 4 | 0 | 0  |
| US-SQ-QUALITY-02 | 3 | 3 | 0 | 0  |
| US-SQ-QUALITY-03 | 5 | 5 | 0 | 0  |
| US-SQ-QUALITY-04 | 2 | 2 | 0 | 0  |
| US-SQ-QUALITY-05 | 2 | 2 | 0 | 0  |
| US-SQ-QUALITY-06 | 2 | 2 | 0 | 0  |
| US-SQ-OVERVIEW-01 | 3 | 3 | 0 | 0  |
| US-SQ-LINK-01 | 1 | 1 | 0 | 0  |
| US-SQ-ISSUES-01 | 3 | 3 | 0 | 0  |
| US-SQ-CE-01 | 3 | 3 | 0 | 0  |
| US-SQ-QUALITY-07 | 2 | 2 | 0 | 0  |
| US-SQ-QUALITY-08 | 2 | 2 | 0 | 0  |
| US-SQ-QUALITY-09 | 2 | 2 | 0 | 0  |
| US-SQ-WATCH-01 | 4 | 1 | 0 | 3 (not proven) |
| US-SQ-QUALITY-10 | 2 | 2 | 0 | 0  |
| US-SQ-HOTSPOT-01 | 2 | 2 | 0 | 0  |
| US-SQ-QUALITY-11 | 2 | 2 | 0 | 0  |
| US-SQ-QUALITY-12 | 2 | 2 | 0 | 0  |
| US-SQ-QUALITY-13 | 2 | 2 | 0 | 0  |
| US-SQ-ISSUES-02 | 2 | 2 | 0 | 0  |
| US-SQ-ISSUES-03 | 2 | 2 | 0 | 0  |
| US-SQ-SERVER-01 | 2 | 2 | 0 | 0  |
| US-SQ-OVERVIEW-02 | 2 | 2 | 0 | 0  |
| US-SQ-PIN-01 | 2 | 2 | 0 | 0  |
| US-SQ-WIDGET-01 | 2 | 1 | 0 | 1 (device-only) |
| US-SQ-OFFLINE-01 | 2 | 2 | 0 | 0  |
| US-SQ-LINK-02 | 2 | 1 | 0 | 1 (partly) |
| US-SQ-ISSUES-04 | 2 | 2 | 0 | 0  |
| US-SQ-XTOOL-01 | 3 | 3 | 0 | 0  |
| US-SQ-XTOOL-02 | 2 | 2 | 0 | 0  |
| US-SQ-XTOOL-03 | 1 | 1 | 0 | 0  |
| US-SQ-WRITE-01 | 2 | 2 | 0 | 0  |
| US-SQ-WRITE-02 | 1 | 1 | 0 | 0  |
| US-SQ-WRITE-03 | 1 | 1 | 0 | 0  |
| US-SQ-WRITE-04 | 1 | 0 | 0 | 1 (partly) |
| US-WEB-01 | 3 | 2 | 0 | 1 (not proven) |
| US-WEB-02 | 5 | 2 | 0 | 3 (not proven; partly) |
| US-WEB-03 | 3 | 3 | 0 | 0  |
| US-WEB-04 | 5 | 4 | 0 | 1 (diverged on purpose) |
| US-WEB-05 | 3 | 2 | 0 | 1 (a process rule, not a test) |
| US-WEB-06 | 3 | 3 | 0 | 0  |
| US-WEB-07 | 3 | 3 | 0 | 0  |
| US-WEB-08 | 3 | 2 | 0 | 1 (superseded) |
| US-WEB-10 | 5 | 5 | 0 | 0  |
| US-WEB-11 | 4 | 4 | 0 | 0  |
| US-WEB-12 | 4 | 3 | 0 | 1 (partly) |
| US-WEB-13 | 3 | 1 | 0 | 2 (follows US-GH-CRED-01; same as US-WEB-12 "Token field".) |
| US-WEB-14 | 2 | 1 | 0 | 1 (the URL rule is shared and tested (US-WEB-12), but the token) |
| US-WEB-15 | 4 | 4 | 0 | 0  |
| US-WEB-16 | 4 | 0 | 0 | 4 (not proven) |
| US-WEB-17 | 4 | 1 | 0 | 3 (not built in the app; not proven) |
| US-WEB-18 | 2 | 1 | 0 | 1 (the app keeps its own active choice per device (`active_serv) |
| US-WEB-19 | 4 | 0 | 0 | 0  |
| US-WEB-20 | 3 | 2 | 0 | 1 (partly) |
| US-WEB-21 | 3 | 3 | 0 | 0  |
| US-WEB-22 | 6 | 6 | 0 | 0  |
| US-SUB-01 | 4 | 3 | 0 | 1 (partly) |
| US-SUB-02 | 5 | 5 | 0 | 0  |
| US-SUB-03 | 3 | 2 | 0 | 1 (partly) |
| US-SUB-04 | 4 | 4 | 0 | 0  |
| US-SUB-05 | 4 | 4 | 0 | 0  |
| US-SUB-06 | 2 | 1 | 0 | 1 (not proven) |
| US-SUB-07 | 2 | 2 | 0 | 0  |
| US-SUB-08 | 3 | 3 | 0 | 0  |
| US-SUB-09 | 4 | 4 | 0 | 0  |
