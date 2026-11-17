# Epic: DESIGN — Design System (glass chrome, flat content)

Cross-cutting visual language for the whole app. Every screen-level story in
files 01–08 references these stories instead of restating them. The epic
exists because a frosted, layered look is easy to get wrong in ways that
break accessibility and performance; those failure modes are written in as
first-class acceptance criteria, not left implicit.

**Current state (Phase 14, approved 2026-10-23).** The app was rebuilt
screen by screen to the approved designs in `UI-UX/` (24 artboards,
`UI-UX/README.md` maps each to its files). The original "glass on every
surface" direction was narrowed during that design review. The stories
below describe what was approved and built:

- **Glass only on persistent chrome.** The bottom navigation bar is the
  one frosted surface (94% fill, backdrop blur). Cards, sheets, dialogs and
  list rows are opaque, so text never sits on blurred content.
- **One accent.** `#2563EB` everywhere. The per-tool accent swap on
  `primary` was dropped, and CI tools keep their brand colour only on their
  own logo tile.
- **Flat background.** The gradient backdrop was removed (P14-05). With
  nothing translucent over content, nothing needed a busy background.
- **Tokens, not literals.** `AppTokens` (a `ThemeExtension`, read with
  `AppTokens.of(context)`) carries the surfaces (background, chrome, card,
  cardBorder, raised, console) and text levels (text, textSecondary,
  textMuted), separately for light and dark. It also carries six
  `StatusTone`s, each with a foreground, background and dot colour.
- **Type.** Inter for UI, JetBrains Mono (ligatures off) for URLs, build
  numbers, parameter names and logs. Both are bundled as assets under the
  OFL, with their licences registered.

---

### US-DESIGN-01 — Shared surface primitives

**Priority:** Must
**Source:** new — design refresh; revised by Phase 14
**Dependencies:** —

As a user
I want every card, sheet, and navigation surface to share one consistent
look
So that the app feels like a single coherent product, not a set of
independently styled screens

**Acceptance Criteria**
- Scenario: Reusable surfaces exist
  Given the design system is implemented
  When any screen renders a card, grouped list, sheet, or the bottom tab bar
  Then it uses the shared primitives: `GlassSurface.card` (opaque card, 1px
  border), `GroupedCard`/`GroupHeader` (rows separated by hairlines),
  `GlassSurface.chrome` (the frosted nav bar), the theme's bottom-sheet and
  dialog shapes, rather than a one-off implementation per screen
- Scenario: Blur only where something scrolls beneath
  Given a frosted surface is rendered
  When content can scroll under it (the bottom nav bar)
  Then the blur has real content behind it; surfaces with nothing beneath
  them are opaque instead of blurring a flat colour
- Scenario: Nested blur avoided
  Given a card or row is rendered
  When content is added inside it
  Then it adds no blur of its own — at most one blur layer per visual
  region, to keep contrast and performance predictable

**UI / Design Notes**
- `UI-UX/screens/05-home-jenkins-dark` and `09-settings` show cards and
  grouped lists; every screen shows the nav bar.

**Non-Functional Notes**
- NFR-PERF-01, NFR-A11Y-01

---

### US-DESIGN-02 — Light and dark themes with guaranteed contrast

**Priority:** Must
**Source:** new — design refresh; revised by Phase 14
**Dependencies:** US-DESIGN-01

As a user reading job names, build statuses, and log text
I want text and icons to stay clearly legible in both light and dark mode
So that the look never costs me the ability to actually read the app

**Acceptance Criteria**
- Scenario: Light mode contrast floor
  Given the app is in light mode
  When body text, muted text, or status text is rendered on a card or the
  background
  Then the text/background contrast meets WCAG AA (≥4.5:1 for normal
  text, ≥3:1 for large text/icons)
- Scenario: Dark mode contrast floor
  Given the app is in dark mode
  When the same text is rendered
  Then the same AA floor holds, with dark tokens tuned separately rather
  than reusing light values
- Scenario: The accent is readable
  Given the single accent `#2563EB`
  When it fills a button or marks a selected state
  Then its label colour on it, and it on the background, are checked
  against the same AA floor

**UI / Design Notes**
- Every token has a light and a dark value in `app_colors.dart`. The
  contrast pairs are asserted in `test/core/theme/app_colors_test.dart`, so
  a token change that breaks AA fails the build.

