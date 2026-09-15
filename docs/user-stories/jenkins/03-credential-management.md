# Epic: CRED — Jenkins Server (Credential) Management

Backed by `JobTrigger-Backend`'s `/api/credentials*` endpoints (`x-auth-token`
header). Stores server name, Jenkins URL, username, password, optional
param token, and an `isDefault` flag. The domain layer renames `password` to
`secret` specifically to flag it as sensitive at every call site (see
`docs/data-models.md`) and gives it a redacting `toString()` — every story
below assumes that discipline holds.

---

### US-CRED-01 — View my saved Jenkins servers

**Priority:** Must
**Source:** tasks/phase-3-credentials-management.md (P3-03, P3-06)
**Dependencies:** US-AUTH-02 or US-AUTH-03

As a user
I want to see a list of all Jenkins servers I've saved
So that I can review, manage, and pick between them

**Acceptance Criteria**
- Scenario: List loads successfully
  Given I have one or more saved servers
  When I open the Settings/servers screen
  Then `GET /api/credentials` populates the list, with the active server
  visually marked, and passwords are never rendered in the list (masked or
  omitted entirely — display name/URL/username only)
- Scenario: No servers saved yet
  Given I have no saved servers
  Then I see an empty state prompting me to add one, not a blank screen
- Scenario: Load failure
  Given the backend call fails
  Then the failure is shown via the `AppFailure` mapping (`NetworkFailure`
  → "can't reach server" with retry; backend `ServerFailure`/`UnknownFailure`
  → generic message) — not a raw error or blank screen

**Security & Privacy Notes**
- The list view must never render `password`/`secret` values, even masked
  as dots — there's no legitimate reason to fetch or display it once saved,
  and doing so widens the exposure window.

**UI / Design Notes**
- Each server is a row inside a single glass card list (US-DESIGN-01); the
  active server's row uses accent-color highlighting per US-DESIGN-02.

**Non-Functional Notes**
- NFR-SEC-01, NFR-TEST-01

---

### US-CRED-02 — Add a new Jenkins server

**Priority:** Must
**Source:** tasks/phase-3-credentials-management.md (P3-01, P3-02, P3-07)
**Dependencies:** US-CRED-01

As a user
I want to add a Jenkins server by entering its URL and my credentials
So that the app can connect to it on my behalf

**Acceptance Criteria**
- Scenario: Successful add
  Given I open the add-server form and enter a name, a valid Jenkins base
  URL, username, and password (param token optional)
  When I save
  Then `POST /api/credentials` is called, the new server appears in the
  list, and if it's my first server it becomes active automatically
- Scenario: Client-side validation
  Given required fields are empty or the URL is not well-formed
  (missing scheme, invalid host)
  When I attempt to save
  Then inline validation blocks submission before any network call
- Scenario: Save failure
  Given the backend rejects or fails the save
  Then an `AppFailure`-mapped message is shown and the form retains my
  entered values so I don't have to retype the URL/username
- Scenario: Recommended — test before save
  Given I haven't yet run "test connection" (US-CRED-06)
  When I try to save
  Then the app allows saving anyway (Jenkins may be temporarily unreachable
  but credentials still correct) but visibly nudges me to test first, since
  an unverified server could silently fail later

**Security & Privacy Notes**
- The password field is masked with an explicit reveal toggle, uses a
  password-type keyboard/autofill hint, and is transmitted only to the
  configured backend base URL over HTTPS (no hardcoded URLs — `core/config/`
  only, per `CLAUDE.md` §7).
- Password is never logged client-side; the domain `Credential.secret`'s
  redacting `toString()` must be exercised by a unit test asserting the
  literal secret never appears in any log/debug output.
- **Flagged risk (backend track, out of current scope):** whether the
  backend encrypts stored Jenkins passwords at rest in MongoDB is a backend
  concern outside `docs/api-reference.md`'s documented contract; flagged
  here rather than assumed.

**UI / Design Notes**
- Form presented as a glass bottom sheet (US-DESIGN-01) per the existing
  P3-07 pattern; "Save" button disabled until required fields are valid.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-02, NFR-TEST-01, NFR-TEST-02

---

### US-CRED-03 — Edit an existing Jenkins server

**Priority:** Must
**Source:** tasks/phase-3-credentials-management.md (P3-02, P3-07)
**Dependencies:** US-CRED-01

As a user
I want to update a saved server's details (e.g. rotate a password, fix a
typo in the URL)
So that I can keep my saved credentials accurate without deleting and
re-adding the server

**Acceptance Criteria**
- Scenario: Successful edit
  Given I open an existing server for editing and change one or more fields
  When I save
  Then `PUT /api/credentials/:id` sends a partial update, the list reflects
  the change, and if I edited the active server, the Jenkins Dio client for
  that server is rebuilt with the new credentials immediately
- Scenario: Password field starts empty, not pre-filled
  Given I open the edit form
  Then the password field is blank (never pre-populated with the existing
  secret, even masked) — leaving it blank on save means "keep existing
  password unchanged," entering a new value means "replace it"
- Scenario: Edit failure
  Given the update request fails
  Then an `AppFailure`-mapped message is shown and no partial/inconsistent
  local state is applied — the list still reflects the last known-good
  server data until a successful response arrives

**Security & Privacy Notes**
- Never pre-filling the password field (above) prevents the previously
  saved secret from ever being displayed back to the UI layer at all.
- Same "never logged" and HTTPS-only requirements as US-CRED-02.

**UI / Design Notes**
- Same glass bottom sheet as add-server, pre-filled except password.

