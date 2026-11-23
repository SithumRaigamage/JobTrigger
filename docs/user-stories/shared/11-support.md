# US-SUP — Support and feedback

Approved 2026-11-18 as Phase 25. The app had one way to reach support: a
`mailto:` link that opened a draft in the user's mail app. Nothing was
recorded, nothing could be triaged, and a phone with no mail account set up
could not send anything at all.

## US-SUP-01 — Report a problem

As someone whose build log is blank, I want to report it from the screen I am
on, so that I don't have to describe my setup from memory in an email.

Acceptance:
- [x] Profile → Support opens a form with four kinds: Bug, Feature idea,
  Question, Tool request.
  Evidence: `test/presentation/features/profile/profile_screen_test.dart` "the account section opens Support"; Fixed 2026-11-21: test added: `test/presentation/features/support/support_screen_test.dart` "the form offers four kinds and warns about tokens".
- [x] Subject and details are required; the composer says not to paste tokens.
  Evidence: `support_screen_test.dart` "an empty form names the missing field and sends nothing"; Fixed 2026-11-21: tests added: "details are required too", "the form offers four kinds and warns about tokens" ("Do not paste tokens or passwords."); backend `test/support_tickets.test.js` "rejects an unknown category, an empty body and oversized fields".
- [x] "Attach app details" is on by default and shows exactly what it attaches:
  version/build, tool, platform and the server's scheme+host+port. It never
  includes a job path, a username or a credential.
  Evidence: `support_screen_test.dart` "sends a report with only host-level diagnostics" and (added 2026-11-21) "the form offers four kinds and warns about tokens" (on by default; the summary shows version and host:port, not the job path or server name); `test/domain/support/support_diagnostics_test.dart` "drops the path, query, fragment and any credentials"; backend `support_tickets.test.js` "stores no credential and keeps only the host of a server URL".
- [x] Sending stores a ticket and shows its id and the reply address. A failure
  keeps the text in the form and says why.
  Evidence: `support_screen_test.dart` "sends a report with only host-level diagnostics" ("Report sent", "Ticket t1", the reply address) and "a failed send keeps the form and shows the reason" (typed text kept, checked 2026-11-21); backend `support_tickets.test.js` "files a ticket that belongs to the caller, and lists only their own".

## US-SUP-02 — See what happened to my report

As someone who reported twice, I want to see whether the team has looked at
it, so that I don't file the same thing again.

Acceptance:
- [x] the Support screen lists my earlier reports with a status
  (Sent / In review / Closed) and the date.
  Evidence: `support_screen_test.dart` "pull-to-refresh reloads earlier reports and their status" (Sent → In review) and, added 2026-11-21, "earlier reports show status and date" ("Closed · 2026-11-20").

## US-SUP-03 — Request a tool

As someone who uses GitLab CI, I want the "Need another tool?" link to record
my request, so that requests can be counted instead of living in a mail box.

Acceptance:
- [x] the link opens the Support form with Tool request selected and a
  prefilled subject.
  Evidence: `test/presentation/features/tool_selection/tool_selection_screen_test.dart` "the tool request opens Support as a tool request"; `support_screen_test.dart` "a prefilled tool request starts as a tool request" (chip selected, subject "Tool request: ").

## US-SUP-04 — Answer from the owner's side

As the owner, I want each ticket in one place with the report and its
diagnostics, so that I can triage without asking the user for their version.

Acceptance:
- [x] `GET /api/admin/support/tickets` (super admin only) lists every
  ticket and `PATCH …/:id` moves it to triaged or closed; the report email
  carries the same content. A normal account sees a 404, not the admin API.
  Evidence: backend `test/support_tickets.test.js` "lets a super admin list every ticket and move it to triaged" (closed asserted too, 2026-11-21), "keeps triage to the owner: a normal account gets a 404", "sends the owner a notification carrying the report".

## US-SUP-05 — Tell us more about the problem

Approved 2026-11-23 for **1.1** (`tasks/phase-31-support-extended.md`). The
four chips are fine for classifying a ticket, but they do not say which tool
was involved or how badly it is broken.

As someone filing a report, I want to select the affected areas and the impact
without writing a paragraph, so that the owner can triage it at a glance.

Acceptance:
- [x] The app's Support form and the website's signed-in form offer seven
  primary categories: Bug, Feature idea, Question, Tool request, Account &
  sign-in, Billing & subscription, Something else. The four existing wire
  values stay unchanged, so old tickets and the tool-request link still read.
  Evidence: app `support_screen_test.dart` "seven category chips …" (1,998
  passing); website `domain/support.test.ts` "the seven categories …" and
  `support-form.test.tsx` "offers seven kinds …"; `npm run check` + e2e clean.
- [x] A multi-select "Affected area" offers Jenkins, GitHub Actions,
  SonarQube, Website, Phone/app and Account; none is required.
  Evidence: app `support_screen_test.dart` area selection; website
  `support-form.test.tsx` "submits the held files with the text and options"
  (two areas in the payload); e2e `support-report.spec.ts` checks two.