**Non-Functional Notes**
- NFR-A11Y-01, NFR-A11Y-02

---

### US-DESIGN-03 — Reduce-transparency accessibility fallback

**Priority:** Must
**Source:** new — design refresh
**Dependencies:** US-DESIGN-01

As a user who has enabled "Reduce Transparency" (iOS) or a similar
high-contrast setting (Android)
I want the app's one frosted surface to become solid
So that the blur doesn't make anything harder to read, and the app remains
usable regardless of my OS accessibility settings

**Acceptance Criteria**
- Scenario: OS reduce-transparency is on at launch
  Given the device has "Reduce Transparency" (or equivalent) enabled
  When the app starts
  Then `GlassSurface.chrome` renders opaque, in the same layout, with no
  blur
- Scenario: Setting changes while app is running
  Given the app is open
  When the user toggles the OS setting and returns to the app
  Then the nav bar switches to/from the opaque fallback without a restart
- Scenario: Fallback preserves hierarchy
  Given the opaque fallback is active
  When comparing it to the frosted variant
  Then the nav bar's boundary and selected state remain distinguishable

**UI / Design Notes**
- `GlassSurface` reads `reduceTransparencyNotifierProvider` and drops the
  blur; screens are not duplicated. Since cards and sheets are already
  opaque, the fallback only changes the chrome.

**Non-Functional Notes**
- NFR-A11Y-01, NFR-A11Y-03

---

### US-DESIGN-04 — Performance guardrail on long lists and the console

**Priority:** Must
**Source:** new — design refresh
**Dependencies:** US-DESIGN-01

As a user scrolling the job tree, build history, or a long console log
I want smooth scrolling
So that the redesign doesn't make the app feel slower or janky, especially
on mid-range Android devices

**Acceptance Criteria**
- Scenario: Blur cost doesn't scale with list length
  Given a screen renders a long scrollable list (job tree, history, queue)
  When the list is scrolled
  Then list rows are opaque and built lazily (`DecoratedSliver` groups,
  `ListView.builder`); the only `BackdropFilter` is the nav bar
- Scenario: Android mid-range device check
  Given the app runs on a mid-range Android device (the same class of
  device flagged as untested in Phase 5's P5-13 log-performance task)
  When scrolling the job tree or a multi-thousand-line log
  Then frame rendering stays within acceptable jank thresholds, measured
  manually — this reuses and extends the still-open P5-13 check
- Scenario: Console is flat
  Given the build log screen renders its virtualized console
  When log text streams and auto-scrolls
  Then the console is a flat, fixed-colour surface (`console` token) with
  a line-number gutter; nothing in it is blurred

**UI / Design Notes**
- `UI-UX/screens/15-build-log`.

**Non-Functional Notes**
- NFR-PERF-01, NFR-PERF-02, NFR-PERF-03

---

### US-DESIGN-05 — Build-status semantics stay legible

**Priority:** Must
**Source:** new — design refresh; revised by Phase 14
**Dependencies:** US-DESIGN-01, US-DESIGN-02

As a user scanning a list of jobs or builds
I want success/failure/unstable/running/paused/neutral states to be
immediately distinguishable
So that I can triage build health at a glance, which is the core reason I
opened the app

**Acceptance Criteria**
- Scenario: Each status has its own tone
  Given the status mapping in `app_colors.dart` (`toneForBuildResult`,
  `toneForJobColor`, `toneForStageStatus`)
  When statuses are shown side by side
  Then each `StatusTone` is distinct from the others and from its
  surface, in both light and dark mode
- Scenario: Running stays visible
  Given a job is building
  When its status is shown
  Then it uses the running tone with the pulsing indicator on its own
  tinted backing, and reads "Running" in words
- Scenario: Colour is never the only signal
  Given a user may have a colour-vision deficiency
  When any build status is shown
  Then it is paired with a distinct icon shape (`StatusTile`) and/or a
  word (`StatusPill`, the widget's status column), never colour alone

**UI / Design Notes**
- The same tones drive the native home-screen widgets (iOS WidgetKit,
  Android `AppWidgetProvider`), so a status looks the same on the home
  screen as in the app (`UI-UX/screens/24-home-widget-notification`).

**Non-Functional Notes**
- NFR-A11Y-01, NFR-A11Y-02
