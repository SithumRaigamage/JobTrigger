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

## Out of scope

Attaching a crash-report event id, an in-app FAQ, a store rating prompt, and a
reply thread inside the app (that needs ticket messages and notifications).