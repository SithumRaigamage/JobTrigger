# Phase 22 — Next release (improvement plan follow-up)

Source: `docs/implemented/improvement-plan.md`, section "Next release". These are the
items between the Emergency phase and the public release. Each one is still
planned, approved and committed on its own (`CLAUDE.md` §9), and anything
touching Jenkins needs the owner to reopen it (§11).

Rules for every task here: `flutter analyze` + `flutter test` in
`JobTrigger-Frontend/`, `npm test` in `JobTrigger-Backend/` and in
`JobTrigger-Web/` when they change, the whole suite before the PR (§11), and
anything only checkable on a real iPhone marked **UNVERIFIED**.

- [x] NR-01 **Fold noisy log sections** (2026-11-16). Runs of four or more
      near-identical console lines (same text once numbers, hex ids, case
      and spacing are normalised) collapse into one summary row, "N similar
      lines", that opens on tap. Lines that look like a failure
      (`isErrorLine`) are never folded and always break a run, so "Jump to
      first error" still lands on real output; search and jumps open the
      fold that hides their line. New `domain/jenkins/console_folds.dart`
      (pure Dart, no Flutter imports), a `Fold repeated lines` toggle in the
      log menu (`ConsolePrefs.foldSections`, on by default, stored in
      `shared_preferences`), tests for the grouping rule and the viewer.
      No new dependency. Copy, share and save still use every line.
      **UNVERIFIED on the iPhone** until the folding is scrolled by hand.
- [x] NR-02 **Unified home dashboard** (2026-11-16). `/dashboard`
      (`presentation/features/dashboard/`), opened from the Home menu on
      Jenkins and from the header of the GitHub and SonarQube Home tabs.
      It fetches each tool independently: Jenkins failing and running jobs
      from the job tree, GitHub failed and in-progress runs from the
      cross-repo feed, SonarQube projects whose gate needs attention, and
      the pinned jobs with their status. A tool that isn't set up or can't
      load shows a note and leaves the rest working, the header sums the
      totals, and every row opens the detail screen that tool already has.
      Read-only: it never triggers, cancels or approves anything, and the
      only change to existing screens is the added entry point.
      **UNVERIFIED on the iPhone**; host tests cover the aggregate (6) and
      the screen (3).
- [x] NR-03 **QR-code pairing (website → app)** (2026-11-16). `/servers`
      shows one code per saved Jenkins server (`features/servers/
      pair-codes.ts`, `qrcode` on the server, SVG; CSP unchanged). The
      phone's own Camera app opens it as `jobtrigger://app/pair?url=…&name=…
      &username=…` — the scheme both platforms already register (US-JX-19),
      so no camera package and no new permission. The app lands on
      `PairScreen`, which shows what the code carries and continues into the
      ordinary add-server sheet with those fields filled
      (`ServerEditBottomSheet` prefill); its validation, plan gate and save
      path are unchanged. The token is never in the code. Bad or incomplete
      codes are refused with a way to Settings. Tests: web (pairing link,
      codes, view) and app (link round-trip, screen). The website's store QR
      (P15-24) is a separate item.
- [ ] NR-04 **Clearer error copy** for a bad token, an unreachable server
      and an expired session. Checked 2026-11-16: the app
      (`core/error/error_message.dart`, `describeError`) and the portal
      (`server/backend-client.ts`, its failure mapping) already carry this
      copy. Re-check on the iPhone with a deliberately wrong token and an
      off server before closing it.
- [ ] Subscriptions in the app: finish Phase 20 (`tasks/phase-20-subscriptions.md`).
- [ ] Website go-live: owner actions in `tasks/phase-15-website.md` (P15-22,
      P15-24) and `tasks/phase-emergency.md` (PE-03).
- [x] NR-04 **Clearer error copy** — checked 2026-11-16 and already built:
      the app's `core/error/error_message.dart` (`describeError`) and the
      portal's `server/backend-client.ts` mapping cover a bad token, an
      unreachable server and an expired session. Re-check on the iPhone with
      a deliberately wrong token and a stopped server before closing.
- [x] NR-05 **Analytics events** (P20-30, 2026-11-16): the site sends
      `signup`, `server_added`, `pricing_view` and `limit_hit` (with the
      backend's `limit`). The app sends none, by the owner decision in
      `docs/subscription/04-email-and-analytics.md` §4.2, so its rows in the
      catalogue are unsent on purpose.
- [x] NR-06 **Server push — backend half** (2026-11-16). `DeviceToken`
      model, `POST /api/devices` and `DELETE /api/devices/:token`
      (owner-scoped, idempotent), and `lib/push.js`: FCM HTTP v1 with a
      self-signed RS256 JWT, one send per registered device, unregistered
      tokens deleted, and a no-op unless `FCM_SERVICE_ACCOUNT` is set. No
      SDK and no new npm dependency. `npm test` 392 passing.
- [ ] NR-06b **Server push — what is left**, all outside the code I can
      land alone: (1) the Firebase project plus its APNs key and
      `google-services.json` / `GoogleService-Info.plist` (owner); (2) the
      app side — `firebase_messaging`, a token upload on launch and a
      notification-permission prompt, which pull Firebase config files and
      a new package (`CLAUDE.md` §3) and so need approval; (3) a server-side
      trigger, which means the backend polling Jenkins with decrypted
      credentials — a deliberate architecture change, since today the phone
      talks to Jenkins directly.
