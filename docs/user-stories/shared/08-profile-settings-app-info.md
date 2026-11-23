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
- [x] Scenario: Profile displays current user
  Given I open the profile screen
  Then my email (from `authNotifierProvider`, already in memory — no extra
  network call) is displayed, along with the app version footer and a
  logout action
  Evidence: `test/presentation/features/profile/profile_screen_test.dart` "names the account and the server in use" (email from `authNotifierProvider`, "Version 1.0.0" footer) and "Log out asks first; Cancel keeps you signed in (US-AUTH-04)".
- [x] Scenario: No network dependency
  Given I have no connectivity
  Then the profile screen still renders correctly since it reads only local
  auth state, distinguishing it from screens that genuinely need a live
  fetch
  Evidence: Fixed 2026-11-21: test added: `profile_screen_test.dart` "renders offline: email, version and Log out" (the server list fails with `NetworkFailure`).

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
- [x] Scenario: Selecting a mode
  Given I open the appearance picker in Settings
  When I select System, Light, or Dark
  Then the app's theme updates immediately and the choice is persisted
  locally (`shared_preferences` — non-secret, per the locked tech stack)
  so it survives app restart
  Evidence: Fixed 2026-11-21: test added: `test/presentation/features/settings/settings_screen_test.dart` "the Appearance picker applies and saves the mode"; restart: `test/core/theme/theme_notifier_test.dart` "rehydrates a previously persisted theme mode on build()".
- [x] Scenario: System mode follows OS changes
  Given "System" is selected
  When the OS-level appearance changes while the app is open (or after
  restart)
  Then the app's theme follows it automatically
  Evidence: Fixed 2026-11-21: test added: `test/core/theme/theme_mode_test.dart` "System follows the OS appearance while the app is open"; `lib/main.dart` passes the chosen `themeMode` with both themes.
- [x] Scenario: Glassmorphism applies to both modes
  Given either Light or Dark is explicitly selected
  Then the glass surfaces render using that mode's dedicated light/dark
  tokens (US-DESIGN-02) — never a mismatched blend of the two
  Evidence: Fixed 2026-11-21: test added: `theme_mode_test.dart` "an explicit mode uses only its own tokens"; `test/core/theme/app_colors_test.dart` "both themes carry their tokens and the one accent".

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
- [x] Scenario: App info loads
  Given I open the App Info screen
  Then it shows the installed app's real version/build number (via
  `package_info_plus`, not a hardcoded string) alongside data fetched from
  `GET /api/appinfo` (min supported version, release notes link) cached
  with a short TTL
  Evidence: Fixed 2026-11-21: the screen showed the backend's `appVersion`; it now shows the installed version from `package_info_plus`, and `GET /api/appinfo` returns `releaseNotesUrl` and `minSupportedVersion` (backend `models/AppInfo.js`, `scripts/seedAppInfo.js`). Tests: `app_info_screen_test.dart` "shows the installed version, not the backend's" and "shows Release notes when the backend links a changelog"; `app_info_dto_test.dart` "parses releaseNotesUrl and minSupportedVersion"; short TTL: `update_gate_test.dart` group "app info cache" ("is kept after its screen closes", "fresh info is not fetched again", "info older than the TTL is fetched again"; 10 minutes, `AppInfoNotifier.refreshIfStale`); backend `test/app_info_seed.test.js` "links release notes to the changelog…".
- [x] Scenario: Privacy policy / terms / licenses links
  Given I tap the privacy policy, terms, or licenses link
  Then it opens via `url_launcher` in the appropriate external handler
  (browser or in-app license viewer), matching `AppInfoView.swift`'s
  original `openURL` usage
  Evidence: `app_info_screen_test.dart` "shows the version and every link the backend provides"; rows open through `openExternalLink` (`url_launcher`), `test/presentation/common_widgets/external_link_test.dart` "an opened link shows nothing extra", "a link nothing can open says so (AUD-22)".
- [ ] Scenario: Support email link
  Given I tap the support contact
  Then it opens a `mailto:` link via `url_launcher`, matching the original
  SwiftUI app's `openURL` behavior
  Open: superseded on purpose by P25-05: "Contact support" opens the in-app Support screen (`app_info_screen_test.dart` "Contact support opens the Support screen") so reports become trackable tickets; the `mailto:` link is still offered there as a fallback (`support_screen.dart`). Needs the owner to retire or reword this criterion.
- [x] Scenario: App info fetch fails
  Given `GET /api/appinfo` fails
  Then the screen still shows the local version/build info (which needs no
  network call) and shows a non-blocking failure only for the
  backend-sourced fields
  Evidence: Fixed 2026-11-21: a failed fetch replaced the whole screen with an error; the installed version and the local guide now stay, with an inline retry for the backend's links. Test `app_info_screen_test.dart` "a failed fetch keeps the installed version on screen".
