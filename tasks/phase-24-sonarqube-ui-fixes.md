# Phase 24 — SonarQube Overview + Profile version fixes (epic FIX-2)

UI fixes found by the owner while testing on a physical iPhone (2026-11-17),
against the approved P14 design (`UI-UX/screens/05-home-jenkins-dark`,
`06-home-jenkins-light`). Each was planned, approved and committed one at a
time.

- [x] P24-01 **SonarQube Overview had no credential selector.** The header
      showed the active credential's label as plain text ("Development(local)")
      with no way to switch. It now shows a dropdown chip (the Jenkins Home
      `_ServerChip` pattern, P19-07): tap to list the saved SonarQube
      credentials, check on the active one, "Manage credentials…" → Settings.
      Switching calls `setActiveCredential`; the repository rebuilds and
      refetches on its own. Covered by `sonarqube_overview_test.dart` ("the
      credential chip drops down the saved credentials and switches in place").
- [x] P24-02 **Overview didn't match the approved UI.** The counts were plain
      tiles; "My issues"/"Search issues" were loose text buttons in the header.
      Counts are now colored status pills (Failing red, Warning amber, Passing
      green, Not analyzed neutral; a zero count fades to neutral), and the two
      quick actions are now `_ActionTile` cards (icon + label, same
      `GlassSurface.card` family as the pills) — kept, not removed, since they
      are the `US-SQ-ISSUES-01/03` entry points. The My Issues and Search
      Issues screens themselves are unchanged — the owner picked Overview only.
      Covered by "the My issues and Search issues tiles still reach their
      screens" in `sonarqube_overview_test.dart`.
- [x] P24-03 **Profile showed "Version 1.0.0 (1)".** The footer now reads
      "Version 1.0.0" — the build number is dropped, per the owner. The
      `profile_screen_test.dart` expectation was updated on purpose (it
      asserted the old string); `app_info_screen.dart` keeps its own
      "Version X (Y)" line untouched (flagged as a possible follow-up).
- [x] P24-04 **Subscription UI invisible without store keys.** The owner
      wanted to see the plans, the paywall and the Free/Pro status row, but
      `billingAvailable` correctly hides all of it in a build with no
      RevenueCat SDK key. A dev-only `BILLING_PREVIEW` dart-define now opts
      into `PreviewBillingClient`, which serves the website's two plans
      (Monthly $9.99, Yearly $29.99 with a 7-day trial) so the UI renders.
      Purchases always fail ("Preview build: no store is connected") and
      restore finds nothing; no money can move. Release builds can never
      preview (`AppConfig.billingPreview` is `!isRelease`-guarded), demo mode
      still wins, and the launchers write the flag only for local runs
      (`BILLING_PREVIEW=0` opts out). The real store checkout still needs
      the owner's keys (P20-40..42). Covered by
      `preview_billing_client_test.dart` and `billing_availability_test.dart`.
