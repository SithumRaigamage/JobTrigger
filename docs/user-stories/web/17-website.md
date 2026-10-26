# Epic: WEB — JobTrigger Website (marketing + setup portal)

This epic is **new scope** added on 2026-10-24. It is docs-only and **not
promoted or implemented**. It needs its own task phase and approval before
any code is written (`CLAUDE.md` §9).

**Why it exists.** Users run JobTrigger on their phone, but their Jenkins,
GitHub, and SonarQube tokens are created in a browser on their laptop.
Getting a long token from the laptop onto the phone is the hardest step of
setup today. The website lets a user sign in on the laptop with their
JobTrigger account, paste the details there, and open the app to find the
server ready. The backend already stores credentials per user, so the app
picks them up with no new sync mechanism. The same site also markets the
product to people who don't use it yet.

It has three parts:

1. **Marketing** (US-WEB-01 … US-WEB-08), public pages for visitors.
2. **Setup portal** (US-WEB-10 … US-WEB-21), signed-in pages to manage
   servers and the account.
3. **Launching before the product is finished** (US-WEB-22), one
   feature-status list that drives every "Beta" / "Coming soon" /
   "Planned" badge, so the site never promises what isn't shipped.

"Must" in this epic means *needed to set up a server without retyping a
token on the phone, or needed to publish the app (store-required pages)*.
"Should" means high value for adoption or trust. "Could" means
nice-to-have.

**New technology (needs approval).** The website is a **Next.js** app in a
new top-level folder, `JobTrigger-Web/`. Next.js is not in `CLAUDE.md` §3,
which covers the Flutter client. A "Website" row must be added to §3 in the
same change that creates the folder. The Flutter rules in §3–§5 (Riverpod,
dio, freezed) don't apply to it. Its own conventions are decided in the
task phase.

**Architecture constraint: the browser never holds a full secret.** The
backend's credential list endpoints (`GET /api/credentials`,
`/api/github-credentials`, `/api/sonarqube-credentials`) return secrets
**decrypted in full**, because the mobile app needs them to call each tool
directly. So the website **must not** call the backend from browser
JavaScript. Every backend call goes through the Next.js server (route
handlers / server actions), acting as a backend-for-frontend (BFF):

- The JobTrigger access and refresh tokens (AUD-26) live in an `HttpOnly`,
  `Secure`, `SameSite=Lax` cookie set by the Next.js server, never in
  `localStorage` or readable JS.
- The Next.js server masks every secret before rendering (`••••` + last 4
  characters) and never sends the full value to the browser.
- The JobTrigger backend still sees the same `x-auth-token` header it gets
  from the app. Backend and tool auth schemes stay separate (NFR-SEC-03).

A backend endpoint that returns masked credentials would be cleaner than
masking in the BFF. That is **a flagged risk for the separate backend
track** (NFR-SEC-05), not a precondition for this epic.

**Backend changes this epic needs (backend track, flagged):**
- Add the website's origin to the backend's CORS allow-list (`server.js`
  already reads one), only if any call ends up browser-side. With the BFF
  above, server-to-server calls don't need CORS.
- US-WEB-19 (test connection) needs a new backend endpoint. It is the only
  story that does.

**Web baselines.** These apply to every page in this epic, alongside the
shared NFRs referenced per story:
- **WEB-B1, HTTPS only.** HSTS on, no mixed content.
- **WEB-B2, security headers.** A strict Content-Security-Policy, no
  third-party scripts on signed-in pages (no analytics, chat widgets, or
  tag managers there), `frame-ancestors 'none'`.
- **WEB-B3, no secret leakage.** No secret in URLs, query strings, logs,
  error pages, analytics events, or browser storage.
- **WEB-B4, responsive.** Every page works from 360 px wide upward.
- **WEB-B5, accessible.** WCAG 2.1 AA contrast, keyboard reachable, labelled
  form fields (the web reading of NFR-A11Y-01/02).
- **WEB-B6, same visual language.** Uses the colours, accent, and tone of
  US-DESIGN-* so the site and the app look like one product.
