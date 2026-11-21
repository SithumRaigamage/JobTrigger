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
- [ ] Scenario: Reusable surfaces exist
  Given the design system is implemented
  When any screen renders a card, grouped list, sheet, or the bottom tab bar
  Then it uses the shared primitives: `GlassSurface.card` (opaque card, 1px
  border), `GroupedCard`/`GroupHeader` (rows separated by hairlines),
  `GlassSurface.chrome` (the frosted nav bar), the theme's bottom-sheet and
  dialog shapes, rather than a one-off implementation per screen
  Open: not proven: the primitives exist and are used (`GlassSurface.card` in 25 feature files, `GroupedCard` in 11, `GlassSurface.chrome` for the tab bar), but 18 feature files still draw their own bordered `BoxDecoration`s (e.g. `home_screen.dart`, `settings_screen.dart`, `build_detail_screen.dart`); some are chips or tiles rather than cards. Needs a per-file audit before this can be ticked.
- [x] Scenario: Blur only where something scrolls beneath
  Given a frosted surface is rendered
  When content can scroll under it (the bottom nav bar)
  Then the blur has real content behind it; surfaces with nothing beneath
  them are opaque instead of blurring a flat colour
  Evidence: Fixed 2026-11-21: tests added: `test/presentation/navigation/main_scaffold_test.dart` "content runs under the frosted tab bar, its only blur" (`extendBody: true`); `test/presentation/common_widgets/glass_surface_test.dart` "a card is opaque and never blurs", "the chrome bar frosts what scrolls beneath it".
- [x] Scenario: Nested blur avoided
  Given a card or row is rendered
  When content is added inside it
  Then it adds no blur of its own — at most one blur layer per visual
  region, to keep contrast and performance predictable
  Evidence: Fixed 2026-11-21: test added: `glass_surface_test.dart` "a card inside the bar adds no blur of its own".

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
- [x] Scenario: Light mode contrast floor
  Given the app is in light mode
  When body text, muted text, or status text is rendered on a card or the
  background
  Then the text/background contrast meets WCAG AA (≥4.5:1 for normal
  text, ≥3:1 for large text/icons)
  Evidence: `test/core/theme/app_colors_test.dart` group "light tokens": status text 4.5:1 on its tint, cards and background; dots 3:1; muted/secondary/body text 4.5:1 on every surface. Screens: `test/presentation/accessibility/guidelines_test.dart` (Flutter's contrast guideline, both themes).
- [x] Scenario: Dark mode contrast floor
  Given the app is in dark mode
  When the same text is rendered
  Then the same AA floor holds, with dark tokens tuned separately rather
  than reusing light values
  Evidence: `app_colors_test.dart` group "dark tokens" (the same checks), and "both themes carry their tokens and the one accent" (`AppTokens.dark` is its own set, not the light values).
- [x] Scenario: The accent is readable
  Given the single accent `#2563EB`
  When it fills a button or marks a selected state
  Then its label colour on it, and it on the background, are checked
  against the same AA floor
  Evidence: `app_colors_test.dart` "white on the accent reaches 4.5:1"; Fixed 2026-11-21: test added: "the accent reaches 3:1 on both backgrounds and cards".

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
- [ ] Scenario: OS reduce-transparency is on at launch
  Given the device has "Reduce Transparency" (or equivalent) enabled
  When the app starts
  Then `GlassSurface.chrome` renders opaque, in the same layout, with no
  blur
  Open: not as written: Flutter does not expose iOS "Reduce Transparency" (`reduce_transparency_notifier.dart` doc comment), so the fallback is an in-app Settings switch, saved and applied at launch (`glass_surface_test.dart` "the setting survives a restart"). Reading the OS setting needs a native channel; owner decision.
- [ ] Scenario: Setting changes while app is running
  Given the app is open
  When the user toggles the OS setting and returns to the app
  Then the nav bar switches to/from the opaque fallback without a restart
  Open: same platform limit as above for the OS toggle. The in-app switch does change the bar live, both ways, without a restart (`glass_surface_test.dart` "reduce transparency makes the bar opaque at once, same layout, border kept").
- [x] Scenario: Fallback preserves hierarchy
  Given the opaque fallback is active
  When comparing it to the frosted variant
  Then the nav bar's boundary and selected state remain distinguishable
  Evidence: Fixed 2026-11-21: test added: `glass_surface_test.dart` "reduce transparency makes the bar opaque at once, same layout, border kept" (same size, opaque chrome fill, 1px border kept; the `NavigationBar` selected indicator is unchanged).

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
- [x] Scenario: Blur cost doesn't scale with list length
  Given a screen renders a long scrollable list (job tree, history, queue)
  When the list is scrolled
  Then list rows are opaque and built lazily (`DecoratedSliver` groups,
  `ListView.builder`); the only `BackdropFilter` is the nav bar
  Evidence: Fixed 2026-11-21: test added: `glass_surface_test.dart` "a long list of cards under the bar has one blur in total" (500 rows, scrolled); lazy lists: `console_log_viewer_test.dart` "virtualizes a 5,000-line log".
- [ ] Scenario: Android mid-range device check
  Given the app runs on a mid-range Android device (the same class of
  device flagged as untested in Phase 5's P5-13 log-performance task)
  When scrolling the job tree or a multi-thousand-line log
  Then frame rendering stays within acceptable jank thresholds, measured
  manually — this reuses and extends the still-open P5-13 check
  Open: device-only: measured by hand on a mid-range Android phone, the owner's M-02 (with P5-13, on hold).
- [x] Scenario: Console is flat
  Given the build log screen renders its virtualized console
  When log text streams and auto-scrolls
  Then the console is a flat, fixed-colour surface (`console` token) with
  a line-number gutter; nothing in it is blurred
  Evidence: Fixed 2026-11-21: test added: `test/presentation/features/build_log/console_log_viewer_test.dart` "the console is flat and numbers its lines"; the surface is the `console` token (`build_log_screen.dart`).

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
- [x] Scenario: Each status has its own tone
  Given the status mapping in `app_colors.dart` (`toneForBuildResult`,
  `toneForJobColor`, `toneForStageStatus`)
  When statuses are shown side by side
  Then each `StatusTone` is distinct from the others and from its
  surface, in both light and dark mode
  Evidence: Fixed 2026-11-21: test added: `app_colors_test.dart` "every status tone is distinct from the others" (both modes); readable on its surface: "each status dot reaches 3:1 on a card and the background".
- [x] Scenario: Running stays visible
  Given a job is building
  When its status is shown
  Then it uses the running tone with the pulsing indicator on its own
  tinted backing, and reads "Running" in words
  Evidence: Fixed 2026-11-21: tests added: `test/presentation/common_widgets/status_semantics_test.dart` "a running build reads \"Running\" on the running tint", "a building job pulses; a finished one is still".
- [x] Scenario: Colour is never the only signal
  Given a user may have a colour-vision deficiency
  When any build status is shown
  Then it is paired with a distinct icon shape (`StatusTile`) and/or a
  word (`StatusPill`, the widget's status column), never colour alone
  Evidence: Fixed 2026-11-21: tests added: `status_semantics_test.dart` "every tone has its own icon shape" (`StatusTile`), "every build result has a word" (`StatusPill`); `status_indicator_test.dart` (screen-reader words).

**UI / Design Notes**
- The same tones drive the native home-screen widgets (iOS WidgetKit,
  Android `AppWidgetProvider`), so a status looks the same on the home
  screen as in the app (`UI-UX/screens/24-home-widget-notification`).

**Non-Functional Notes**
- NFR-A11Y-01, NFR-A11Y-02
