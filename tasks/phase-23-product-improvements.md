# Phase 23 — Suggested first ten product improvements

Source: `docs/product-improvements.md`, "Suggested first ten" (promoted 2026-11-17).
These are the small, high-value, no-new-package improvements chosen from the
156-item proposal list. Each one keeps its `IMP-XX` id here as well as its
phase-23 task id (`PI-XX`), so commit messages can reference either.

Rules for every task here: `flutter analyze` + `flutter test` in
`JobTrigger-Frontend/` after each batch, plus `npm test`/lint/typecheck/build/E2E
in `JobTrigger-Web/` when batch 5 lands. No new packages, no backend changes,
no changes to frozen Jenkins integration code (`CLAUDE.md` §3, §11). Anything
only checkable on the owner's iPhone stays **UNVERIFIED** and is recorded in
`manually/`.

Implemented in five batches, with a full verification and commit after each.

## Batch 1 — Safety and access

- [x] PI-01 / IMP-25 **Read-only mode per server.** Local, user-scoped
      `ServerSafetyStore` (`shared_preferences`, key `server_safety`) holds a
      set of read-only credential ids keyed `tool:id`, so the preference is a
      client-side safety setting and needs no backend/DTO change. A Settings
      switch per saved credential marks it read-only. All trigger, cancel,
      dispatch, scan, enable/disable and write actions for that credential are
      hidden (or disabled) with an inline "read-only" note; watching and
      browsing keep working. `user_scoped_prefs.dart` registers the key so it
      clears on logout. Tests: store, Settings toggle, one gating test per
      tool. **UNVERIFIED on the iPhone** until tapped by hand.
- [x] PI-02 / IMP-24 **Two-step confirm for production actions.** Extend the
      shared `showConfirmationDialog` with an optional `requiredPhrase`: when
      set, a text field is shown and the confirm button stays disabled until
      the exact name is typed. The same `ServerSafetyStore` holds per-job
      "protected" markers keyed by a normalised tool-scoped job URL. A
      "Protect this job" action on job detail toggles it; while protected,
      trigger/stop/enable/disable/input (and GitHub dispatch/cancel) require
      the typed-name confirm. Existing single-step dialogs are unchanged when
      the phrase is absent. Tests: dialog helper, marker store, gated actions.
      **UNVERIFIED on the iPhone.**

## Batch 2 — Connectivity

- [x] PI-03 / IMP-35 **"Why can't I reach it?" check.** Pure
      `domain/diagnostics/connection_diagnosis.dart` turns a URL + `AppFailure`
      into a structured cause with explanation, fix tips and a guide id,
      telling apart a wrong URL, a private address on mobile data, a VPN that
      is off, a certificate error, and a plain network failure. Add an additive
      `BadCertificateFailure` variant to `AppFailure` (no other tool's copy
      changes). A "Why can't I reach it?" action on the shared
      `ConnectionErrorView` opens a new `ConnectionHelpScreen`. No
      `connectivity_plus`: private-address/VPN guidance is heuristic, based on
      the URL host and the failure, and phrased as advice rather than detected
      fact. Tests: diagnosis cases, screen, error mapping.
- [x] PI-04 / IMP-36 **In-app tunnel guides.** `RemoteAccessGuideScreen` with
      Tailscale, WireGuard and Cloudflare Tunnel cards (steps in-app, plus a
      link to the full doc) linked from the new help screen and App Info.
      Expand `docs/remote-access.md` with the WireGuard section and make the
      Cloudflare guide concrete. Tests: guide screen and link.

## Batch 3 — Freshness and status

- [x] PI-05 / IMP-38 **Last updated and offline banner.** Shared
      `DataFreshnessNotifier` (`DateTime? savedAt`, `bool offline`) and
      `DataFreshnessBanner` in `common_widgets`: "Updated 2m ago" for a live
      load, "Offline — showing data from HH:MM" for a cached fallback. Wire
      into Home, job detail, history, GitHub repos/runs and SonarQube
      projects/overview/issues. The existing Jenkins and SonarQube banners
      delegate to the shared widget so their current copy and tests stay
      green. Tests: notifier, banner, at least one screen per tool.
- [x] PI-06 / IMP-51 **Status by shape and text.** Add a shared `StatusMark`
      (distinct icon per tone **and** a visible label) and replace the
      remaining colour-only indicators: the Home server reachability chip,
      GitHub run step segments and Jenkins stage-status circles. Leave the
      already-compliant `StatusPill`/`StatusTile` alone. Extend the
      accessibility guideline test.

## Batch 4 — Notifications

- [x] PI-07 / IMP-11 **Notification rules per watched item.** Add `WatchRule`
      (`all`, `failuresOnly`, `backToGreenOnly`, `mainBranchOnly`) to
      `BuildWatch` with a JSON default of `all`, so existing watches keep
      their behaviour. `decideWatch` filters by result and, where known, by
      branch; `JenkinsBuild` has no branch field, so the main-branch rule uses
      a best-effort read of the multibranch job URL/display name and never
      suppresses when the branch is unknown (documented in the UI copy).
      Rule selector in the job-detail bell menu and the Settings watch list.
      Tests: rule evaluation, store round-trip, UI.

## Batch 5 — First-run, tokens, what's new

- [x] PI-08 / IMP-74 **First-run checklist.** Dismissible card on Home:
      connect a server → trigger a build → turn on alerts. Step one is read
      from the three credential notifiers, step two from a new local
      "has triggered" flag written by the trigger notifiers, step three from
      the watch stores. User-scoped so it clears on logout; hidden in demo
      mode and once dismissed. Tests: step detection, card, dismissal.
- [x] PI-09 / IMP-75 **Token wizards.** "How do I get a token?" button in all
      three credential edit sheets, opening a short in-app wizard with the
      right scopes and an external link to the token page: Jenkins
      `<base>/me/configure` (existing helper), GitHub with `repo`+`workflow`
      classic / Actions read+write fine-grained, SonarQube
      `<base>/user/account/security` (SonarCloud `/account/security`).
      Add `docs/token-guides.md`. Tests: URL helpers, wizard, each sheet's
      button.
- [x] PI-10 / IMP-65 **What's new.** App `WhatsNewSheet` opened from Profile
      and shown once per installed version (`package_info_plus` + a local
      last-seen-version key, deliberately device-level so it survives
      logout). Add a released v1.0 entry to the web changelog
      (`src/content/changelog.ts`) and its tests; the app sheet highlights the
      three tools shipped in 1.0.
- [x] PI-10-FIX **What's new sheet fills the phone and cannot be closed**
      (owner report 2026-11-23; US-PROF-05). With `isScrollControlled` and no
      max height the sheet grows to the whole screen, so there is no tap-out
      area and the only button sits below a long scroll. Cap the modal at 85%
      of the screen, add a labelled Close icon in the header, keep the bullet
      list in a `Flexible` scroll area and pin "Got it" in the footer. Tests:
      the sheet leaves a strip of app above it, long notes scroll, Close and
      "Got it" work without scrolling, and every dismissal records the seen
      version. Flutter only; web/backend unaffected.
      Done 2026-11-23: `flutter analyze` clean, `dart format --check` clean,
      full `flutter test` 1,995 passed / 29 skipped (7 What's-new tests,
      including the 3 new ones). `US-PROF-05` criteria ticked. iPhone pass
      (drag handle, scrim, real small-screen layout) still with the owner.