- [x] Scenario: Forced update gate (if min version not met)
  Given the backend's `minSupportedVersion` exceeds my installed version
  Then the app clearly prompts that an update is required, consistent with
  what `AppInfo`'s `minSupportedVersion` field exists to gate per
  `docs/data-models.md`
  Evidence: Fixed 2026-11-21: nothing read `minSupportedVersion`; `update_gate.dart` now covers the app with "Update required" (an outage or bad value never blocks). Tests `test/presentation/features/app_info/update_gate_test.dart` (version comparison, gate shown, not shown, failed fetch); the backend sets it from `MIN_SUPPORTED_APP_VERSION` (`test/app_info_seed.test.js`).

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
- [x] Scenario: Tab bar present on all top-level screens
  Given I am logged in with an active tool/server selected
  Then Home, History, Settings, and Profile are each one tap away via a
  persistent bottom tab bar, and the current section is clearly highlighted
  Evidence: `test/presentation/navigation/main_scaffold_test.dart` "all four tabs have labels in visual/focus order", "tapping a destination switches to that branch"; highlighted tab: `app_router_test.dart` (`NavigationBar.selectedIndex`).
- [x] Scenario: Tab bar hidden where inappropriate
  Given I am inside a deep-navigation context (e.g. viewing a specific
  build's log, or mid-way through the add-server form)
  Then the tab bar's presence follows standard mobile navigation
  conventions (present at the top level of each section, not necessarily
  on every pushed detail screen), so it doesn't compete with in-context
  actions
  Evidence: Fixed 2026-11-21: test added: `test/presentation/navigation/app_router_test.dart` "a pushed detail screen hides the tab bar; Back restores it"; detail routes use the root navigator (`app_router.dart`).
- [x] Scenario: Switching tabs preserves each tab's state
  Given I scroll partway down the job tree, switch to History, then switch
  back to Home
  Then Home returns to where I left it (scroll position/folder level) 
  rather than resetting to the root every time
  Evidence: `main_scaffold_test.dart` "switching away and back preserves branch widget state" (branches live in an `IndexedStack`).

**Security & Privacy Notes**
- None specific.

**UI / Design Notes**
- This is the single largest structural glass surface in the app (always
  visible) — per US-DESIGN-04's performance guardrail, the tab bar's blur
  must be cheap to keep static since it's composited over every scrolling
  screen behind it; the active tab uses the accent color per US-DESIGN-02.

**Non-Functional Notes**
- NFR-PERF-01, NFR-A11Y-02

---

### US-PROF-05 — Read "What's new" without getting stuck

**Priority:** Must (1.0.0 bug fix)
**Source:** owner report 2026-11-23; `tasks/phase-23-product-improvements.md` (PI-10-FIX)
**Dependencies:** US-PROF-01, US-PROF-03

As a user
I want the "What's new" sheet to leave part of the app visible and always give
me a way out
So that I can read every note and dismiss the sheet on a small phone

**Acceptance Criteria**
- [x] Scenario: The sheet does not take over the phone
  Given I open "What's new" from Profile, or it appears after an update
  Then a strip of the app behind it stays visible above the sheet, and the
  sheet never grows taller than 85% of the screen
  Evidence: `whats_new_sheet.dart` caps the modal at `0.85 * screen height`;
  `whats_new_test.dart` "the modal sheet leaves a strip of the app visible".
- [x] Scenario: Every note is reachable
  Given the release notes are longer than the sheet
  Then the notes scroll inside the sheet and every line can be read
  Evidence: `whats_new_test.dart` "long notes scroll while the action stays
  on screen" (40 notes in a 360px sheet, last note scrolled into view).
- [x] Scenario: I can always get out
  Given the sheet is open
  Then a labelled Close action and the "Got it" button are both visible
  without scrolling, and tapping either one dismisses the sheet
  Evidence: `whats_new_test.dart` "the sheet lists the release notes" (Close
  tooltip), "the gate shows the notes once per version" (taps Got it with no
  `ensureVisible`), "the close button dismisses and records the version".
- [x] Scenario: A dismissed sheet is not shown again for this version
  Given I dismiss the sheet by Close, "Got it", the drag handle or the area
  outside it
  Then the installed version is recorded as seen and the sheet does not
  reappear on the next launch
  Evidence: `whats_new_gate.dart` saves the version after any return from
  `showWhatsNewSheet`; "the close button dismisses and records the version",
  "the gate shows the notes once per version", "the gate stays quiet once
  this version has been seen". Drag/scrim use the default modal behaviour;
  the physical iPhone pass is still to do.

**Security & Privacy Notes**
- None specific. The sheet shows public release notes; it holds no account
  data or credentials.

**UI / Design Notes**
- Presentation layer only: `whats_new_sheet.dart` keeps the modal bottom sheet
  but caps its height, gives the notes a `Flexible` scroll area and pins the
  primary action in a footer. The close icon follows
  `stage_detail_sheet.dart`; the height cap follows `edit_sheet.dart`.
  `whats_new_gate.dart` needs no change: every dismissal returns from
  `showWhatsNewSheet`, after which the version is saved.

**Non-Functional Notes**
- NFR-A11Y-02 (labelled close action), NFR-PERF-01 (no new work while idle)
