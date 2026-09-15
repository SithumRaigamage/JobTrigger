# Epic: AUTH — Authentication

Backend auth against `JobTrigger-Backend` (`/api/auth/*`), JWT-equivalent
token carried as the `x-auth-token` header on subsequent backend calls (not
`Authorization: Bearer` — see `docs/api-reference.md`). Entirely separate
from Jenkins per-server Basic Auth (see [03-credential-management.md](03-credential-management.md)).

---

### US-AUTH-01 — Sign up for an account

**Priority:** Must
**Source:** tasks/phase-2-auth-tool-selection.md (P2-01, P2-02, P2-06)
**Dependencies:** —

As a new user
I want to create an account with my email and a password
So that I can securely store my Jenkins server credentials in the app

**Acceptance Criteria**
- Scenario: Successful signup
  Given I am on the signup screen with no account yet for my email
  When I enter a valid email, a password meeting the app's minimum
  strength rule, matching confirmation, and submit
  Then `POST /api/auth/signup` is called, the returned token is written to
  secure storage, the returned user populates `authNotifierProvider`, and I
  am routed to tool selection
- Scenario: Client-side validation before any network call
  Given I am on the signup screen
  When I enter an invalid email format, or a password below the minimum
  strength rule, or a confirmation that doesn't match
  Then the form shows inline field-level errors and no network request is
  made
- Scenario: Email already registered
  Given the backend rejects the signup because the email is already in use
  When the response comes back
  Then I see a clear, specific "an account with this email already exists"
  message (mapped from the backend's validation error, not a generic
  failure) and am offered a link to the login screen
- Scenario: Network/server failure during signup
  Given the backend is unreachable or returns a non-2xx, non-validation
  error
  When signup fails
  Then the failure is shown via the shared `AppFailure` mapping
  (`NetworkFailure` → "can't reach server, try again"; `ServerFailure` →
  generic message with status code) and the password fields are not
  silently cleared without warning

**Security & Privacy Notes**
- Password field is masked by default with an explicit show/hide toggle;
  never logged, never included in analytics/crash payloads (none are wired
  up today — see BACKLOG-07 — but the rule holds regardless).
- Minimum password strength rule is enforced client-side for UX, but the
  backend remains the source of truth for validation — the client never
  assumes its own check is sufficient security.
- The token returned by signup goes directly to `flutter_secure_storage`;
  it is never held in a widget's local state or `shared_preferences`.
- **Flagged risk (backend track, out of current scope):** signup
  rate-limiting/CAPTCHA to prevent automated account creation is a backend
  concern not covered by `docs/api-reference.md` today; not implemented
  client-side as a substitute.

**UI / Design Notes**
- Form fields sit inside a glass card (US-DESIGN-01) over the app's
  gradient background; primary "Sign Up" button uses the active accent
  color per US-DESIGN-02's contrast floor.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-02, NFR-TEST-01

---

### US-AUTH-02 — Log in

**Priority:** Must
**Source:** tasks/phase-2-auth-tool-selection.md (P2-01, P2-02, P2-05)
**Dependencies:** —

As a returning user
I want to log in with my email and password
So that I can access my saved Jenkins servers and jobs

**Acceptance Criteria**
- Scenario: Successful login
  Given I have a valid account
  When I enter my correct email and password and submit
  Then `POST /api/auth/login` succeeds, the token is written to secure
  storage, `authNotifierProvider` updates, and the router redirects me past
  the login gate to tool selection/home
- Scenario: Invalid credentials
  Given I enter a wrong email or password
  When login fails with an authentication error
  Then I see one generic "invalid email or password" message — the UI does
  not reveal whether the email exists or the password was wrong, to avoid
  leaking account existence
- Scenario: Client-side validation
  Given the email field is empty or not a valid email shape
  When I attempt to submit
  Then submission is blocked with an inline error before any network call
- Scenario: Network/server failure during login
  Given the backend is unreachable
  When login is attempted
  Then a `NetworkFailure`-mapped "can't reach server" message is shown with
  a retry action, and the password field is preserved so I don't have to
  retype it

**Security & Privacy Notes**
- Identical, deliberately generic error copy for "wrong password" and
  "no such account" (see edge case above) — a standard authentication
  best practice to avoid user enumeration.
- **Flagged risk (backend track, out of current scope):** login
  rate-limiting / account lockout after repeated failures is a backend
  concern not present in `docs/api-reference.md` today; documented here so
  it isn't silently forgotten, not implemented as client-side throttling
  (which is trivially bypassable and would give false security).
- Token handling identical to US-AUTH-01: secure storage only.

**UI / Design Notes**
- Same glass card treatment as signup (US-DESIGN-01); error banner uses a
  solid (non-glass) toast per US-DESIGN-04's guidance to keep critical
  feedback maximally legible.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-02, NFR-TEST-01

---

### US-AUTH-03 — Session persists across app restart

**Priority:** Must
**Source:** tasks/phase-2-auth-tool-selection.md (P2-03, P2-04); manual
verification still open per P2-11
**Dependencies:** US-AUTH-02