- **WEB-B7, never promise what isn't shipped.** Every feature, tool, or
  action the site mentions reads its availability from one feature-status
  list (US-WEB-22). Anything not `live` is badged and its action disabled.

**Feature availability (as of 2026-10-24).** The app is still in
development, so the site launches before parts of the product exist. This
table is the starting state of US-WEB-22's feature-status list; the source
of truth for app progress is `tasks/README.md`.

| Feature | Status | Why (task tracker) | What the site shows |
|---|---|---|---|
| Jenkins: browse, trigger, logs, history, stages, tests | `live` | Phases 4, 5, 7 done | Live |
| Jenkins: notifications, pinned jobs, widget, nodes, queue, app lock | `live` | Phase 11 done | Live |
| App on the App Store / Google Play | `soon` | `release-checklist.md` pending; app at 1.0.0+1 | "Coming soon to iPhone and Android"; store buttons disabled; no QR code |
| GitHub: accounts, repositories, workflows | `live` | P8 GH-CRED + GH-REPO done | Live |
| GitHub: runs, logs, history | `soon` | P8 in progress (11 of 28) | GitHub badged **Beta**; "Runs and logs coming soon" |
| SonarQube: save a server (app and web) | `live` | P10 SQ-CRED done | Live |
| SonarQube: projects, quality gates, measures, issues | `soon` | P10 in progress (6 of 16) | SonarQube badged **Coming soon** |
| Website: sign in, add/edit/delete servers, set active, account | `live` | Backend endpoints exist | Live |
| Website: test connection (US-WEB-19) | `soon` | Needs a new backend endpoint (backend track) | Button shown disabled, "Coming soon" |
| Password reset | `soon` | Deferred, US-AUTH-08 in `tasks/backlog.md` | "Forgot?" links to support (already the case) |
| GitLab CI, CircleCI | `planned` | Docs-only epics GL, CC | "Planned · no date yet" |
| Changelog entries | `soon` | No public release yet | One "First public release — coming soon" entry |

**Decisions taken for launch (2026-10-24), changeable later:**
- The download section says **"Coming soon"** with no launch date until
  one is committed in `release-checklist.md`.
- **No "notify me" email signup** at launch. Collecting emails needs a new
  backend endpoint and a privacy-policy change; it is logged in
  `tasks/backlog.md` as a backend-track item. Until then, "coming soon"
  copy points to the changelog.

---

## Part 1 — Marketing

### US-WEB-01 — Home page explains the product at a glance

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** none

As a DevOps engineer who hasn't heard of JobTrigger
I want to understand what it does within a few seconds
So that I can decide whether to install it

**Acceptance Criteria**
- Scenario: First visit
  Given I open the site's root URL
  Then I see a one-sentence value statement (trigger and watch CI builds
  from your phone), real app screenshots, the supported tool logos, and a
  primary "Get the app" call to action above the fold
- Scenario: Honest claims
  Then every feature or tool named on the page exists in the current
  released app. Planned tools are labelled "Planned" (see US-WEB-04)
- Scenario: Signed-in shortcut
  Given I am signed in to the portal
  Then the header shows "My servers" instead of "Sign in"

**Security & Privacy Notes**
- Screenshots use demo data only: no real server URLs, job names, or
  usernames.

**UI / Design Notes**
- WEB-B6. Screenshots inside a device frame, light and dark variants.

**Non-Functional Notes**
- WEB-B1, WEB-B4, WEB-B5. Largest contentful paint under 2.5 s on a
  mid-range phone over 4G.

---

### US-WEB-02 — Download buttons, with a QR code on desktop

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-01

As a visitor
I want to get the app onto my phone easily
So that I can start using it

**Acceptance Criteria**
- Scenario: On a phone
  Given I visit on iOS or Android
  Then I see the matching store badge first, linking to the App Store or
  Google Play listing
- Scenario: On a laptop
  Given I visit on a desktop browser
  Then both badges show, plus a QR code that opens the store listing when
  scanned with a phone camera
