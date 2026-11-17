# UI/UX — JobTrigger website (approved 2026-10-24)

The approved designs for the Next.js website in epic WEB
([`docs/user-stories/web/17-website.md`](../../docs/user-stories/web/17-website.md)):
public marketing pages plus a signed-in setup portal where users paste
Jenkins, GitHub and SonarQube details on a laptop so the phone app picks
them up.

This is **v4**. Earlier attempts, with the reason each was turned down, are
kept in [`rejected/`](rejected/):

| Version | Why it was rejected |
|---|---|
| [v1](rejected/v1-app-look/README.md) | Copied the app's screens too literally |
| [v2](rejected/v2-paper-orange/README.md) | Paper white + orange — didn't match the app |
| [v3](rejected/v3-dark-light-mix/README.md) | App colours, but generic layouts |

## Files

To browse every screen (website, pre-launch and app) from one page, open
[`../preview.html`](../preview.html).


| Folder | What it is |
|---|---|
| [`screens/`](screens/) | One folder per page with `screen.png` (rendered at 1440 px wide, @2x; full page length) and `preview.html` (the same page as static HTML — open it in any browser; links between pages work). Start here. |
| [`design/`](design/) | The editable design-canvas sources (`.dc.html`) plus [`canvas.json`](design/canvas.json), the canvas layout. They stay in one folder because pages mount the shared parts (`Header`, `Footer`, `Sidebar`) by sibling file name. |

Live canvas: https://claude.ai/artifact/Xpi1amGJubJEt5ELg1MeLM (private).
After editing anything in `design/`, regenerate `screens/` with
[`tools/web-design-render`](../../tools/web-design-render/README.md).

## Pages

| Source | Screen | Page | Stories | Layout |
|---|---|---|---|---|
| `Main.dc.html` | [png](screens/01-home/screen.png) | Home | US-WEB-01, 02 | Dark hero with phone + floating UI cards; Trigger → Watch → Fix → Relax timeline; slanted blue setup band; security cards; download |
| `Features.dc.html` | [png](screens/02-features/screen.png) | Features | US-WEB-03 | Fanned screenshot gallery; 9-card colour-coded grid; GitHub Actions spotlight |
| `Tools.dc.html` | [png](screens/03-integrations/screen.png) | Integrations | US-WEB-04 | Tool cards over the hero; capability comparison table; request-a-tool band |
| `Security.dc.html` | [png](screens/04-security/screen.png) | Security | US-WEB-05 | Token-flow architecture diagram; six facts; least-privilege advice |
| `Privacy.dc.html` | [png](screens/05-privacy/screen.png) | Privacy policy | US-WEB-06 | At-a-glance cards + long-form policy with side TOC (draft for legal review) |
| `Support.dc.html` | [png](screens/06-support/screen.png) | Support | US-WEB-06 | Topic tiles; FAQ accordion; contact band |
| `Changelog.dc.html` | [png](screens/07-changelog/screen.png) | Changelog | US-WEB-08 | Release timeline with New / Improved tags |
| `SignIn.dc.html` | [png](screens/08-sign-in/screen.png) | Sign in | US-WEB-10, 20 | Slanted dark band, pitch + floating form; Tweaks: idle / error / rate-limited notices |
| `SignUp.dc.html` | [png](screens/09-sign-up/screen.png) | Sign up | US-WEB-10 | Same shell as sign in |
| `Servers.dc.html` | [png](screens/10-my-servers/screen.png) | My servers | US-WEB-11, 18 | Dashboard: sidebar, per-tool tiles, servers table with masked tokens and "Make active"; Tweaks: error state |
| `AddServer.dc.html` | [png](screens/11-add-server/screen.png) | Add server | US-WEB-12, 13, 14, 16, 19 | 3-step tracker, tool tiles, form + "How do I get this?" panel, Test connection |
| `EditServer.dc.html` | [png](screens/12-edit-server/screen.png) | Edit / delete server | US-WEB-15 | Breadcrumbs, form with blank-to-keep token, delete confirmation dialog |
| `Saved.dc.html` | [png](screens/13-saved/screen.png) | Now open the app | US-WEB-17 | Dark card with phone showing the new server; QR for the store |
| `Account.dc.html` | [png](screens/14-account/screen.png) | Account | US-WEB-20, 21 | Change password, sign out everywhere, delete account |
| `Header.dc.html` | [png](screens/15-header/screen.png) | Marketing header | — | Shared |
| `Footer.dc.html` | [png](screens/16-footer/screen.png) | Footer | — | Shared |
| `Sidebar.dc.html` | [png](screens/17-sidebar/screen.png) | Portal sidebar | — | Shared |

## Design tokens

