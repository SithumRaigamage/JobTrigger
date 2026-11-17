# Epic: LOG — Build Log Viewing

Streams console output via
`GET {buildURL}logText/progressiveText?start={offset}`, reading the
`X-Text-Size` (next offset) and `X-More-Data` response headers, polling at
~1s intervals until `X-More-Data` is false/absent.

---

### US-LOG-01 — View a build's streaming console log

**Priority:** Must
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-09, P5-10, P5-11)
**Dependencies:** US-JOB-01

As a user
I want to open a build's console log and see it update live while the
build is still running
So that I can watch progress and diagnose issues in real time, the same as
tailing Jenkins' console output on a laptop

**Acceptance Criteria**
- Scenario: Log streams while build is running
  Given I open the log screen for a currently-building build
  Then the log accumulates via progressive fetches roughly every second,
  appending new text as `X-Text-Size` advances, until `X-More-Data`
  indicates the stream is complete
- Scenario: Viewing a finished build's log
  Given the build has already completed
  Then the full existing log loads once (no ongoing polling needed once
  `X-More-Data` is false from the first response)
- Scenario: Leaving the screen stops polling
  Given I navigate away while a log is still streaming
  Then the polling timer is cancelled by the owning notifier's disposal —
  it does not keep fetching in the background
- Scenario: Log fetch failure mid-stream
  Given a progressive fetch fails partway through
  Then previously accumulated log text remains visible (not cleared), with
  a non-blocking `AppFailure`-mapped indicator and automatic retry on the
  next interval
- Scenario: Very large log
  Given the log is many thousands of lines long
  Then the console view remains scrollable and responsive (virtualized
  rendering — only visible lines are laid out), per the still-open Android
  performance check carried into US-DESIGN-04

**Security & Privacy Notes**
- Console output is whatever the Jenkins job itself printed — it may
  contain secrets the job's own script leaked (e.g. an env var echoed by
  mistake). The app cannot and does not attempt to redact Jenkins-side log
  content; this is a known, inherent risk of viewing raw CI logs and is
  called out explicitly rather than silently assumed safe (see
  US-LOG-03's share warning).

**UI / Design Notes**
- Per US-DESIGN-04, the log console itself is a flat, non-blurred surface
  for both legibility and scroll performance; only the surrounding app bar/
  controls use the glass treatment.

**Non-Functional Notes**
- NFR-PERF-03, NFR-TEST-02

---

### US-LOG-02 — Auto-scroll with manual override

**Priority:** Must
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-11)
**Dependencies:** US-LOG-01

As a user watching a live log
I want it to auto-scroll to the newest output, but stop doing that the
moment I scroll up to read something
So that I can review earlier output without the view constantly yanking
back to the bottom

**Acceptance Criteria**
- Scenario: Default auto-scroll
  Given a log is streaming and I haven't manually scrolled
  Then the view auto-scrolls to keep the latest line visible as new text
  arrives
- Scenario: Manual scroll disables auto-scroll
  Given I scroll up while streaming
  Then auto-scroll stops immediately — new incoming text no longer yanks my
  view back down
- Scenario: Resuming auto-scroll
  Given auto-scroll is currently disabled
  When I tap a visible "scroll to bottom" affordance
  Then the view jumps to the latest line and auto-scroll resumes
- Scenario: Reaching the bottom naturally
  Given I manually scroll back down to the very bottom myself
  Then auto-scroll resumes automatically, without requiring the explicit
  button tap

**Security & Privacy Notes**
- None specific.

**UI / Design Notes**
- "Scroll to bottom" is a small floating glass-pill button (US-DESIGN-01)
  that appears only once auto-scroll is disabled, so it doesn't clutter the
  screen during normal streaming.

**Non-Functional Notes**
- NFR-PERF-03

---

### US-LOG-03 — Copy or share a build log

**Priority:** Should
**Source:** tasks/phase-5-build-execution-logs-history.md (P5-12)
**Dependencies:** US-LOG-01

As a user
I want to copy or share a build's console output
So that I can send it to a teammate or paste it into a ticket/chat when
diagnosing a failure

**Acceptance Criteria**
- Scenario: Copy to clipboard
  Given I'm viewing a log
  When I choose "Copy log"
  Then the currently loaded log text is copied to the system clipboard,
  with confirmation feedback
- Scenario: Share via system share sheet
  Given I choose "Share log"
  Then the OS share sheet opens (via `share_plus`, per `CLAUDE.md`'s locked
  stack) with the log text, letting me pick a destination app
- Scenario: Sharing a still-streaming log
  Given the build hasn't finished yet
  When I share
  Then it shares the log content accumulated so far, clearly (not silently)
  — the action doesn't imply it will include content that arrives later
- Scenario: Secret-exposure warning
  Given this is the first time I share/copy a log in a session (or the
  first time ever, whichever is simpler to implement well)
  Then a brief, dismissible notice reminds me that Jenkins console output
  can contain secrets the job itself printed, and that sharing is my
  responsibility to review before sending — this does not block the action,
  it informs it

**Security & Privacy Notes**
- This is the primary mitigation for the risk noted in US-LOG-01: since the
  app cannot redact Jenkins-authored log content, the share/copy action is
  where the user is explicitly reminded, at the moment of an outbound-sharing
  decision, rather than the risk being undocumented.
- Share/copy actions must not silently attach anything beyond the visible
  log text (no hidden metadata, no credentials from app state).

**UI / Design Notes**
- Copy/share buttons live in the glass app bar for the log screen.

**Non-Functional Notes**
- NFR-SEC-04