- Scenario: Not yet published (the state at launch)
  Given the `app-store` feature in US-WEB-22 is `soon`
  Then the section reads "Coming soon to iPhone and Android", the store
  badges render as disabled (not links, `aria-disabled="true"`), the QR
  code is not shown, and every "Get the app" button elsewhere on the site
  reads "Coming soon" and points to `/changelog` instead of a store
- Scenario: One store ships first
  Given only one store listing is live
  Then that badge is a real link and the other stays disabled with
  "Coming soon"; the QR code appears only when at least one listing is live
- Scenario: No dead links
  Then no store badge or QR code ever points at a listing that doesn't
  exist

**Security & Privacy Notes**
- The QR code contains only a public store URL, never account or server
  data.

**UI / Design Notes**
- Official store badge artwork, used per Apple's and Google's guidelines.

**Non-Functional Notes**
- WEB-B4, WEB-B5 (the QR code has a text link alternative).

---

### US-WEB-03 — Features page

**Priority:** Should
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-01

As a visitor comparing tools
I want to see what JobTrigger can do
So that I know whether it covers my workflow

**Acceptance Criteria**
- Scenario: Feature list
  Then the page covers triggering builds (including parameters), live
  console logs, build history, build notifications, pinned jobs and the
  home-screen widget, multiple servers, and the biometric app lock, each
  with a short description and screenshot
- Scenario: Accuracy
  Then each listed feature maps to a shipped story (`tasks/README.md`
  status "done"). Unshipped work isn't listed as available
- Scenario: Partly shipped tools
  Given a tool is only partly built (GitHub Actions today: runs, logs and
  history are `soon`)
  Then its section carries a **Beta** badge and names what is coming,
  e.g. "Runs and logs coming soon"

**Security & Privacy Notes**
- Demo data only in screenshots, as in US-WEB-01.

**UI / Design Notes**
- WEB-B6.

**Non-Functional Notes**
- WEB-B4, WEB-B5.

---

### US-WEB-04 — Supported tools page, with "request a tool"

**Priority:** Should
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-01

As a visitor who uses a particular CI tool
I want to know if it is supported
So that I don't install an app that can't help me

**Acceptance Criteria**
- Scenario: Supported tools
  Then Jenkins, GitHub Actions, and SonarQube are listed with what each one
  supports today, each with a status badge from US-WEB-22: Jenkins
  "Full support", GitHub Actions "Beta", SonarQube "Coming soon"
- Scenario: SonarQube before its screens ship
  Given SonarQube projects and quality gates are `soon`
  Then the card says "Save your server now — projects and quality gates
  coming soon", and the comparison table shows "Soon" for those rows,
  never "Yes"
- Scenario: Comparison table
  Then each capability cell is one of "Yes", "Beta", "Soon", or "n/a",
  driven by US-WEB-22, with the word always present (never colour or an
  icon alone)
- Scenario: Planned tools
  Then GitLab CI and CircleCI are listed as "Planned", with no promised date
- Scenario: Request a tool
  Then a "Request a tool" link goes to the same destination as the app's
  tool-selection "request a tool" link, so requests land in one place

**Security & Privacy Notes**
- None beyond the baselines.

**UI / Design Notes**
- WEB-B6. Tool logos follow each vendor's brand guidelines.

**Non-Functional Notes**
- WEB-B4, WEB-B5.

---

### US-WEB-05 — Security page explains how tokens are handled

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-01

As a DevOps engineer responsible for my company's CI
I want to know where my tokens go and how they are protected
So that I can decide whether I'm allowed to use the app

**Acceptance Criteria**
- Scenario: Plain explanation
  Then the page explains, in plain words: tokens are encrypted at rest on
  the JobTrigger backend (AUD-03) and kept in the phone's secure storage;
  the app talks to Jenkins, GitHub, and SonarQube directly, not through a
  JobTrigger proxy; the website never shows a saved token in full