The website uses the app's tokens from [`../README.md`](../README.md#design-tokens)
— dark `#0B1120` / `#111A2B`, light `#F8FAFC` / white, accent `#2563EB`, the
app's status colours, Inter + JetBrains Mono — with website-only treatments:

- 60–80px headlines with tight tracking; section kickers 12–13 / 700
  uppercase.
- Dot-grid backgrounds on dark sections (`#1F2A3D` 1px dots, 28px grid).
- Slanted solid bands (`skewY(-4deg … -8deg)`) — solid colour, no gradients.
- Status colours used as illustration accents (timeline nodes, chips,
  tool tiles), always with a text label.
- Marketing pages use a top header; portal pages use a dark sidebar.

## Pre-launch pages (coming-soon states)

The app is still in development, so the site launches with some features
not yet available. Rules and the full availability table are in
[US-WEB-22](../../docs/user-stories/web/17-website.md#us-web-22--show-whats-available-and-whats-coming)
and the epic's "Feature availability" section.

These are **separate pages** (`*Soon.dc.html`, screens 18–25). The approved
v4 pages above are unchanged and show the finished product; the site ships
the pre-launch pages until each feature's status in US-WEB-22 flips to
`live`. Pages without a pre-launch variant (Security, Privacy, Support,
Sign in/up, My servers, Edit server, Account, Sidebar) need no change.

| Screen | Source | Change |
|---|---|---|
| [Home](screens/18-home-prelaunch/screen.png) | `MainSoon.dc.html` | Download band → "Coming soon to iPhone and Android"; store badges disabled; QR removed. Hero CTA → "Set up your servers" (works today) + a "Coming soon" note for the apps; GitHub badged Beta, SonarQube Coming soon in the logo strip. |
| [Header](screens/24-header-prelaunch/screen.png) / [Footer](screens/25-footer-prelaunch/screen.png) | `HeaderSoon` / `FooterSoon` | "Get the app" → "App coming soon" badge + "Set up servers"; footer band "The app is coming soon."; "Download" → "Launch updates". |
| [Features](screens/19-features-prelaunch/screen.png) | `FeaturesSoon.dc.html` | GitHub Actions spotlight gets a **Beta** badge and "Runs and logs coming soon". |
| [Integrations](screens/20-integrations-prelaunch/screen.png) | `ToolsSoon.dc.html` | SonarQube → **Coming soon** ("Save your server now — projects and quality gates coming soon"); GitHub → **Beta**; comparison table uses Yes / Beta / Soon / n/a. |
| [Add server](screens/22-add-server-prelaunch/screen.png) | `AddServerSoon.dc.html` | "Test connection" disabled with a **Coming soon** badge; helper "You can test from the app after saving". |
| [Saved](screens/23-saved-prelaunch/screen.png) | `SavedSoon.dc.html` | Store links + QR → "The JobTrigger app is coming soon. Your server is saved and will be waiting." |
| [Changelog](screens/21-changelog-prelaunch/screen.png) | `ChangelogSoon.dc.html` | "v1.0 · Coming soon" (Ships / Beta items) and "After launch · No dates yet" (Next items) instead of `[VERSION]` cards. |

Badges reuse the app's status colours: **Beta** = running blue
(`#DBEAFE` / `#1D4ED8` light, `#10284A` / `#93C5FD` dark), **Coming soon** =
slate (`#F1F5F9` / `#334155` light, `#1E293B` / `#CBD5E1` dark), **Planned** =
dashed slate outline. Disabled actions keep their shape at reduced
emphasis and always say why.

## Placeholders to fill before launch

`[VERSION]`, `[DATE]`, `[COMPANY NAME]`, `[SECURITY EMAIL]`, `[PRIVACY EMAIL]`,
`[N]` working days, `[RETENTION PERIOD FOR BACKUPS]`, store badge artwork
(official Apple / Google badges), real store QR codes, and the "Request a
tool" destination.

## Images

The `/_blob/<id>` URLs point at this canvas's copies of the app screenshots:

| Blob id | Repo file |
|---|---|
| `e1bddce9…` | `UI-UX/screens/05-home-jenkins-dark/screen.png` |
| `31f89858…` | `UI-UX/screens/15-build-log/screen.png` |
| `67b7be20…` | `UI-UX/screens/11-job-detail/screen.png` |
| `78ef8c66…` | `UI-UX/screens/24-home-widget-notification/screen.png` |
| `2f9245af…` | `UI-UX/screens/14-build-detail/screen.png` |
| `8d042c13…` | `UI-UX/screens/04-app-lock/screen.png` |
| `eeca0d0c…` | `UI-UX/screens/08-global-history/screen.png` |
| `228ae7b2…` | `UI-UX/screens/07-home-github-repos/screen.png` |
