# Phase 6 — Polish & Release

Goal: parity-checklist complete, both platforms feel native, store-ready.
Some items can start as soon as their underlying feature lands in an
earlier phase — don't wait for Phase 5 to fully close to begin these.

- [ ] P6-01 Profile screen — user info, logout, app version footer.
- [ ] P6-02 App info screen — version/build number, release notes link,
      wired to `AppInfoNotifier` / `/api/appinfo`.
- [ ] P6-03 Theme parity pass — confirm light/dark palettes match the
      original `AppTheme` values closely enough that returning users don't
      feel a regression.
- [ ] P6-04 Haptic feedback on build trigger/cancel (`HapticFeedback`),
      matching original tactile cues.
- [ ] P6-05 Accessibility pass: font scaling, screen-reader labels on icon
      buttons and status indicators, sufficient contrast on status colors.
- [ ] P6-06 Android-specific review: back-gesture behavior matches
      breadcrumb/folder navigation expectations; platform-appropriate
      widgets where Material vs Cupertino defaults would feel foreign.
- [ ] P6-07 App icons, splash screens, store screenshots for both platforms.
- [ ] P6-08 Crash reporting / analytics hook (decide tool, out of original
      scope but reasonable to add before public release — confirm with the
      team before implementing, don't assume).
- [ ] P6-09 Full regression pass against `docs/migration-strategy.md`'s
      feature parity checklist, both platforms.
- [ ] P6-10 Cold-start, backgrounding, and token-expiry (401 mid-session)
      flows explicitly tested.
- [ ] P6-11 Internal TestFlight + Play internal testing track release.
- [ ] P6-12 Dogfood window, track crash-free rate and any Jenkins-server
      edge cases surfaced by real usage.
- [ ] P6-13 Public release; keep SwiftUI app archived (not delisted) for a
      rollback window per `docs/migration-strategy.md §5`.