- [x] A single "Impact" select offers Blocked, Major and Minor.
  Evidence: app `support_screen_test.dart`; website `support-form.test.tsx`
  "offers seven kinds, the areas, the impact …"; backend
  `test/support_extended.test.js` rejects an unknown impact.
- [x] Subject, details, reply email and the diagnostics toggle behave exactly
  as in US-SUP-01; the form never asks for a token or password.
  Evidence: app `support_screen_test.dart` "a failed send keeps the form …"
  and the unchanged diagnostics tests (all passing); the form keeps
  "Do not paste tokens or passwords."; website `actions.test.ts` shows the
  reply address from the session and no token field.
- [x] The new fields are stored on the ticket, shown in the owner's ticket
  detail and included in the notification email.
  Evidence: backend `test/support_extended.test.js` (storage + email body),
  `emails/supportTicket.js` ("Areas: …", "Impact: …"); website
  `server/support-api.test.ts` (detail parses areas/impact) and
  `features/admin/support-view.test.tsx` (detail renders them).

## US-SUP-06 — Attach screenshots

As someone whose build log looks wrong, I want to attach a screenshot, so that
the owner sees what I see instead of asking me to describe it.

Acceptance:
- [x] The app picks JPG or PNG files with the already-approved `file_picker`
  (no camera package); up to 3 files, 5 MB each. The website accepts the same
  limits in its signed-in form.
  Evidence: app `support_screenshots.dart` uses `file_picker` only, with the
  limits in `test/presentation/features/support/support_screen_test.dart`;
  website `domain/support.ts` limits and `features/support/actions.ts`
  "refuses too many or oversized files before anything travels" (unit + e2e).
- [x] Each file shows a preview with a remove control before sending, and the
  form warns to blur tokens, passwords and personal data first.
  Evidence: app `support_screen.dart` preview/remove plus the blur copy in
  `support_screen_test.dart`; website `support-form.test.tsx` "previews a
  picked image and lets it be removed …" and the blur-warning assertion; e2e
  "Remove shot.png" before send.
- [x] The backend checks the file's leading bytes, not its name, and rejects
  wrong types with **415** and oversized files with **413**. At most 3 files
  are stored per ticket.
  Evidence: `test/support_extended.test.js` magic-byte, 413 and 415 cases and
  the 3-file cap (529 backend tests passing).
- [x] Screenshot bytes are encrypted at rest with the same secret cipher used
  for student documents, are never returned to the account on
  `GET /api/support/tickets`, and are deleted 30 days after the ticket is
  created by the daily job.
  Evidence: `test/support_extended.test.js` encryption-at-rest, "no bytes in
  the caller's own list" and the 30-day cleanup cases; `lib/studentJobs.js`
  daily job; AAD `supportScreenshot` in the controller.
- [x] The owner email names the number of screenshots and links to the
  super-admin detail page; images are not sent as email attachments.
  Evidence: `emails/supportTicket.js` "N screenshots … review at /admin/support/:id"
  and `test/support_extended.test.js` email-content assertion.

## US-SUP-07 — Owner reviews a report with its screenshots

As the owner, I want one super-admin page with the report, its options and its
screenshots, so that I can triage without asking the reporter to resend.

Acceptance:
- [x] `/admin/support` lists tickets (newest first, status filter) with their
  category, areas, impact, reporter and screenshot count.
  Evidence: `features/admin/support-view.tsx` queue + status filters, covered
  by `support-view.test.tsx` and `app/(portal)/admin/support/admin-support.test.ts`
  ("defaults to open and ignores an unknown status"); e2e "reaches the owner
  console" asserts the row's category/areas/impact/count.
- [x] `/admin/support/:id` shows full details, screenshot thumbnails and the
  existing status control; each thumbnail opens the full image.
  Evidence: `SupportDetailView` + `SupportStatusForm`, tests in
  `support-view.test.tsx` (thumbnail links to `/screenshots/0`) and e2e
  (status change to closed shows "Marked closed.").
- [x] `GET /api/admin/support/tickets/:id` and the screenshot route require a
  super-admin session; a normal account gets **404**, as in US-SUP-04.
  Evidence: backend `test/support_extended.test.js` role checks; website
  `admin-support.test.ts` "non-admin gets a plain 404" and e2e "a normal
  account gets a plain 404 for the owner's support pages".
- [x] The screenshot route sets `Cache-Control: no-store` and never exposes a
  path, a token or another account's data.
  Evidence: `app/(portal)/admin/support/[id]/screenshots/[index]/route.ts`
  uses the session's own token server-side, allows only image/jpeg|png, sets
  `no-store`/`nosniff`/CSP; `admin-support.test.ts` "streams one image with
  no-store, nosniff and no token" and e2e header assertions.

## Out of scope

Attaching a crash-report event id, an in-app FAQ, a store rating prompt, a
reply thread inside the app (that needs ticket messages and notifications),
and in-app camera capture (would need a new `image_picker` dependency).