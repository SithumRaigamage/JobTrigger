# UI/UX — JobTrigger redesign (approved 2026-10-23)

**Browse everything in one place: open [`preview.html`](preview.html)** — every
app and website screen as a thumbnail, each linking to its preview.
Two focused website views: [`preview-launch.html`](preview-launch.html) (the
site as it launches, with coming-soon pages) and
[`preview-complete.html`](preview-complete.html) (the finished product).

The approved screen designs for the Flutter app's modernised look. Each
screen has its own folder under [`screens/`](screens/):

| File | What it is |
|---|---|
| `screen.png` | The design rendered at 390 × 844 pt (@2x). Start here. |
| `preview.html` | The same screen as a standalone page — open it in any browser. |
| `design.dc.html` | The editable source from the design canvas. |

[`canvas.json`](canvas.json) is the canvas layout the sources came from.
Implementation is tracked in
[`tasks/phase-14-ui-redesign.md`](../tasks/phase-14-ui-redesign.md), one
task per screen.

## Screens

| # | Screen | Design | Implemented in |
|---|---|---|---|
| 01 | Login | [png](screens/01-login/screen.png) | `features/auth/login_screen.dart` |
| 02 | Signup | [png](screens/02-signup/screen.png) | `features/auth/signup_screen.dart` |
| 03 | Tool selection | [png](screens/03-tool-selection/screen.png) | `features/tool_selection/tool_selection_screen.dart` |
| 04 | App lock | [png](screens/04-app-lock/screen.png) | `features/app_lock/app_lock_gate.dart` |
| 05 | Home — Jenkins (dark) | [png](screens/05-home-jenkins-dark/screen.png) | `features/home/home_screen.dart` |
| 06 | Home — Jenkins (light) | [png](screens/06-home-jenkins-light/screen.png) | `features/home/home_screen.dart` (light theme) |
| 07 | Home — GitHub repos | [png](screens/07-home-github-repos/screen.png) | `features/github/github_repo_screen.dart` |
| 08 | Global history | [png](screens/08-global-history/screen.png) | `features/history/global_history_screen.dart` |
| 09 | Settings | [png](screens/09-settings/screen.png) | `features/settings/settings_screen.dart` |
| 10 | Profile | [png](screens/10-profile/screen.png) | `features/profile/profile_screen.dart` |
| 11 | Job detail | [png](screens/11-job-detail/screen.png) | `features/job_detail/job_detail_screen.dart` |
| 12 | Stage detail sheet | [png](screens/12-stage-detail-sheet/screen.png) | `features/job_detail/stage_detail_sheet.dart` |
| 13 | Job history | [png](screens/13-job-history/screen.png) | `features/history/job_history_screen.dart` |
| 14 | Build detail | [png](screens/14-build-detail/screen.png) | `features/build_detail/build_detail_screen.dart` |
| 15 | Build log | [png](screens/15-build-log/screen.png) | `features/build_log/build_log_screen.dart` |
| 16 | Nodes | [png](screens/16-nodes/screen.png) | `features/nodes/nodes_screen.dart` |
| 17 | Queue | [png](screens/17-queue/screen.png) | `features/queue/queue_screen.dart` |
| 18 | GitHub workflows | [png](screens/18-github-workflows/screen.png) | `features/github/github_workflow_list_screen.dart` |
| 19 | Open link | [png](screens/19-open-link/screen.png) | `features/open_link/open_link_screen.dart` |
| 20 | App info | [png](screens/20-app-info/screen.png) | `features/app_info/app_info_screen.dart` |
| 21 | Edit server sheet | [png](screens/21-edit-server-sheet/screen.png) | `features/settings/server_edit_bottom_sheet.dart` (+ GitHub/SonarQube sheets) |
| 22 | Change password dialog | [png](screens/22-change-password-dialog/screen.png) | `features/profile/account_dialogs.dart` |
| 23 | Unknown route | [png](screens/23-unknown-route/screen.png) | `navigation/app_router.dart` |
| 24 | Home widget + notification | [png](screens/24-home-widget-notification/screen.png) | `features/home_widget/`, `features/notifications/`, native widgets |

Paths in the last column are under `JobTrigger-Frontend/lib/presentation/`.

## Design tokens

Every screen is built from these. In code they live in
`JobTrigger-Frontend/lib/core/theme/`.

**Type.** Inter for interface text; JetBrains Mono for anything a CI tool
printed or counts — build numbers, durations, branches, URLs, file names,
parameter names, console output. Screen titles 28–30 / 700; section labels
12 / 600 uppercase with 0.06em tracking; body 15; secondary 12–13.

**Surfaces (dark).** Background `#0B1120`, card `#111A2B` with a 1px
`#1F2A3D` border, raised control `#1E293B`, nav bar `#0F172A`, console
`#060A14`. Text `#F1F5F9`, secondary `#CBD5E1`, muted `#94A3B8` (the
lowest text shade allowed; 6.6:1 on a card).

**Surfaces (light).** Background `#F8FAFC`, card `#FFFFFF` with a 1px
`#E2E8F0` border and a 1px shadow, text `#0F172A`, muted `#475569`.

**Status.** Every status carries a text label; colour is the second
signal, never the only one. Dark: tint background + light text. Light:
pale background + 700/800 text.

| Status | Dark bg / text | Light bg / text |
|---|---|---|
| Success | `#0F2E1F` / `#86EFAC` | `#DCFCE7` / `#15803D` |
| Failed | `#3A1418` / `#FCA5A5` | `#FEE2E2` / `#B91C1C` |
| Unstable | `#3A2210` / `#FDBA74` | `#FFEDD5` / `#C2410C` |
| Running | `#10284A` / `#93C5FD` | `#DBEAFE` / `#1D4ED8` |
| Aborted / none | `#1E293B` / `#CBD5E1` | `#F1F5F9` / `#334155` |

**Accent.** One app-wide accent, `#2563EB` (white text on it is 5.2:1),
for the primary button, the selected tab and switches. The CI tool's brand
colour is used only on the tool's own logo tile — no longer as the app
accent, so Jenkins red no longer competes with the "failed" red.

**Shape.** Cards 16–18 radius, inputs and buttons 12–14, pills fully
rounded. Touch targets at least 44 × 44. Primary button 52 high.

## Website

The approved designs for the JobTrigger website (epic WEB — marketing pages
and the setup portal) live in [`Web/`](Web/README.md). They reuse the design
tokens above with website-only treatments; see that README.
