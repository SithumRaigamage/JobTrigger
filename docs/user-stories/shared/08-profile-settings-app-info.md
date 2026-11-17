# Epic: PROF — Profile, Settings & App Info

Covers the profile screen, appearance/theme control, the app info screen
(backed by `GET /api/appinfo`), and the persistent bottom tab bar that ties
all top-level destinations together.

---

### US-PROF-01 — View my profile

**Priority:** Must
**Source:** tasks/phase-6-polish-release.md (P6-01)
**Dependencies:** US-AUTH-02 or US-AUTH-03

As a logged-in user
I want to see my account email and have quick access to logout
So that I know which account I'm using and can manage my session

**Acceptance Criteria**
- Scenario: Profile displays current user
  Given I open the profile screen
  Then my email (from `authNotifierProvider`, already in memory — no extra
  network call) is displayed, along with the app version footer and a
  logout action
- Scenario: No network dependency
  Given I have no connectivity
  Then the profile screen still renders correctly since it reads only local
  auth state, distinguishing it from screens that genuinely need a live
  fetch

**Security & Privacy Notes**
- Only the email is shown — no password, token, or other secret ever
  appears on this screen.

**UI / Design Notes**
- Profile card uses the glass treatment (US-DESIGN-01); logout action
  reuses US-AUTH-04's confirmation pattern.

**Non-Functional Notes**
- NFR-SEC-01

---

### US-PROF-02 — Change appearance (system/light/dark)

**Priority:** Must
**Source:** tasks/phase-1-core-infrastructure.md (P1-06, P1-07); tasks/phase-6-polish-release.md (P6-03)
**Dependencies:** —

As a user
I want to choose between system, light, or dark appearance
So that the app matches my device settings or my personal preference

**Acceptance Criteria**
- Scenario: Selecting a mode
  Given I open the appearance picker in Settings
  When I select System, Light, or Dark
  Then the app's theme updates immediately and the choice is persisted
  locally (`shared_preferences` — non-secret, per the locked tech stack)
  so it survives app restart
- Scenario: System mode follows OS changes
  Given "System" is selected
  When the OS-level appearance changes while the app is open (or after
  restart)
  Then the app's theme follows it automatically
- Scenario: Glassmorphism applies to both modes
  Given either Light or Dark is explicitly selected
  Then the glass surfaces render using that mode's dedicated light/dark
  tokens (US-DESIGN-02) — never a mismatched blend of the two

**Security & Privacy Notes**
- None — theme preference is explicitly non-secret and correctly belongs in
  `shared_preferences`, not secure storage.

**UI / Design Notes**
- Picker itself is a glass segmented control; this story is the direct
  consumer of US-DESIGN-02's light/dark token requirement.

**Non-Functional Notes**
- NFR-A11Y-01

---

### US-PROF-03 — View app info

**Priority:** Should
**Source:** tasks/phase-6-polish-release.md (P6-02)
**Dependencies:** —

As a user
I want to see the app's version, and reach privacy policy, terms, licenses,
and support contact
So that I can verify what I'm running and get help or review legal
information if needed

**Acceptance Criteria**
- Scenario: App info loads
  Given I open the App Info screen
  Then it shows the installed app's real version/build number (via
  `package_info_plus`, not a hardcoded string) alongside data fetched from
  `GET /api/appinfo` (min supported version, release notes link) cached
  with a short TTL
- Scenario: Privacy policy / terms / licenses links
  Given I tap the privacy policy, terms, or licenses link
  Then it opens via `url_launcher` in the appropriate external handler
  (browser or in-app license viewer), matching `AppInfoView.swift`'s
  original `openURL` usage
- Scenario: Support email link
  Given I tap the support contact
  Then it opens a `mailto:` link via `url_launcher`, matching the original
  SwiftUI app's `openURL` behavior
- Scenario: App info fetch fails
  Given `GET /api/appinfo` fails
  Then the screen still shows the local version/build info (which needs no
  network call) and shows a non-blocking failure only for the
  backend-sourced fields
- Scenario: Forced update gate (if min version not met)
  Given the backend's `minSupportedVersion` exceeds my installed version
  Then the app clearly prompts that an update is required, consistent with
  what `AppInfo`'s `minSupportedVersion` field exists to gate per
  `docs/data-models.md`

**Security & Privacy Notes**
- Outbound links (privacy policy, terms, mailto) only ever launch via
  `url_launcher` to hosts declared in `docs/`-documented config — no
  arbitrary/user-influenced URLs are ever opened from this screen.

**UI / Design Notes**
- Standard glass card list of links; consistent with Settings' visual
  language.

**Non-Functional Notes**
- NFR-SEC-01

---

### US-PROF-04 — Navigate the app via a persistent bottom tab bar

**Priority:** Must
**Source:** tasks/phase-6-polish-release.md (P6-14)
**Dependencies:** US-TREE-01, US-HIST-01, US-CRED-01, US-PROF-01

As a user
I want Home, History, Settings, and Profile always reachable from a
consistent bottom navigation bar
So that I can move between the app's main areas in one tap, instead of
hunting for scattered icon buttons per screen

**Acceptance Criteria**
- Scenario: Tab bar present on all top-level screens
  Given I am logged in with an active tool/server selected
  Then Home, History, Settings, and Profile are each one tap away via a
  persistent bottom tab bar, and the current section is clearly highlighted
- Scenario: Tab bar hidden where inappropriate
  Given I am inside a deep-navigation context (e.g. viewing a specific
  build's log, or mid-way through the add-server form)
  Then the tab bar's presence follows standard mobile navigation
  conventions (present at the top level of each section, not necessarily
  on every pushed detail screen), so it doesn't compete with in-context
  actions
- Scenario: Switching tabs preserves each tab's state
  Given I scroll partway down the job tree, switch to History, then switch
  back to Home
  Then Home returns to where I left it (scroll position/folder level) 
  rather than resetting to the root every time

**Security & Privacy Notes**
- None specific.

**UI / Design Notes**
- This is the single largest structural glass surface in the app (always
  visible) — per US-DESIGN-04's performance guardrail, the tab bar's blur
  must be cheap to keep static since it's composited over every scrolling
  screen behind it; the active tab uses the accent color per US-DESIGN-02.

**Non-Functional Notes**
- NFR-PERF-01, NFR-A11Y-02
