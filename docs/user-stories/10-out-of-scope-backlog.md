# Out of Scope / Backlog (v1)

These are documented here — as deliberately excluded, not silently
forgotten — so the story set is complete about the product's boundaries as
well as its capabilities. Source: `tasks/backlog.md`. None of these have
acceptance criteria; they are stubs recording the decision and the reason,
per `CLAUDE.md` §7's rule against scope creep during the rewrite.

### BACKLOG-01 — Real GitHub Actions / GitLab / SonarQube / CircleCI integration
Tool selection shows these as disabled placeholder cards (US-TOOL-02) today.
**Reason deferred:** v1 scope is Jenkins-only per the migration's stated
goal; each additional CI tool is its own integration surface (different
auth model, different API shape) and a separate initiative.

### BACKLOG-02 — Push notifications for build completion
**Reason deferred:** requires a push infrastructure decision (APNs/FCM,
backend fan-out) not present in the current backend or architecture docs —
a backend-track initiative, not a client-only addition.

### BACKLOG-03 — Home-screen widget
**Reason deferred:** platform-specific (iOS WidgetKit / Android App
Widgets) work with its own data-refresh and security model (would need to
display job status outside the authenticated app context); not part of the
core rewrite.

### BACKLOG-04 — Multi-account support (multiple backend accounts)
**Reason deferred:** current auth/session model (`authNotifierProvider`,
single stored token) assumes one active account; supporting multiple would
change session storage design significantly.

### BACKLOG-05 — Offline job-tree caching
**Reason deferred:** the product's value is *live* Jenkins state — a stale
cached job tree risks a user triggering a build against outdated
assumptions about current status. Would need explicit staleness UX if ever
pursued.

### BACKLOG-06 — Biometric unlock
**Reason deferred:** additive security feature, not required for parity
with the original SwiftUI app; secure storage already protects the token
at rest regardless.

### BACKLOG-07 — Crash reporting / analytics tool
**Reason deferred:** tool choice explicitly deferred by the user
(`tasks/phase-6-polish-release.md` P6-08); no telemetry is currently wired
up, which is also why NFR-SEC-01 notes "none are wired up today" rather
than assuming a specific vendor's data-handling posture.

### BACKLOG-08 — Backend / MongoDB migration or rewrite
**Reason deferred:** explicitly out of scope for the Flutter rewrite per
`CLAUDE.md` §7 — "don't rewrite the Node backend as part of this migration
unless a task explicitly says so." The backend is a separate track.

### BACKLOG-09 — Live "Backend Server Status" indicator in Settings
**Reason deferred:** would require a lightweight health-check story of its
own (polling cadence, what counts as "down") that hasn't been scoped;
today, connectivity issues surface reactively per-screen via the existing
`AppFailure` handling (NFR-SEC-04) rather than proactively.