- Scenario: Least privilege advice
  Then it recommends a dedicated API token with the smallest scopes needed,
  and links to US-WEB-16's how-to steps
- Scenario: Accuracy
  Then every statement is checked against the code before publishing and
  re-checked when the security design changes

**Security & Privacy Notes**
- Describes the design. It must not disclose internals that help an
  attacker (key names, infrastructure hostnames).

**UI / Design Notes**
- WEB-B6. Short sections with a simple diagram: phone ↔ tool, phone ↔
  backend, laptop ↔ website ↔ backend.

**Non-Functional Notes**
- WEB-B4, WEB-B5.

---

### US-WEB-06 — Privacy policy, terms, and support pages

**Priority:** Must
**Source:** new — website epic, 2026-10-24; P6-02 (app info links)
**Dependencies:** none

As a user, or an app store reviewer
I want a privacy policy, terms, and a way to get support
So that I know my rights and the app can be published

**Acceptance Criteria**
- Scenario: Pages exist
  Then `/privacy`, `/terms`, and `/support` exist at stable URLs
- Scenario: App links resolve
  Given the app info screen opens the privacy, terms, and support links
  served by `GET /api/appinfo`
  Then those values are updated to point at these pages, and each link
  opens the right page
- Scenario: Support contact
  Then `/support` shows the support email (the same `mailto:` the app uses)
  and short answers to common setup problems

**Security & Privacy Notes**
- The privacy policy accurately lists what the backend stores (account
  email, hashed password, encrypted tool credentials) and states that the
  app holds no analytics or crash reporting today (backlog, P6-08).

**UI / Design Notes**
- WEB-B6. Readable long-form text layout.

**Non-Functional Notes**
- WEB-B4, WEB-B5.

---

### US-WEB-07 — Link previews and search visibility

**Priority:** Should
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-01

As someone sharing JobTrigger with my team
I want the link to show a proper preview
So that people know what it is before clicking

**Acceptance Criteria**
- Scenario: Shared link
  Given a public page URL is pasted into Slack, Teams, or X
  Then a title, description, and preview image appear (Open Graph and
  Twitter card tags)
- Scenario: Search
  Then public pages have unique titles and descriptions, a sitemap, and a
  `robots.txt`
- Scenario: Portal is hidden
  Then every portal page (US-WEB-10 onward) is `noindex` and excluded from
  the sitemap

**Security & Privacy Notes**
- Portal pages are never indexed or cached by search engines.

**UI / Design Notes**
- One 1200×630 preview image per public page, or a shared default.

**Non-Functional Notes**
- WEB-B1.

---

### US-WEB-08 — "What's new" changelog

**Priority:** Should (raised from Could on 2026-10-24: every "Coming soon"
link on the site points here, US-WEB-22)
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-01

As an existing user
I want to see what changed in each release
So that I notice new features

**Acceptance Criteria**
- Scenario: Before the first release (the state at launch)
  Given no public release exists yet
  Then the page shows one entry, "First public release — coming soon",
  listing what the first release will include (the `live` features in
  US-WEB-22) and what follows it (the `soon` ones), with no invented
  version numbers or dates
- Scenario: Release list
  Then each app release has an entry with version, date, and plain-language
  highlights, newest first
- Scenario: Source
  Then entries are authored as files in the website repo (no CMS), so a
  release adds its notes in the same pull request

**Security & Privacy Notes**
- Release notes never mention unfixed vulnerabilities.

**UI / Design Notes**
- WEB-B6.

**Non-Functional Notes**
- WEB-B4, WEB-B5.

---

## Part 2 — Setup portal

### US-WEB-10 — Sign in or sign up with my JobTrigger account

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-AUTH-01, US-AUTH-02

As a JobTrigger user at my laptop
I want to sign in with the same account I use in the app
So that servers I add here appear in the app

**Acceptance Criteria**
- Scenario: Sign in
  Given I enter my email and password on `/sign-in`
  When the Next.js server calls `POST /api/auth/login` and it succeeds
  Then the server stores the access and refresh tokens in an `HttpOnly`
  cookie and sends me to "My servers" (US-WEB-11)
