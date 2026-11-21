# Epic: AUTH — Authentication

Backend auth against `JobTrigger-Backend` (`/api/auth/*`), JWT-equivalent
token carried as the `x-auth-token` header on subsequent backend calls (not
`Authorization: Bearer` — see `docs/api-reference.md`). Entirely separate
from Jenkins per-server Basic Auth (see [03-credential-management.md](../jenkins/03-credential-management.md)).

---

### US-AUTH-01 — Sign up for an account

**Priority:** Must
**Source:** tasks/phase-2-auth-tool-selection.md (P2-01, P2-02, P2-06)
**Dependencies:** —

As a new user
I want to create an account with my email and a password
So that I can securely store my Jenkins server credentials in the app

**Acceptance Criteria**
- [x] Scenario: Successful signup
  Given I am on the signup screen with no account yet for my email
  When I enter a valid email, a password meeting the app's minimum
  strength rule, matching confirmation, and submit
  Then `POST /api/auth/signup` is called, the returned token is written to
  secure storage, the returned user populates `authNotifierProvider`, and I
  am routed to tool selection
  Evidence: `test/presentation/features/auth/signup_notifier_test.dart` "a successful signup sets AuthNotifier to Authenticated"; `auth_notifier_test.dart` "setSession persists the token…"; backend `test/auth_edge.test.js`.
- [x] Scenario: Client-side validation before any network call
  Given I am on the signup screen
  When I enter an invalid email format, or a password below the minimum
  strength rule, or a confirmation that doesn't match
  Then the form shows inline field-level errors and no network request is
  made
  Evidence: `signup_notifier_test.dart` "rejects a malformed email without calling the repository", "rejects a password shorter than 8 characters", "rejects mismatched password/confirmPassword".
- [x] Scenario: Email already registered
  Given the backend rejects the signup because the email is already in use
  When the response comes back
  Then I see a clear, specific "an account with this email already exists"
  message (mapped from the backend's validation error, not a generic
  failure) and am offered a link to the login screen
  Evidence: Backend `test/auth_edge.test.js` ("already exists"); the 400 message is shown as-is (`RejectedRequestFailure`, `auth_repository_impl_test.dart`); `signup_screen.dart` offers "Log in".
- [x] Scenario: Network/server failure during signup
  Given the backend is unreachable or returns a non-2xx, non-validation
  error
  When signup fails
  Then the failure is shown via the shared `AppFailure` mapping
  (`NetworkFailure` → "can't reach server, try again"; `ServerFailure` →
  generic message with status code) and the password fields are not
  silently cleared without warning
  Evidence: Fixed 2026-11-21: test added: `test/presentation/features/auth/auth_network_failure_test.dart` "signup: network copy, passwords kept, submit tries again".

**Security & Privacy Notes**
- Accepted trade-off (AUD-55, 2026-10-20): signup answers "User already
  exists", which confirms an email is registered. A generic answer only
  helps with email verification behind it, which the backend doesn't have;
  until it does, the 5-signups-per-hour-per-IP limit bounds the probing.
  Login doesn't leak it: an unknown email gets the same message and the
  same bcrypt work as a wrong password.
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
- [x] Scenario: Successful login
  Given I have a valid account
  When I enter my correct email and password and submit
  Then `POST /api/auth/login` succeeds, the token is written to secure
  storage, `authNotifierProvider` updates, and the router redirects me past
  the login gate to tool selection/home
  Evidence: `login_notifier_test.dart` "a successful login sets AuthNotifier to Authenticated"; router redirect in `app_router.dart`.
- [x] Scenario: Invalid credentials
  Given I enter a wrong email or password
  When login fails with an authentication error
  Then I see one generic "invalid email or password" message — the UI does
  not reveal whether the email exists or the password was wrong, to avoid
  leaking account existence
  Evidence: Backend `test/login_timing.test.js` (one "Invalid credentials" for unknown email and wrong password) and `auth_edge.test.js`.
- [x] Scenario: Client-side validation
  Given the email field is empty or not a valid email shape
  When I attempt to submit
  Then submission is blocked with an inline error before any network call
  Evidence: `login_notifier_test.dart` "rejects a malformed email without calling the repository"; `login_screen_test.dart` "a failed attempt is reported inline".
