# Phase 26 — Session continuity and pre-trigger polish

Source: `docs/product-improvements.md` section Z (IMP-157…168, added
2026-11-19). The owner approved the four cheapest items on 2026-11-19 as the
first post-1.0 batch. The other eight stay proposals in that document and are
**not** in this phase.

**Ships in 1.1.0, not 1.0.0.** 1.0.0 is feature-frozen (`Releases/v1.0.0/`
Track J); this phase starts only after the tag is cut, so the release that the
nine CI gates and the device matrix certified is not re-opened for polish.

## Rules for every task here

- **No backend changes** (separate track, `CLAUDE.md` §7).
- **No new pub packages.** P26-02 is the one exception to "no native code":
  it uses a small platform channel instead of `wakelock_plus`, and can be
  deferred if the owner would rather not touch the native shells yet.
- **Jenkins is frozen** (§11). These four read existing data and never change
  a Jenkins request or response shape.
- **Shared code stays shared** (§11): every change here is additive. Home, job
  detail and Settings serve all three tools, so each task says which screens
  it touches and which existing tests must keep passing unchanged.
- Run `flutter analyze` and `flutter test` after each task, and the whole suite
  before the PR. Anything only checkable on a device is marked **UNVERIFIED**
  and recorded in `manually/`.

## Batch 1 — Home and session continuity

- [ ] P26-01 / IMP-157 **"Since you last looked" card.** Show what changed
      since the previous app open — builds that failed, builds that went
      green, and approvals waiting — as one dismissible card at the top of
      Home.
      - Store a per-account "last looked at" timestamp plus a per-watch
        last-known result in the existing user-scoped prefs
        (`lib/data/cache/user_scoped_prefs.dart`, the `server_safety` pattern),
        so logout clears it and a re-install simply starts clean.
      - Source the data from what is already loaded — the dashboard's failing
        and running lists, `build_watch_store`, and the pending-input counts
        the job detail already fetches. **No new polling loop**: build the
        card from the first successful load of the session, then freeze it
        until the next open (a stale card that keeps moving is not "since you
        last looked").
      - First run after install shows nothing (no previous timestamp) — no
        "everything is new" noise.
      - Tests: the delta builder (pure Dart, all four combinations), the card,
        dismissal persistence, first-run silence, and that Home's existing
        sections and their tests are unchanged.
      - **UNVERIFIED on the iPhone** until seen after a real background/kill.

- [ ] P26-02 / IMP-160 **Duration estimate beside Trigger.** Show "last time
      this took 12 min" next to the trigger action, and a warning when the
      job's recent durations are far above that median.
      - Read the existing build history the job detail already loads; take the
        median of the last five successful builds and the median of all
        recent builds. No new request unless the history list is empty.
      - Three states only: unknown (no history, nothing shown), normal
        (label), slower ("usually 12 min — this build is at 31 min" in the
        running state).
      - Must not change the trigger button's enabled/disabled logic or the
        protected-job confirm path (PI-02).
      - Tests: the median helper (empty, one build, odd/even counts),
        the three states, and the existing job-detail tests unchanged.

## Batch 2 — Release watching and runbooks

- [ ] P26-03 / IMP-158 **Deploy-watch mode.** While the user is watching a
      running build, keep the screen awake and show a compact "watching" pill;
      stop automatically when the build finishes or the user leaves.
      - A `MethodChannel('jobtrigger/screen_awake')` with two calls,
        `enable`/`disable`: iOS `UIApplication.shared.isIdleTimerDisabled`,
        Android `window.addFlags(FLAG_KEEP_SCREEN_ON)` /
        `clearFlags`. About fifteen lines per platform, no dependency.
        If the owner prefers no native changes in 1.1, defer this task and
        keep IMP-158 as a proposal.
      - Opt-in from the job detail overflow menu ("Keep screen awake"), per
        session only — **no persisted setting**, so a forgotten toggle cannot
        drain a battery. Always released in `dispose()`, on build completion,
        and on app background.
      - Tests: a fake channel asserting enable/disable pairing for leave,
        completion and dispose, plus the pill's visibility. The native calls
        themselves are **UNVERIFIED** until the iPhone check.

- [ ] P26-04 / IMP-163 **Runbook link per job.** Attach a URL (wiki page,
      checklist, on-call doc) to a job and surface it before a protected
      trigger.
      - Store per credential-and-job, keyed like the protected-job markers in
        `ServerSafetyStore`, in the same local prefs — a link, never fetched
        content. Validate it is `http(s)`, label it, allow removal.
      - Shown as a "Runbook" row on job detail, and inside the confirm dialog
        for a protected job (PI-02) so it is read before acting.
      - `url_launcher` is already in the stack (§3), so opening it adds no
        dependency. Validate the scheme before launching; never launch a
        `file:` or `javascript:` URL.
      - Tests: store round-trip, URL validation, the job-detail row, and that
        an unprotected job's confirm dialog is unchanged.

## Verification gate

- `flutter analyze` clean and `flutter test` green with no weakened tests
  (`CLAUDE.md` §11).
- Run the four flows on the owner's iPhone with `scripts/run-on-iphone.sh`
  (profile build; see `IPHONE.md`):
  1. Home → trigger a failure, kill the app, reopen → the card lists it once.
  2. Job detail → a job with history shows "last time" beside Trigger.
  3. Job detail → overflow → Keep screen awake → the screen no longer sleeps
     while the build runs, and the toggle is off again next time.
  4. Settings → mark a credential read-only and protect a job → Runbook opens
     the saved page from the confirm dialog.
- Record each device check in `manually/` as M-19…M-22 with the build it ran
  on, and leave anything not tapped marked **UNVERIFIED**.