- Scenario: Sign up
  Given I have no account
  Then `/sign-up` creates one via `POST /api/auth/signup`, with the same
  validation rules as the app (US-AUTH-01)
- Scenario: Wrong credentials
  Then I see "Email or password is incorrect" (`AuthFailure` copy), never a
  raw backend message or status code
- Scenario: Too many attempts
  Given the backend's login rate limiter rejects the request
  Then I see "Too many attempts, try again in a few minutes"
  (`RateLimitFailure` copy)
- Scenario: Token refresh
  Given my 15-minute access token expires while I'm using the portal
  Then the Next.js server refreshes it via `POST /api/auth/refresh` without
  interrupting me. If the refresh fails, I'm sent to `/sign-in` with my
  unsaved form kept (US-WEB-20)

**Security & Privacy Notes**
- Tokens never reach browser JavaScript (see the epic's architecture
  constraint). Forms are protected against CSRF (`SameSite` cookie plus a
  token on every state-changing action).
- Forgot-password is not offered, because the backend has no reset flow
  (backlog). Copy says "Reset your password from the app's support page"
  until it exists.

**UI / Design Notes**
- WEB-B6. The same fields and copy as the app's login screen.

**Non-Functional Notes**
- NFR-SEC-03, NFR-SEC-04, NFR-SEC-07, WEB-B1–B5.

---

### US-WEB-11 — See my servers, with secrets masked

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-10

As a signed-in user
I want to see every server and account I've set up
So that I know what's already configured

**Acceptance Criteria**
- Scenario: List
  Then "My servers" shows three groups (Jenkins, GitHub, SonarQube) from
  the three backend list endpoints, each item showing its name, URL (or
  GitHub username), and which one is active
- Scenario: Masked secrets
  Then every token or password is shown as `••••` plus its last 4
  characters. The full value never appears in the HTML, the page data, or
  the network responses sent to the browser
- Scenario: Empty
  Given I have nothing set up
  Then each group shows an "Add" call to action
- Scenario: Backend unavailable
  Then I see "Can't reach JobTrigger right now" (`NetworkFailure` /
  `ServerFailure` copy) with a retry button

**Security & Privacy Notes**
- Masking happens on the Next.js server (see the epic's architecture
  constraint). A backend masked-list endpoint is flagged for the backend
  track (NFR-SEC-05).
- Pages are sent with `Cache-Control: no-store`.

**UI / Design Notes**
- WEB-B6. One card per server, the same tone as the app's settings list.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-04, WEB-B1–B5.

---

### US-WEB-12 — Add a Jenkins server

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-11, US-CRED-01

As a signed-in user with my Jenkins tab open on my laptop
I want to paste my Jenkins details into a form
So that I don't have to transfer the token to my phone

**Acceptance Criteria**
- Scenario: Save
  Given I enter a name, Jenkins URL, username, and API token
  When I press Save
  Then the Next.js server calls `POST /api/credentials` with the same
  fields the app sends, and I go to the "Now open the app" screen
  (US-WEB-17)
- Scenario: Validation
  Then the URL must be `https://` (or `http://` with a visible warning, the
  same rule as the app), and the fields are trimmed and validated with the
  app's rules before any network call (NFR-SEC-02)
- Scenario: Duplicate
  Given the backend rejects a duplicate
  Then I see the same copy the app shows for that case
- Scenario: Token field
  Then the token field is masked with a show/hide toggle, `autocomplete`
  set to `off`, and spellcheck off

**Security & Privacy Notes**
- The token goes browser → Next.js server → backend over HTTPS only, and is
  never logged at any hop.

**UI / Design Notes**
- WEB-B6. The same field order and labels as the app's Jenkins edit sheet,
  with a "How do I get this?" link (US-WEB-16).

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-02, NFR-SEC-04, WEB-B1–B5.

---

### US-WEB-13 — Add a GitHub account

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-11, US-GH-CRED-01