- [x] Scenario: Network/server failure during login
  Given the backend is unreachable
  When login is attempted
  Then a `NetworkFailure`-mapped "can't reach server" message is shown with
  a retry action, and the password field is preserved so I don't have to
  retype it
  Evidence: Fixed 2026-11-21: test added: `auth_network_failure_test.dart` "login: network copy, password kept, Log in tries again".

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
- [x] Scenario: Cold start with a valid stored session
  Given a valid token exists in secure storage from a previous session
  When the app is cold-started
  Then `authNotifierProvider` rehydrates from secure storage before the
  router makes its first redirect decision, and I land directly on
  tool selection/home without seeing the login screen flash first
  Evidence: Fixed 2026-11-21: the login route showed its form while the stored session was read; `login_screen.dart` now shows a progress screen until it resolves. Test `login_screen_test.dart` "no form flashes while the stored session is read"; rehydration `auth_notifier_test.dart` "a fresh container rehydrates Authenticated state".
- [x] Scenario: Cold start with no stored session
  Given no token exists in secure storage
  When the app is cold-started
  Then I am routed to the login screen
  Evidence: `auth_notifier_test.dart` "build returns Unauthenticated when no session is stored"; `app_router.dart` redirects unauthenticated users to login.
- [ ] Scenario: App backgrounded and resumed
  Given I am logged in and background the app, then return to it later
  Then my session and current screen state are preserved without an
  unnecessary re-login prompt
  Open: device-only: backgrounding/OS suspension can only be observed on a physical device (P6-10 records no lifecycle code is needed); owner check M-01.
- [x] Scenario: Corrupted/unreadable secure storage entry
  Given the stored token exists but cannot be read/decrypted (e.g. platform
  keystore issue)
  When the app starts
  Then this is treated as "no session" (routed to login) rather than
  crashing or looping
  Evidence: Fixed 2026-11-21: `auth_notifier.dart` treated an unreadable keystore as an error; it is now "no session" and wiped. Test `auth_notifier_test.dart` "an unreadable keystore is no session, not a crash".

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
- [ ] Scenario: Logout from profile
  Given I am logged in and open the profile screen
  When I tap "Log out" and confirm
  Then the stored token is deleted from secure storage, in-memory auth
  state is cleared, the active-server selection is left intact for next
  login (not deleted), and I am routed to the login screen
  Open: superseded: AUD-28 (security audit, `tasks/phase-12-audit-remediation.md`) deliberately clears the active credentials on logout so the next person on the device can't see them; keeping them would undo that fix.
- [x] Scenario: Confirmation before destructive action
  Given I tap "Log out"
  When the confirmation dialog appears
  Then cancelling it leaves me logged in and on the same screen — logout is
  never a single accidental tap
  Evidence: Fixed 2026-11-21: "Log out" logged out on one tap; `profile_screen.dart` now asks first. Test `profile_screen_test.dart` "Log out asks first; Cancel keeps you signed in".
- [ ] Scenario: In-flight requests after logout
  Given a Jenkins/backend request was in flight when I logged out
  When it completes after logout
  Then its result is discarded rather than updating UI for a screen the
  user has already left
  Open: not proven: results are dropped by auto-dispose and `ref.mounted` checks in the notifiers, but no test drives a request across a logout; needs a router-level widget test.

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
- [x] Scenario: Backend returns 401 on any authenticated call
  Given my stored token is no longer valid
  When any `JobTrigger-Backend` request (e.g. fetching credentials) returns
  401
  Then the client clears the stored session (same cleanup as US-AUTH-04),
  shows a "your session has expired, please log in again" message, and
  routes to login — this is a global, backend-session-only reaction
  Evidence: Fixed 2026-11-21: the session was cleared but no message said why; `auth_notifier.dart` now shows "Your session has expired. Please log in again." Test `session_expiry_test.dart` (real Dio 401 → Unauthenticated + message); `backend_api_client_test.dart` "a 401 response clears the stored session".
- [x] Scenario: Jenkins 401/403 does NOT trigger this
  Given a Jenkins server call (not the backend) returns 401/403 because
  Jenkins credentials for that specific server are wrong or revoked
  Then this is handled as a per-server `AuthFailure` scoped to that server
  (see US-CRED-05/US-JOB stories) — the user's backend session remains
  intact and they are not logged out of the app
  Evidence: `test/core/network/auth_domain_isolation_test.dart` "a Jenkins 401 is only an AuthFailure: no logout, backend session …".
