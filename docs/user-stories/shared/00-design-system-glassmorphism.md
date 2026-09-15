# Epic: DESIGN — Glassmorphism Design System

Cross-cutting visual language for the whole app. Every screen-level story in
files 01–08 references these stories instead of restating them. This epic
exists because "make it glassmorphic" is easy to get wrong in ways that break
accessibility and performance — those failure modes are written in as
first-class acceptance criteria, not left implicit.

Current state: `app_theme.dart`/`app_colors.dart` today produce a solid
Material 3 theme (opaque surfaces, per-tool accent swap on `primary`/
`onPrimary` only). None of the stories below exist in code yet — this is a
design-system migration applied on top of the already-implemented screens.

---

### US-DESIGN-01 — Frosted-glass surface primitive

**Priority:** Must
**Source:** new — design refresh
**Dependencies:** —

As a user
I want every card, sheet, app bar, and navigation surface to share one
consistent frosted-glass look
So that the app feels like a single coherent product, not a set of
independently styled screens

**Acceptance Criteria**
- Scenario: Reusable glass surface widget exists
  Given the design system is implemented
  When any screen renders a card, bottom sheet, app bar, or the bottom tab
  bar
  Then it uses one shared `GlassSurface`-style widget (semi-transparent
  fill, `BackdropFilter` blur of the content behind it, a 1px
  semi-transparent border, and a soft outer shadow for depth) rather than a
  one-off implementation per screen
- Scenario: Background provides something to blur
  Given a glass surface is rendered
  When there is no photographic content behind it
  Then the screen background is a subtle gradient or blurred brand-color
  wash (not a flat single color), so the blur effect is visually meaningful
  instead of blurring nothing
- Scenario: Nested glass avoided
  Given a glass card is already rendered on the glass app bar/background
  When content is added inside that card
  Then inner elements (list tiles, buttons) do not stack a second
  independent blur on top of the first — at most one blur layer per visual
  region, to keep contrast and performance predictable

**Security & Privacy Notes**
- None specific to this story.

**UI / Design Notes**
- This is the primitive story; it defines the widget other stories consume.

**Non-Functional Notes**
- NFR-PERF-01, NFR-A11Y-01

---

### US-DESIGN-02 — Light and dark glass variants with guaranteed contrast

**Priority:** Must
**Source:** new — design refresh
**Dependencies:** US-DESIGN-01

As a user reading job names, build statuses, and log text through a frosted
surface
I want text and icons to stay clearly legible in both light and dark mode
So that the aesthetic never costs me the ability to actually read the app

**Acceptance Criteria**
- Scenario: Light mode contrast floor
  Given the app is in light mode
  When body text or status text is rendered on a glass surface
  Then the rendered text/background contrast ratio meets WCAG AA (≥4.5:1
  for normal text, ≥3:1 for large text/icons), verified against the actual
  blurred-background color range, not just the glass fill alone
- Scenario: Dark mode contrast floor
  Given the app is in dark mode
  When body text or status text is rendered on a glass surface
  Then the same AA contrast floor holds, with glass fill/opacity tuned
  separately for dark mode rather than reusing light-mode values
- Scenario: Tool-accent color still readable on glass
  Given the active tool's accent color (currently Jenkins) is applied to
  `primary`/`onPrimary` per `app_theme.dart`
  When accent-colored elements (buttons, selected nav state) sit on a glass
  surface
  Then the accent/glass combination is checked against the same AA floor,
  not assumed compatible by default

**Security & Privacy Notes**
- None specific to this story.

**UI / Design Notes**
- Glass fill opacity, blur sigma, and border color must each be defined as
  separate light/dark tokens in `app_colors.dart` — never a single value
  reused across both brightnesses.

**Non-Functional Notes**
- NFR-A11Y-01, NFR-A11Y-02

---

### US-DESIGN-03 — Reduce-transparency accessibility fallback

**Priority:** Must
**Source:** new — design refresh
**Dependencies:** US-DESIGN-01

As a user who has enabled "Reduce Transparency" (iOS) or a similar
high-contrast/reduce-motion setting (Android)
I want the app to switch glass surfaces to solid, opaque ones
So that the blur effect doesn't make text unreadable or trigger discomfort,
and the app remains usable regardless of my OS accessibility settings

**Acceptance Criteria**
- Scenario: OS reduce-transparency is on at launch
  Given the device has "Reduce Transparency" (or equivalent) enabled
  When the app starts
  Then every `GlassSurface` renders as an opaque, solid-color surface using
  the same layout, with no blur applied