As a signed-in user
I want to paste a GitHub token into a form
So that GitHub Actions works in the app without retyping it

**Acceptance Criteria**
- Scenario: Save
  Given I enter a name and a personal access token
  Then the Next.js server calls `POST /api/github-credentials` with the
  fields the app sends, and I go to US-WEB-17
- Scenario: Validation
  Then the token format is checked with the app's rules before submitting
- Scenario: Token field
  Then it is masked, the same as US-WEB-12

**Security & Privacy Notes**
- As US-WEB-12. The how-to (US-WEB-16) recommends a fine-grained token
  limited to the repositories needed.

**UI / Design Notes**
- WEB-B6. Mirrors the app's GitHub credential sheet.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-02, NFR-SEC-04, WEB-B1–B5.

---

### US-WEB-14 — Add a SonarQube server

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-11, US-SQ-CRED-01

As a signed-in user
I want to paste my SonarQube URL and token into a form
So that code-quality checks work in the app without retyping them

**Acceptance Criteria**
- Scenario: Save
  Given I enter a name, server URL, and token
  Then the Next.js server calls `POST /api/sonarqube-credentials` with the
  fields the app sends, and I go to US-WEB-17
- Scenario: Validation and token field
  Then the same rules as US-WEB-12 apply

**Security & Privacy Notes**
- As US-WEB-12.

**UI / Design Notes**
- WEB-B6. Mirrors the app's SonarQube credential sheet.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-02, NFR-SEC-04, WEB-B1–B5.

---

### US-WEB-15 — Edit or delete a server

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-12, US-WEB-13, US-WEB-14

As a signed-in user
I want to change or remove a saved server
So that I can rotate tokens and clean up old servers from my laptop

**Acceptance Criteria**
- Scenario: Edit without re-entering the token
  Given I open a server's edit form
  Then the token field is empty with "Leave blank to keep the current
  token". If I leave it blank, the Next.js server sends the existing value
  it read server-side, which never goes to the browser
- Scenario: Rotate a token
  Given I paste a new token
  Then `PUT /api/<type>/:id` saves it
- Scenario: Delete
  Given I press Delete
  Then a confirmation names the server. On confirm, `DELETE /api/<type>/:id`
  runs and the list updates
- Scenario: Not found
  Given the server was deleted elsewhere (for example in the app)
  Then I see "This server no longer exists" (`NotFoundFailure` copy) and
  return to the list

**Security & Privacy Notes**
- Edit and delete requests are CSRF-protected, as in US-WEB-10.

**UI / Design Notes**
- WEB-B6. Delete is styled as destructive and is never the default button.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-04, WEB-B1–B5.

---

### US-WEB-16 — "How do I get this token?" help

**Priority:** Should
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-12, US-WEB-13, US-WEB-14

As a user who has never created an API token
I want step-by-step instructions next to the field
So that I can finish setup without searching the web

**Acceptance Criteria**
- Scenario: Jenkins
  Then the help shows the click path (your name → Security → API Token →
  Add new token), explains it differs from the account password, and links
  to the server's own token page when the URL is already entered
  (`<url>/me/security`, Jenkins 2.x)
- Scenario: GitHub
  Then the help links to GitHub's token settings and lists exactly which
  permissions the app needs to read workflows and trigger runs
- Scenario: SonarQube
  Then the help shows where to create a user token
- Scenario: Opens alongside the form
  Then help opens in a panel or new tab without losing what I've typed

**Security & Privacy Notes**
- Always recommends the least-privilege token and an expiry date.

**UI / Design Notes**
- WEB-B6. Short numbered steps, with screenshots where helpful.

**Non-Functional Notes**
- WEB-B4, WEB-B5.

---

### US-WEB-17 — "Now open the app" after saving

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-12, US-WEB-13, US-WEB-14

As a user who just saved a server on the website
I want clear next steps, and the app to show the server immediately
So that I can start using it without restarting the app

