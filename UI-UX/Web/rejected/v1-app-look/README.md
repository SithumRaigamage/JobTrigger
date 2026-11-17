# Website design v1 — REJECTED (2026-10-24)

**Status:** Rejected. Kept for reference only. Don't build from it.

**Reason:** it reused the JobTrigger app's own UI/UX: the same dark navy
surfaces (`#0B1120` / `#111A2B`), the same single blue accent (`#2563EB`), the
same rounded cards and the same Inter type. The website must have its own
visual identity as a marketing site, not look like the app's screens
stretched to desktop width.

**What it covered:** every page in epic WEB
([`docs/user-stories/web/17-website.md`](../../../../docs/user-stories/web/17-website.md)):

| File | Page | Stories |
|---|---|---|
| `Main.dc.html` | Home | US-WEB-01, 02 |
| `Features.dc.html` | Features | US-WEB-03 |
| `Tools.dc.html` | Supported tools | US-WEB-04 |
| `Security.dc.html` | Security | US-WEB-05 |
| `Privacy.dc.html` | Privacy policy | US-WEB-06 |
| `Support.dc.html` | Support | US-WEB-06 |
| `Changelog.dc.html` | What's new | US-WEB-08 |
| `SignIn.dc.html` | Sign in | US-WEB-10, 20 |
| `SignUp.dc.html` | Sign up | US-WEB-10 |
| `Servers.dc.html` | My servers | US-WEB-11, 18 |
| `AddServer.dc.html` | Add server | US-WEB-12, 13, 14, 16, 19 |
| `EditServer.dc.html` | Edit / delete server | US-WEB-15 |
| `Saved.dc.html` | Now open the app | US-WEB-17 |
| `Account.dc.html` | Account | US-WEB-20, 21 |
| `Header.dc.html`, `Footer.dc.html` | Shared parts | — |

`canvas.json` is the canvas layout. The `.dc.html` files are design-canvas
sources. Their `/_blob/<id>` image URLs point at the canvas's uploaded copies
of these app screenshots:

| Blob id | Repo file |
|---|---|
| `2be98968…` | `UI-UX/screens/05-home-jenkins-dark/screen.png` |
| `8810b65d…` | `UI-UX/screens/15-build-log/screen.png` |
| `94be59c3…` | `UI-UX/screens/11-job-detail/screen.png` |
| `377e21af…` | `UI-UX/screens/24-home-widget-notification/screen.png` |
| `0ef607e4…` | `UI-UX/screens/14-build-detail/screen.png` |
| `4359d568…` | `UI-UX/screens/04-app-lock/screen.png` |
| `d6a3162f…` | `UI-UX/screens/07-home-github-repos/screen.png` |
| `4a4a8820…` | `UI-UX/screens/08-global-history/screen.png` |

Live canvas: https://claude.ai/artifact/583KygVGgpJ9eC1aje9eyU (private).
