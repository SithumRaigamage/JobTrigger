# Cross-cutting: Non-Functional & Security Baselines (NFR)

These are not user stories in their own right — they're the baseline
requirements that every story in files 00–08 references by ID, so each
individual story doesn't have to restate them. If a story's "Non-Functional
Notes" or "Security & Privacy Notes" cites one of these IDs, this is the
authoritative definition of what that ID means and how to verify it.

## Security (SEC)

### NFR-SEC-01 — Secrets never leave secure storage inappropriately
JWT tokens and Jenkins credentials (`Credential.secret`) are written and
read only via `flutter_secure_storage`. They are never placed in
`shared_preferences`, never held in widget-local state beyond what's needed
to render a masked input, and never included in logs, crash payloads, or
`toString()` output (the domain `Credential` type's redacting `toString()`
is the concrete mechanism — verify it with a unit test asserting the literal
secret string never appears in its output).
**Applies to:** all AUTH and CRED stories, and any story touching the Dio
interceptors.

### NFR-SEC-02 — Input validation before network calls
Client-side validation (format, required fields, minimum password strength)
runs before any request is sent, as a UX and defense-in-depth measure — the
backend/Jenkins remains the actual source of truth for validity, and the
client never assumes its own check is sufficient on its own.
**Applies to:** US-AUTH-01, US-AUTH-02, US-CRED-02.

### NFR-SEC-03 — Two auth schemes never cross-contaminate
`BackendApiClient` (JWT-style `x-auth-token` header) and `JenkinsApiClient`
(per-server HTTP Basic Auth) are separate Dio instances with separate
interceptors. A failure/expiry in one must never be handled as if it were a
failure in the other (backend 401 → global logout; Jenkins 401/403 →
per-server `AuthFailure`, scoped, no logout).
**Applies to:** US-AUTH-05, US-CRED-05, and every TREE/JOB/LOG story that
makes a Jenkins call.

### NFR-SEC-04 — No raw errors leak to the UI
Repositories return `AppFailure`-typed results; widgets never inspect raw
`DioException`/HTTP status codes or render a raw exception message/stack
trace. All failure copy goes through the single `AppFailure → String`
mapper referenced in `docs/architecture.md#error-handling`, so error
messaging stays consistent and never accidentally discloses internal detail
(hostnames, stack frames) beyond what's useful to the user.
**Applies to:** every story with a "failure" acceptance scenario.

### NFR-SEC-05 — Flagged backend-track risks stay flagged, not silently implemented
Where a security best practice would normally require new backend behavior
(login rate-limiting/lockout, signup CAPTCHA, server-side log redaction,
at-rest encryption verification for stored Jenkins passwords), the relevant
story documents it as an explicit flagged risk rather than the client
attempting a workaround that would give false security. Per `CLAUDE.md` §7,
backend changes are a separate track and require their own task.
**Applies to:** US-AUTH-01, US-AUTH-02, US-CRED-02, US-LOG-01/03.

## Testing (TEST)

### NFR-TEST-01 — Unit/widget coverage for repositories and notifiers
Every repository and notifier introduced or touched by a story has unit
test coverage (`flutter_test`, `mocktail`, `riverpod_test`), per
`CLAUDE.md` §3 and `docs/integration-testing.md`. This is mandatory, not
aspirational, for Phase 2+ work.
**Applies to:** all AUTH, CRED, and TREE stories.

### NFR-TEST-02 — Verified against a real Jenkins instance
Mocked tests alone are insufficient for Jenkins-facing behavior because
Jenkins' own JSON responses are inconsistent (nullable fields, polymorphic
parameter defaults). Each story touching a Jenkins endpoint must be
manually verified against at least one real, running Jenkins instance
before being marked done, and the final regression pass must additionally
cover **two differently-configured** servers (one with nested folders, one
flat) per `docs/migration-strategy.md`'s pre-store-submission QA gate.
**Applies to:** all CRED, TREE, JOB, LOG, and HIST stories.

## Accessibility (A11Y)

### NFR-A11Y-01 — Contrast and reduce-transparency compliance
Text/icon contrast on any surface (glass or opaque) meets WCAG AA. Glass
surfaces additionally respect the OS reduce-transparency setting per
US-DESIGN-03, falling back to opaque without any loss of information
hierarchy.
**Applies to:** every screen-bearing story via US-DESIGN-02/03.

### NFR-A11Y-02 — Screen-reader and tap-target support
All interactive elements have screen-reader labels, and tap targets meet
platform minimum size guidelines (44x44pt iOS / 48x48dp Android), including
elements rendered on glass surfaces where visual boundaries may be subtle.
**Applies to:** US-TOOL-01/02, US-PROF-04, and any story introducing a new
interactive control.

### NFR-A11Y-03 — Status is never conveyed by color alone
Build status and any other state indicator pairs color with an icon/shape
and/or text label (US-DESIGN-05), so the app remains usable for users with
color-vision deficiencies.
**Applies to:** all TREE, JOB, and HIST stories.

## Performance (PERF)

### NFR-PERF-01 — Blur cost is bounded, not proportional to content
`BackdropFilter` usage is limited to actually-visible chrome surfaces (app
bars, cards, sheets, the persistent tab bar) per US-DESIGN-01/04 — never
applied per list item or recomputed on every state tick (e.g. every 5s poll
in US-JOB-04) where a cheaper partial repaint suffices.
**Applies to:** all DESIGN stories, US-JOB-04, US-PROF-04.

### NFR-PERF-02 — Bounded recursion and client-side filtering
Job-tree recursion is capped at 6 levels (`docs/architecture.md`); search
(US-TREE-03) filters the already-fetched, already-flattened tree
client-side rather than issuing a network call per keystroke.
**Applies to:** US-TREE-01, US-TREE-03.

### NFR-PERF-03 — Log console remains smooth at scale
The build log console (US-LOG-01/02) uses virtualized rendering and a flat
(non-blurred) surface so that scroll performance and text legibility don't
degrade with multi-thousand-line logs, verified on a mid-range Android
device (closing the gap left open by Phase 5's P5-13).
**Applies to:** US-LOG-01, US-LOG-02, US-DESIGN-04.

## Platform (PLAT)

### NFR-PLAT-01 — Cold start, backgrounding, and session-expiry behavior
Explicitly tested (not assumed from happy-path dev usage): cold start with
and without a stored session, backgrounding/foregrounding mid-session, and
a token expiring while the app is in active use (US-AUTH-03/05), per the
bug found and fixed under Phase 6's P6-10.
**Applies to:** US-AUTH-03, US-AUTH-05.

### NFR-PLAT-02 — Android back-gesture parity
Android's system back gesture is handled consistently with in-app back/up
navigation (folder drill-down in particular), not left to default
Flutter/OS behavior that might exit the app or a navigation context
unexpectedly.
**Applies to:** US-TREE-02.