**Acceptance Criteria**
- Scenario: Confirmation
  Then I see "Saved. Open JobTrigger on your phone, your server is ready",
  with "Add another" and "Back to my servers" actions
- Scenario: App picks it up on return (app change)
  Given the app is open in the background, signed in to the same account
  When I switch back to it
  Then it reloads the credential lists for every tool on resume, and the
  new server appears without a restart or pull-to-refresh
- Scenario: App not installed
  Then the confirmation also shows the store links / QR from US-WEB-02
- Scenario: App not yet released (the state at launch)
  Given the `app-store` feature in US-WEB-22 is `soon`
  Then instead of store links the confirmation says "The JobTrigger app is
  coming soon. Your server is saved and will be waiting when you install
  it." with a link to the changelog

**Security & Privacy Notes**
- The confirmation never repeats the token.

**UI / Design Notes**
- WEB-B6 on the web. In the app, the reload is silent unless it fails, in
  which case the existing settings error state applies.

**Non-Functional Notes**
- App side: NFR-PLAT-01, NFR-TEST-01 (a notifier test for reload on resume).
  Web side: WEB-B4, WEB-B5.

---

### US-WEB-18 — Choose the default server

**Priority:** Should
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-11

As a user with several servers
I want to choose which one the app uses
So that the app opens on the right one

**Acceptance Criteria**
- Scenario: Set active
  Given I press "Make active" on a server
  Then the Next.js server calls `POST /api/<type>/switch/:id`, and the list
  shows the new active server
- Scenario: App follows
  Then the app uses the new active server after its next reload
  (US-WEB-17)

**Security & Privacy Notes**
- CSRF-protected, as in US-WEB-10.

**UI / Design Notes**
- WEB-B6. The active badge doesn't rely on colour alone (NFR-A11Y-03).

**Non-Functional Notes**
- NFR-A11Y-03, WEB-B1–B5.

---

### US-WEB-19 — Test connection before saving

**Priority:** Could
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-12, US-WEB-13, US-WEB-14

As a user filling in a server form
I want to check that the details work before saving
So that I don't discover a typo later on my phone

**Acceptance Criteria**
- Scenario: Before the backend endpoint exists (the state at launch)
  Given the `test-connection` feature in US-WEB-22 is `soon`
  Then the "Test connection" button is shown disabled with a "Coming soon"
  badge and the helper text "You can test from the app after saving", and
  saving works without it
- Scenario: Success
  Given I press "Test connection"
  Then I see "Connected as <username>" from the tool
- Scenario: Failure
  Then I see the same copy the app's test connection uses for
  `AuthFailure`, `NetworkFailure`, `NotFoundFailure`, and
  `ServerFailure(statusCode)`
- Scenario: Private network
  Given the server is only reachable from my office network or VPN
  Then I see "We can't reach this server from the internet. Save it anyway
  and test from the app on your network", and Save stays available

**Security & Privacy Notes**
- **Flagged backend-track risk (NFR-SEC-05).** A browser can't call Jenkins
  directly (CORS), so this needs a new backend endpoint that makes the
  outbound request. That is server-side request forgery (SSRF) surface:
  the endpoint must block private, loopback, and link-local addresses,
  limit redirects, time out quickly, and be rate-limited. Not built until
  the backend track approves it.

**UI / Design Notes**
- WEB-B6.

**Non-Functional Notes**
- NFR-SEC-04, NFR-SEC-05, WEB-B1–B5.

---

### US-WEB-20 — Sign out, and sign out automatically when idle

**Priority:** Must
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-10

As a user on a shared or work laptop
I want to sign out, and be signed out when I walk away
So that nobody else can see or change my servers

**Acceptance Criteria**
- Scenario: Sign out
  Given I press "Sign out"
  Then the session cookie is cleared and I return to the home page
- Scenario: Idle timeout
  Given there's no activity for 30 minutes
  Then the next action sends me to `/sign-in`. A form I was typing in is
  kept in memory for that tab only, without the token field