**Non-Functional Notes**
- NFR-SEC-01, NFR-TEST-01

---

### US-CRED-04 — Delete a Jenkins server

**Priority:** Must
**Source:** tasks/phase-3-credentials-management.md (P3-09)
**Dependencies:** US-CRED-01

As a user
I want to remove a saved Jenkins server I no longer use
So that my server list and my stored credentials stay current

**Acceptance Criteria**
- Scenario: Delete a non-active server
  Given I delete a server that is not the active one
  When I confirm
  Then `DELETE /api/credentials/:id` is called and it's removed from the
  list with no other side effects
- Scenario: Delete the active server
  Given I delete the server currently marked active
  When the deletion succeeds
  Then the app automatically falls back to another `isDefault`/first
  remaining server as active (rebuilding the Jenkins Dio client
  accordingly); if no servers remain, I am routed into the add-server flow,
  not left pointing at a server that no longer exists
- Scenario: Confirmation required
  Given I tap delete on any server
  Then a confirmation step is required before the request is sent —
  deletion is destructive and irreversible from the app's perspective
- Scenario: Delete failure
  Given the delete request fails
  Then the server remains in the list with an `AppFailure`-mapped error
  shown, and no local optimistic removal is left in an inconsistent state

**Security & Privacy Notes**
- Deleting a server is the user's way of revoking the app's access to it —
  confirm the credential is genuinely gone server-side (not just hidden
  client-side) as part of testing this story.

**UI / Design Notes**
- Confirmation dialog as a glass sheet, consistent with US-AUTH-04's
  logout confirmation pattern.

**Non-Functional Notes**
- NFR-SEC-01, NFR-TEST-01

---

### US-CRED-05 — Switch the active Jenkins server

**Priority:** Must
**Source:** tasks/phase-3-credentials-management.md (P3-04, P3-05)
**Dependencies:** US-CRED-01

As a user managing multiple Jenkins servers
I want to switch which one is "active"
So that the job tree, build actions, and logs I see are scoped to the
server I actually mean to use right now

**Acceptance Criteria**
- Scenario: Switch succeeds
  Given I select a different saved server as active
  When the switch completes
  Then `POST /api/credentials/switch/:id` flips the backend's `isDefault`
  flag, `ActiveServerNotifier` updates immediately for instant UI feedback
  (not waiting on a refetch), and the Jenkins Dio client is rebuilt with
  the new server's Basic Auth credentials before any subsequent Jenkins
  call is made
- Scenario: Job tree reflects the new server
  Given I switch servers while viewing the job tree
  Then the job list refreshes against the newly active server rather than
  showing stale data from the previous one
- Scenario: Switch request fails
  Given the backend switch call fails
  Then the previously active server remains active (no client-side
  optimistic flip that later has to be silently reverted) and an
  `AppFailure`-mapped error is shown
- Scenario: Active server's Jenkins auth is invalid
  Given the active server's saved credentials are rejected by Jenkins
  (401/403)
  Then this is surfaced as a per-server `AuthFailure` scoped to that
  server — offering to re-check/edit that server's credentials — and does
  **not** log the user out of their backend session (see US-AUTH-05)

**Security & Privacy Notes**
- The two Dio clients (`BackendApiClient`, `JenkinsApiClient`) must never
  share interceptors — switching servers rebuilds only the Jenkins client;
  the backend auth header is untouched.

**UI / Design Notes**
- Switching is a single tap in the glass server list from US-CRED-01; the
  newly active row's highlight animates rather than jump-cutting, to make
  the switch feel deliberate against the frosted background.

**Non-Functional Notes**
- NFR-SEC-01, NFR-SEC-03, NFR-TEST-02

---

### US-CRED-06 — Test connection before trusting a server

**Priority:** Must
**Source:** tasks/phase-3-credentials-management.md (P3-08)
**Dependencies:** —

As a user adding or editing a server
I want to verify the URL and credentials actually work before relying on
them
So that I don't save a broken configuration and only discover it later when
trying to trigger a real build

**Acceptance Criteria**
- Scenario: Test succeeds
  Given I fill in URL/username/password in the add/edit form and tap
  "Test connection"
  When a `GET {baseURL}/api/json` call succeeds using a throwaway (non-active)
  Dio instance built from the in-progress form values
  Then I see a success indicator with the detected job count, and this does
  **not** disturb the currently active server's session/client
- Scenario: Test fails — bad credentials
  Given Jenkins returns 401/403 for the test call
  Then I see a specific "authentication failed" message distinct from a
  general connectivity failure
- Scenario: Test fails — unreachable host
  Given the URL is unreachable/times out
  Then I see a `NetworkFailure`-mapped "can't reach this server" message
  distinct from the auth-failure case above, so I know which field to fix
- Scenario: Test is optional, not gating
  Given a test has failed or hasn't been run
  Then I am still allowed to save (per US-CRED-02's rationale — a
  temporarily-down Jenkins shouldn't block saving otherwise-correct
  credentials), with the failed/untested state clearly shown, not hidden

**Security & Privacy Notes**
- The throwaway Dio instance used for testing must be discarded after the
  call — it must not leak the in-progress (possibly not-yet-saved)
  password into any shared client, log, or state that outlives the form.

**UI / Design Notes**
- Result indicator (success/fail) rendered inline in the glass form sheet,
  using the same distinguishable status iconography as US-DESIGN-05
  (not relying on color alone).

**Non-Functional Notes**
- NFR-SEC-01, NFR-TEST-02
