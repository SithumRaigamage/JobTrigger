# Owner decisions of 2026-11-21 — design

Five decisions taken after the user-story re-tick
(`Releases/v1.0.0/story-retick-2026-11-21.md`). The stories were updated
first; each section names the criteria it closes, the layers it touches and
the tests it needs.

## 1. Switching servers updates the backend default

Criteria: US-CRED-05 "Switch succeeds" / "Switch request fails",
US-GH-CRED-03 "Switch succeeds", US-SQ-CRED-03 "Switching updates…",
US-WEB-18 "App follows".

- **App.** The three active-credential notifiers (Jenkins, GitHub,
  SonarQube) share one rule, in `lib/data/credentials/default_choice_sync.dart`:
  - Choosing a credential applies on the phone at once (as today), stores
    its id as *pending*, then calls the tool's existing
    `switchActive(id)` (`POST /api/<type>/switch/:id`). Success clears the
    pending id; failure keeps it.
  - On every real reload of that tool's credential list: a pending id is
    retried (or dropped if that credential is gone); with nothing pending,
    the backend default wins, so a default chosen on the website or
    another phone reaches this one (US-WEB-18).
  - Cold start picks: pending → backend default → the id saved on the
    phone → first. If the pick isn't the backend default, it is pushed.
  - Pending ids are user-scoped prefs, cleared on logout (AUD-28).
- **Backend.** Not needed: the switch endpoints exist and are tested.
- **Web.** Not needed: "Make active" already calls them (US-WEB-18).
- **Tests.** Switch calls the backend; a failed switch keeps the choice and
  retries on reload; pending blocks a different backend default; a backend
  default is followed with nothing pending; cold start order; per tool.

## 2. The Jenkins edit form starts empty for the secret

Criterion: US-CRED-03 "Password field starts empty".

- **App.** `server_edit_bottom_sheet.dart`: the token field starts empty
  with "Leave blank to keep current."; saving or testing with it blank uses
  the stored secret (the backend refuses a blank one). A secret that could
  not be read (AUD-63) must still be typed again. Same as the GitHub sheet.
- **Backend, web.** Not needed.
- **Tests.** Empty on edit; blank keeps the stored secret; a new value
  replaces it; Test connection uses the stored secret when blank.

## 3. Returning users skip tool selection

Criterion: US-TOOL-01 "Returning user skips re-selection".

- **App.** The chosen tool is saved (user-scoped pref `active_tool`).
  `returningToolProvider` picks the saved tool if it still has a saved
  credential (or if the lists can't be read), else the first tool with a
  saved credential, skipping a tool the plan locks. Tool selection shows a
  progress indicator while it decides, then goes Home with that tool. It is
  shown as today when nothing is saved, and always when reached from
  Profile → "CI tool" (`/tools?choose=1`).
- **Backend, web.** Not needed.
- **Tests.** Saved tool skips; first tool with a server skips; no server
  shows the picker; `choose=1` always shows it; a locked tool is skipped.

## 4. Website "Request a tool": Support ticket when signed in

Criterion: US-WEB-04 "Request a tool".

- **Web.** Signed in, "Request a tool" opens `/support/request-tool`, a
  portal form (subject prefilled "Tool request: ", details) whose server
  action posts `POST /api/support/tickets` with `category: tool_request`
  (backend limits: subject 120, message 4,000). It shows the ticket id and
  reply address. Signed out, the link stays the support email.
- **Backend.** Not needed: the endpoint exists (US-SUP-01).
- **App.** Not needed: it already files a ticket (P25-05).
- **Tests.** Unit: the action validates, sends the category, maps
  failures; the link differs signed in and out. E2E: a signed-in request
  files a ticket (fake backend).

## 5. Reload credentials when the app returns to the foreground

Criterion: US-WEB-17 "App picks it up on return".

- **App.** `credentialsResumeReloaderProvider`, watched by the app root:
  when the app resumes while signed in (not demo), it reloads the
  Jenkins, GitHub and SonarQube credential lists, at most once every 30
  seconds. The reload also retries a pending default (decision 1).
- **Backend, web.** Not needed.
- **Tests.** Resume reloads all three; a second resume within 30 s does
  not; signed out does nothing.

## 6, 7. Region and address

Render `singapore`, Vercel `sin1` and the Atlas cluster in AWS
`ap-southeast-1` (confirmed). No postal address field.