- [ ] Scenario: 401 during a background poll
  Given a live build-status poll or log stream is running when the backend
  session expires
  Then the timer is cancelled (via the owning notifier's disposal, not left
  running) before the redirect to login happens, avoiding a poll firing
  against a logged-out state
  Open: not proven: polling timers cancel in each notifier's `onDispose` (e.g. `queue_notifier.dart`), but no test shows the cancel happens before the login redirect.

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

---

### US-AUTH-06 — Delete my account

**Priority:** Must (App Store Review Guideline 5.1.1(v); Google Play
data-deletion policy)
**Source:** AUD-48, P13-07 (`tasks/phase-13-audit-2-remediation.md`)
**Dependencies:** US-AUTH-02, US-AUTH-04

As a JobTrigger user
I want to delete my account and everything stored with it
So that my CI credentials don't outlive my use of the app

**Acceptance Criteria**
- [x] Scenario: Delete
  Given I'm signed in
  When I choose Profile → Delete account and confirm with my password
  Then the account and every saved Jenkins server, GitHub credential, and
  SonarQube credential are deleted on the backend, every token stops
  working, and this device is cleared exactly as on logout (US-AUTH-04)
  Evidence: `account_actions_test.dart` "signs out and clears this device"; backend account-deletion tests in `test/billing.test.js` / `auth_edge.test.js`.
- [x] Scenario: Wrong password
  Then the dialog says "Current password is incorrect" and nothing is
  deleted; wrong guesses count against the login rate limit
  Evidence: `auth_repository_impl_test.dart` "deleteAccount surfaces a wrong password as its message"; `routes/authRoutes.js` puts `/account` behind `loginLimiter` (`test/rate_limit.test.js`).
- [x] Scenario: Backend unreachable
  Then nothing is deleted locally either, and the dialog shows the
  `NetworkFailure` copy so I can retry
  Evidence: `account_actions_test.dart` "a failure keeps the session and every local value".

**Security & Privacy Notes**
- `DELETE /api/auth/account` re-checks the password, so a stolen access
  token alone can't delete the account. Credentials are deleted before the
  user, so an interrupted request never leaves orphaned secrets.

---

### US-AUTH-07 — Change my password

**Priority:** Must
**Source:** AUD-48, P13-07
**Dependencies:** US-AUTH-02

As a user who suspects my password leaked
I want to change it
So that whoever has it, and every device signed in with it, is locked out

**Acceptance Criteria**
- [x] Scenario: Change
  Given the right current password and a new one meeting US-AUTH-01's rules
  When I submit Profile → Change password
  Then the password changes, every other device is signed out (the
  backend bumps `tokenVersion`), and this device stays signed in with the
  new session it gets back
  Evidence: `account_actions_test.dart` "keeps this device signed in with the new session"; backend `tokenVersion` bump in `test/password_reset.test.js` / `rate_limit.test.js`.
- [x] Scenario: Invalid input
  Then an empty current password, a new password under 8 characters, or a
  mismatched confirmation is reported inline before any request
  Evidence: `account_actions_test.dart` "checks the form before asking the server".
- [x] Scenario: Wrong current password
  Then "Current password is incorrect" is shown inline and nothing changes
  Evidence: `account_actions_test.dart` "a wrong current password changes nothing".

---

### US-AUTH-08 — Reset a forgotten password (on the website)

**Priority:** Should
**Source:** AUD-48. Deferred 2026-10-23 (no email provider); **built in
Phase 20, P20-72..74 (2026-11-12)**. Owner decision 2026-11-12: the reset
happens **on the website only**. The app's login screen links to the
website's `/forgot-password`; it has no reset screens and the email has no
app link.

As a user who forgot my password
I want to reset it by email
So that I don't lose my saved servers

**Acceptance Criteria**
- A single-use token valid for 15 minutes is emailed; the response is the
  same whether or not the email exists (no enumeration); a successful
  reset bumps `tokenVersion`.
- The app's login screen shows "Forgot password? Reset it on the web",
  which opens the website's reset page in the browser; the emailed link
  opens the website's `/reset-password`.