- Scenario: Setting changes while app is running
  Given the app is open with glass surfaces visible
  When the user toggles the OS reduce-transparency setting and returns to
  the app
  Then surfaces switch to/from the opaque fallback without requiring an app
  restart
- Scenario: Fallback preserves information hierarchy
  Given the opaque fallback is active
  When comparing it to the glass variant
  Then card boundaries, elevation/depth ordering, and status colors remain
  distinguishable — the fallback is a first-class visual state, not an
  unstyled placeholder

**Security & Privacy Notes**
- None specific to this story.

**UI / Design Notes**
- Implement by reading the platform accessibility flag (Flutter's
  `MediaQuery.of(context).disableAnimations` / platform transparency query)
  and branching the shared `GlassSurface` widget's paint, not by duplicating
  screens.

**Non-Functional Notes**
- NFR-A11Y-01, NFR-A11Y-03

---

### US-DESIGN-04 — Performance guardrail on blur-heavy screens

**Priority:** Must
**Source:** new — design refresh
**Dependencies:** US-DESIGN-01

As a user scrolling the job tree, build history, or a long console log
I want smooth scrolling despite the glass styling
So that the visual redesign doesn't make the app feel slower or janky,
especially on mid-range Android devices

**Acceptance Criteria**
- Scenario: List screens cap active blur layers
  Given a screen renders a long scrollable list (job tree, history, log
  console) inside or behind glass surfaces
  When the list is scrolled
  Then only surfaces actually visible on screen apply `BackdropFilter`
  (list items themselves use a cheaper flat translucent fill, not their own
  blur), so blur cost doesn't scale with list length
- Scenario: Android mid-range device check
  Given the app runs on a mid-range Android device (the same class of
  device flagged as untested in Phase 5's P5-13 log-performance task)
  When scrolling the job tree or a multi-thousand-line log
  Then frame rendering stays within acceptable jank thresholds (no
  sustained dropped-frame stutter), measured manually before this story is
  considered done — this reuses and extends the still-open P5-13 manual
  perf check rather than replacing it
- Scenario: Log console excluded from heavy blur
  Given the build log screen renders a virtualized console view
  When log text is streaming and auto-scrolling
  Then the console viewport itself is a flat (non-blurred) surface — only
  its surrounding app bar/controls use glass — since blurring rapidly
  updating text content is both expensive and visually distracting

**Security & Privacy Notes**
- None specific to this story.

**UI / Design Notes**
- Establishes that "glassmorphic" applies to chrome (app bars, cards,
  sheets, nav) and not necessarily to every scrollable content surface.

**Non-Functional Notes**
- NFR-PERF-01, NFR-PERF-02, NFR-PERF-03

---

### US-DESIGN-05 — Build-status semantics stay legible on glass

**Priority:** Must
**Source:** new — design refresh
**Dependencies:** US-DESIGN-01, US-DESIGN-02

As a user scanning a list of jobs or builds
I want success/failure/unstable/building/aborted status colors to remain
immediately distinguishable when shown on a frosted surface
So that I can still triage build health at a glance, which is the core
reason I opened the app

**Acceptance Criteria**
- Scenario: Status colors retain identity on glass
  Given the existing build-status color mapping (success/failure/unstable/
  building/aborted, per `app_colors.dart`) is rendered as an icon or chip on
  a glass surface
  When compared side-by-side across all five states
  Then each status remains visually distinct from the others and from the
  glass background itself, in both light and dark mode
- Scenario: Building state animation stays visible
  Given a job is currently building (animated/pulsing status indicator)
  When it is rendered on top of a moving/blurred background
  Then the animation is not visually lost against the blur — status
  indicators use a small opaque or high-contrast backing shape rather than
  sitting directly on raw blurred content
- Scenario: Color is never the only signal
  Given a user may have a color-vision deficiency
  When any build status is shown
  Then it is paired with an icon/shape and/or text label, not color alone —
  this holds regardless of the glass redesign and is called out here
  because glass backgrounds further reduce color-only legibility

**Security & Privacy Notes**
- None specific to this story.

**UI / Design Notes**
- Status chips/badges should be one of the few elements allowed a small
  opaque backing (per US-DESIGN-04) specifically to preserve this
  legibility requirement.

**Non-Functional Notes**
- NFR-A11Y-01, NFR-A11Y-02