As a returning user
I want the app to remember that I'm logged in
So that I don't have to log in every time I open the app

**Acceptance Criteria**
- Scenario: Cold start with a valid stored session
  Given a valid token exists in secure storage from a previous session
  When the app is cold-started
  Then `authNotifierProvider` rehydrates from secure storage before the
  router makes its first redirect decision, and I land directly on
  tool selection/home without seeing the login screen flash first
- Scenario: Cold start with no stored session
  Given no token exists in secure storage
  When the app is cold-started
  Then I am routed to the login screen
- Scenario: App backgrounded and resumed
  Given I am logged in and background the app, then return to it later
  Then my session and current screen state are preserved without an
  unnecessary re-login prompt
- Scenario: Corrupted/unreadable secure storage entry
  Given the stored token exists but cannot be read/decrypted (e.g. platform
  keystore issue)
  When the app starts
  Then this is treated as "no session" (routed to login) rather than
  crashing or looping

**Security & Privacy Notes**
- Rehydration reads only from `flutter_secure_storage`; at no point is a
  copy of the token kept in `shared_preferences` or plain widget state
  beyond what's needed to attach it via the Dio auth interceptor.
- This story's "real device" gap (cold start / relaunch, flagged as
  unverified in P2-11) must be closed with actual device testing before
  this story is marked done — mocked tests alone are not sufficient per
  `docs/integration-testing.md`.

**UI / Design Notes**
- No new UI; a brief splash/loading state (glass-styled per US-DESIGN-01)
  covers the rehydration check so no login-screen flash is visible.

**Non-Functional Notes**
- NFR-SEC-01, NFR-PLAT-01, NFR-TEST-02

---

### US-AUTH-04 — Log out

**Priority:** Must
**Source:** tasks/phase-2-auth-tool-selection.md (P2-09)
**Dependencies:** US-AUTH-02

As a logged-in user
I want to explicitly log out
So that I can protect my account if I'm using a shared or borrowed device

**Acceptance Criteria**
- Scenario: Logout from profile
  Given I am logged in and open the profile screen
  When I tap "Log out" and confirm
  Then the stored token is deleted from secure storage, in-memory auth
  state is cleared, the active-server selection is left intact for next
  login (not deleted), and I am routed to the login screen
- Scenario: Confirmation before destructive action
  Given I tap "Log out"
  When the confirmation dialog appears
  Then cancelling it leaves me logged in and on the same screen — logout is
  never a single accidental tap
- Scenario: In-flight requests after logout
  Given a Jenkins/backend request was in flight when I logged out
  When it completes after logout
  Then its result is discarded rather than updating UI for a screen the
  user has already left

**Security & Privacy Notes**
- Secure-storage deletion must be verified to actually remove the entry,
  not just clear in-memory state — a token left on disk after "logout"
  would be a real vulnerability on a shared device.

**UI / Design Notes**
- Confirmation dialog rendered as a glass sheet per US-DESIGN-01.

**Non-Functional Notes**
- NFR-SEC-01

---

### US-AUTH-05 — Session expiry mid-use (backend 401)

**Priority:** Must
**Source:** tasks/phase-6-polish-release.md (P6-10 — bug found & fixed
during this exact flow)
**Dependencies:** US-AUTH-02

As a logged-in user whose token has expired or been invalidated
I want the app to detect that and return me to login
So that I'm not stuck seeing broken screens or stale data, and understand
why I need to log in again

**Acceptance Criteria**
- Scenario: Backend returns 401 on any authenticated call
  Given my stored token is no longer valid
  When any `JobTrigger-Backend` request (e.g. fetching credentials) returns
  401
  Then the client clears the stored session (same cleanup as US-AUTH-04),
  shows a "your session has expired, please log in again" message, and
  routes to login — this is a global, backend-session-only reaction
- Scenario: Jenkins 401/403 does NOT trigger this
  Given a Jenkins server call (not the backend) returns 401/403 because
  Jenkins credentials for that specific server are wrong or revoked
  Then this is handled as a per-server `AuthFailure` scoped to that server
  (see US-CRED-05/US-JOB stories) — the user's backend session remains
  intact and they are not logged out of the app
- Scenario: 401 during a background poll
  Given a live build-status poll or log stream is running when the backend
  session expires
  Then the timer is cancelled (via the owning notifier's disposal, not left
  running) before the redirect to login happens, avoiding a poll firing
  against a logged-out state

**Security & Privacy Notes**
- This is the single choke point where backend auth failure is handled —
  confirms the architectural rule that Jenkins auth failures must never be
  conflated with backend session expiry (`docs/api-reference.md`'s
  explicit warning about the two auth schemes).

**UI / Design Notes**
- Session-expired message uses the same solid toast/banner treatment as
  US-AUTH-02's error state, for consistency and legibility.

**Non-Functional Notes**
- NFR-SEC-03, NFR-TEST-02, NFR-PLAT-01
