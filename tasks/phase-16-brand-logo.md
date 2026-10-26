# Phase 16 — Brand logo (Concept B)

Goal: replace the play-glyph mark with logo **Concept B — Pipeline** (two
pipeline stages joined to a green run arrow) everywhere the app and the
website show the logo. The mark says "any CI pipeline", not "Jenkins",
which fits the GitHub Actions and SonarQube integrations.

Chosen by the owner on 2026-10-26 from six concepts (A–F) reviewed on a
design canvas ("i like B"), plan approved the same day ("go"), on branch
`feat/brand-logo-b` from `develop`.

**Workflow.** Each task: implement → local gate → owner review → one
commit, `feat(brand): [P16-0N] …`. The gate is `flutter analyze` +
`flutter test` for the app and `npm run check` + `npm run e2e` for the
website (GitHub Actions is off by the owner's choice).

## The mark

Source drawings in [`UI-UX/brand/`](../UI-UX/brand/), on a 128-unit grid:

| Part | Colour |
|---|---|
| Tile | Navy `#0F172A` |
| Stage rings | `#93C5FD` |
| Connectors | `#60A5FA` |
| Run arrow | Green `#4ADE80` |

## Decisions approved with the phase (2026-10-26)

1. **Logo only.** The mark uses its own fixed colours. The app theme and
   the website accent stay `#2563EB`; no contrast pairs change.
2. **Scope:** app icon (iOS + Android), splash screen, the in-app
   `AppLogo`, and the website (`BrandMark`, `icon.png`, `apple-icon.png`,
   the link-preview image).
3. **No new package.** PNGs are exported by `scripts/export-icons.sh`
   with `rsvg-convert` (Homebrew `librsvg`, a tool on the developer's
   machine, not a project dependency) and committed. `AppLogo` draws the
   mark with a `CustomPainter`, since `flutter_svg` isn't in the stack.
4. **Splash background navy `#0F172A`**, matching the icon tile, so the
   launch has no colour jump.
5. **Android themed icon included**: a one-colour layer in the adaptive
   icon, so Android 13+ can tint it to the wallpaper.
6. **Tracked as a new phase** (this file), not as extra Phase 14 tasks.

## Tasks

- [x] P16-00 Docs: this file and the Phase 16 row in `tasks/README.md`.
- [x] P16-01 Source drawings in `UI-UX/brand/` (full-square iOS icon,
      Android foreground, one-colour layer, rounded mark) and
      `scripts/export-icons.sh`. iOS PNGs carry no alpha channel (App
      Store rule).
- [x] P16-02 App icon: every `AppIcon.appiconset` size; Android
      `ic_launcher` at every density plus the adaptive icon (navy
      background, foreground, monochrome).
- [x] P16-03 Splash screen: navy with the mark centred, Android
      (`launch_background.xml`, `-v21`) and iOS (`LaunchScreen`).
- [x] P16-04 `AppLogo` draws the B mark (hairline outline in dark mode),
      widget test; login and app info screens unchanged.
- [ ] P16-05 Website: `BrandMark`, `icon.png`, `apple-icon.png`,
      `opengraph-image.tsx`.

## Out of scope

- Changing the theme accent or any brand colour beyond the mark itself.
- Store listing artwork (screenshots, feature graphic). The 512 px Play
  Store icon and 1024 px App Store icon come from the same export.