- Scenario: Sign out everywhere
  Then a "Sign out of all devices" action calls `POST /api/auth/logout-all`
  after a confirmation that warns it also signs out the phone app

**Security & Privacy Notes**
- Clearing the website cookie doesn't revoke the backend refresh token on
  its own. Revocation goes through `logout-all`. A per-session revoke
  endpoint is flagged for the backend track (NFR-SEC-05).

**UI / Design Notes**
- WEB-B6.

**Non-Functional Notes**
- NFR-SEC-07, WEB-B1–B5.

---

### US-WEB-21 — Account settings: change password or delete account

**Priority:** Could
**Source:** new — website epic, 2026-10-24
**Dependencies:** US-WEB-10

As a signed-in user
I want to manage my account from the website
So that I can do it from a laptop as well as the app

**Acceptance Criteria**
- Scenario: Change password
  Then `POST /api/auth/password` is called with my current and new
  password, using the same rules and copy as the app's account dialog
- Scenario: Delete account
  Given I confirm by typing my email and entering my password
  Then `DELETE /api/auth/account` runs, I'm signed out, and I see a
  confirmation that all my saved servers were removed
- Scenario: Rate limited
  Then the backend's limiter on both endpoints maps to `RateLimitFailure`
  copy

**Security & Privacy Notes**
- Both actions require the current password even with a valid session.

**UI / Design Notes**
- WEB-B6. Delete is in a separate "Danger zone" section.

**Non-Functional Notes**
- NFR-SEC-04, NFR-SEC-07, WEB-B1–B5.

---

## Part 3 — Launching before the product is finished

### US-WEB-22 — Show what's available and what's coming

**Priority:** Must
**Source:** new — owner request 2026-10-24 ("the app is still in
development; some pages can't be built for the complete product")
**Dependencies:** US-WEB-01 … US-WEB-21 (every page reads from it)

As a visitor or user
I want the site to be honest about what works today and what is coming
So that I don't sign up for something the app can't do yet

**Acceptance Criteria**
- Scenario: One feature-status list
  Then the site has a single, version-controlled list of features, each
  with a status of `live`, `beta`, `soon`, or `planned`, seeded from the
  epic's "Feature availability" table. No page hard-codes "coming soon"
  copy; it reads the status
- Scenario: Flipping a status
  Given a feature moves from `soon` to `live` (for example the app reaches
  the stores)
  When the list is changed and the site is redeployed
  Then every badge, button, comparison cell, and "coming soon" sentence for
  that feature updates, with no page edits
- Scenario: Status badges
  Then `beta` shows a blue "Beta" pill, `soon` a grey "Coming soon" pill,
  and `planned` a dashed "Planned" pill, each with its text label (status
  is never shown by colour alone)
- Scenario: Disabled actions
  Given an action belongs to a `soon` or `planned` feature
  Then its button or link renders disabled (`aria-disabled="true"`, not
  focusable as a link, not a dead URL) and says why ("Coming soon")
- Scenario: Where "coming soon" points
  Then any "coming soon" message that offers a next step links to the
  changelog (US-WEB-08). There is no email signup until the backend-track
  item "Launch notify-me signup" in `tasks/backlog.md` is approved
- Scenario: Keeping it true
  Then a feature is only set to `live` when its stories are "done" in
  `tasks/README.md`, and the PR that ships a feature in the app (or the
  release that puts it in the stores) updates the list in the same change
  or a linked follow-up

**Security & Privacy Notes**
- None beyond the baselines. The list is static content, not user data.

**UI / Design Notes**
- WEB-B6. Badges reuse the app's status colours: Beta = running blue,
  Coming soon = aborted/none slate, Planned = dashed slate outline.
- Designs: the pre-launch pages (`*Soon.dc.html`, screens 18–25) in
  `UI-UX/Web/`, listed under "Pre-launch pages" in `UI-UX/Web/README.md`.
  They are separate from the approved v4 pages, which stay unchanged.

**Non-Functional Notes**
- WEB-B5, WEB-B7, NFR-A11Y-03.
