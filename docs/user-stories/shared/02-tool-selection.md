# Epic: TOOL — Tool Selection

A navigation shell today: Jenkins is the only functional integration.
GitHub Actions/GitLab/SonarQube/CircleCI are shown as disabled placeholders
— see [10-out-of-scope-backlog.md](10-out-of-scope-backlog.md) for why they
stay out of scope for v1.

---

### US-TOOL-01 — Select Jenkins as the active CI tool

**Priority:** Must
**Source:** tasks/phase-2-auth-tool-selection.md (P2-08)
**Dependencies:** US-AUTH-02 or US-AUTH-03

As a logged-in user
I want to choose Jenkins from a grid of CI tool options
So that the app knows which integration to use for the rest of my session

**Acceptance Criteria**
- [ ] Scenario: Selecting Jenkins
  Given I am on the tool selection screen after login
  When I tap the Jenkins card
  Then `ActiveToolNotifier` records Jenkins as active, the app's accent
  color switches to Jenkins' brand color (per `app_theme.dart`'s
  `accentColor` mechanism), and I am taken into the Jenkins flow (either
  credential setup if no server is saved yet, or straight to the job tree
  if one exists)
  Open: partly superseded: the choice is recorded and Continue goes Home (`test/presentation/features/tool_selection/tool_selection_screen_test.dart` "Jenkins is chosen to start with, and nothing is committed until Continue", "choosing GitHub Actions and continuing commits it and goes home"), but the accent no longer changes per tool (P14 decision 4: one accent, `app_theme.dart`), and with no server Home shows "No Jenkins Server" rather than opening the add-server form (see the third criterion). Needs the owner to reword or approve a change.
- [ ] Scenario: Returning user skips re-selection
  Given I previously selected Jenkins and have at least one saved server
  When I log in again
  Then I am not forced back through tool selection — it is shown only when
  no tool/server context exists yet, or when explicitly reached via
  settings/switch-tool navigation
  Open: contradicts a deliberate design: the active tool is in memory only and a signed-in user always passes tool selection after a cold launch (`active_tool_notifier.dart` doc comment; `app_router.dart` sends a just-signed-in user to `/tools`). Owner decision: persist the tool, or retire this criterion.
- [ ] Scenario: No saved servers yet
  Given I select Jenkins for the first time
  When there is no saved Jenkins server
  Then I am routed into the add-server flow (US-CRED-02) rather than to an
  empty job tree
  Open: not as written: with no saved server Home shows "No Jenkins Server" with "Go to Settings" (`test/presentation/features/home/home_screen_test.dart` "shows \"no server\" once the list loads empty"; `no_active_server_view.dart`), never an empty tree, but not the add-server form either. Changing it touches Jenkins Home (frozen, `CLAUDE.md` §11), so it waits for the owner.

**Security & Privacy Notes**
- None specific — no credentials are collected on this screen.

**UI / Design Notes**
- Tool cards are individual glass tiles (US-DESIGN-01) on the gradient
  background; the selected/enabled Jenkins card uses full accent-color
  contrast, disabled cards use a visibly muted glass treatment (see
  US-TOOL-02) so "disabled" reads unambiguously even through the frosted
  style.

**Non-Functional Notes**
- NFR-A11Y-02

---

### US-TOOL-02 — See other CI tools as clearly "coming soon"

**Priority:** Should
**Source:** tasks/phase-2-auth-tool-selection.md (P2-08)
**Dependencies:** —

As a user browsing the tool selection screen
I want to see that GitHub Actions, GitLab, SonarQube, and CircleCI are not
yet available, without it looking like a bug
So that I understand the app's current scope and am not confused by a
non-responsive tap

**Acceptance Criteria**
- [x] Scenario: Disabled card is visually distinct
  Given a non-Jenkins tool card is rendered
  Then it uses a reduced-opacity glass treatment, a muted (not brand-colored)
  icon, and a "coming soon" label — distinct enough from the enabled Jenkins
  card that the difference doesn't rely on subtle contrast alone
  Evidence: `test/presentation/features/tool_selection/release_managed_test.dart` "release 1.0: three tools to choose, two tiles under \"Coming next\" with their versions"; the tiles (`tool_selection_screen.dart` `_ComingNextTile`) use muted text and icon colours, no brand colour, an outline instead of a card, and the release they arrive in as the "coming" label.
- [x] Scenario: Tapping a disabled card
  Given I tap a disabled tool card
  Then nothing navigates, and a brief, non-blocking message confirms it's
  not yet available (rather than the tap silently doing nothing, which
  reads as broken)
  Evidence: Fixed 2026-11-21: a tap on a "Coming next" tile did nothing; it now shows a toast "<Tool> is coming / It arrives in <version>" and still selects nothing. Test `release_managed_test.dart` "the tiles are disabled: tapping one selects nothing" (toast asserted).
- [x] Scenario: Screen-reader announcement
  Given a screen reader is active
  When focus moves to a disabled tool card
  Then it is announced as disabled/unavailable, not read identically to the
  enabled Jenkins card
  Evidence: Fixed 2026-11-21: test added: `release_managed_test.dart` "a screen reader hears a tile as disabled, coming later" (label "GitLab CI, coming in <version>", enabled state false, no tap action).

**Security & Privacy Notes**
- None.

**UI / Design Notes**
- Reuses the muted-glass pattern established here as the app-wide
  convention for "not yet available" affordances (referenced by
  US-DESIGN-01).

**Non-Functional Notes**
- NFR-A11Y-02
