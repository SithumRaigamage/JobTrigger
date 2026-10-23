# Phase 14 — UI redesign (epic UI-2)

Goal: rebuild every screen to the redesign approved on 2026-10-23. The
designs, one folder per screen, are in [`UI-UX/`](../UI-UX/README.md),
along with the design tokens. Behaviour does not change: same routes, same
notifiers, same actions. This phase changes how the screens look and how
they are laid out.

Approved by the user on 2026-10-23 ("approved … do development screen by
screen … commit and push one by one"), on branch `feature/ui-redesign`.
One task = one screen = one commit, pushed on its own, and a task is
`done` only when that screen is fully built: analyze clean, tests green,
and CI green on its commit (Definition of Done from AUD-42).

**CI note (2026-10-23):** GitHub Actions is disabled for the repository
(the owner's billing choice), so no workflow runs on this branch. Until
it's re-enabled, each task is verified by running the Flutter CI steps
locally before its commit — format check, `flutter analyze`, the
generated-code drift check, and the full test suite — and each screen is
compared against its `UI-UX/` render at 390×844. The branch gets a real
CI run before it merges.

## Decisions approved with the designs

1. **Flat cards replace frosted glass.** `GlassSurface` keeps its API but
   draws an opaque card with a hairline border. This supersedes the
   glassmorphism look of US-DESIGN-01; the reduce-transparency setting
   stays and keeps its meaning for the remaining translucent chrome.
2. **Theme-aware status colours.** Every status gets a foreground and a
   tinted background per theme (`UI-UX/README.md`, Design tokens). They
   replace the single AUD-62 shades, and `app_colors_test.dart` measures
   the new pairs: 4.5:1 for status text, 3:1 for dots and icons.
3. **Bundled fonts, no new package.** Inter and JetBrains Mono ship as
   asset TTFs under the SIL Open Font License (`assets/fonts/`). No
   `google_fonts` dependency (CLAUDE.md §3).
4. **One app-wide accent.** `#2563EB` for primary buttons, the selected
   tab and switches. A CI tool's brand colour appears only on its own logo
   tile, so Jenkins red no longer competes with the "failed" red.

## Tasks

- [x] P14-01 Export the approved designs to `UI-UX/`, one folder per
      screen (render, standalone preview, source) with a README index.
- [x] P14-02 Foundation: fonts, colour tokens, theme-aware status colours,
      `AppTheme` component themes, single accent, flat `GlassSurface`,
      plain backdrop, bottom navigation bar, shared `StatusPill` and
      `SectionLabel` widgets.
- [x] P14-03 Login (design 01).
- [x] P14-04 Signup (design 02).
- [x] P14-05 Tool selection (design 03).
- [x] P14-06 App lock (design 04).
- [x] P14-07 Home — Jenkins, dark and light (designs 05, 06).
- [x] P14-08 Home — GitHub repositories (design 07).
- [x] P14-09 Global history (design 08).
- [x] P14-10 Settings (design 09).
- [x] P14-11 Profile (design 10).
- [x] P14-12 Job detail (design 11).
- [ ] P14-13 Stage detail sheet (design 12).
- [ ] P14-14 Job history (design 13).
- [ ] P14-15 Build detail (design 14).
- [ ] P14-16 Build log (design 15).
- [ ] P14-17 Nodes (design 16).
- [ ] P14-18 Queue (design 17).
- [ ] P14-19 GitHub workflows (design 18).
- [ ] P14-20 Open link (design 19).
- [ ] P14-21 App info (design 20).
- [ ] P14-22 Edit sheets: Jenkins server, GitHub and SonarQube
      credentials (design 21).
- [ ] P14-23 Account dialogs: change password, delete account (design 22).
- [ ] P14-24 Unknown route (design 23).
- [ ] P14-25 Home-screen widget and build notifications (design 24).
- [ ] P14-26 Close-out: update the design-system user stories
      (`docs/user-stories/00-design-system-glassmorphism.md`) to the
      approved look, and mark the phase done in `tasks/README.md`.
