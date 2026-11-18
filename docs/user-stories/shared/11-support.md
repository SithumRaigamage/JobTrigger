# US-SUP — Support and feedback

Approved 2026-11-18 as Phase 25. The app had one way to reach support: a
`mailto:` link that opened a draft in the user's mail app. Nothing was
recorded, nothing could be triaged, and a phone with no mail account set up
could not send anything at all.

## US-SUP-01 — Report a problem

As someone whose build log is blank, I want to report it from the screen I am
on, so that I don't have to describe my setup from memory in an email.

Acceptance:
- Profile → Support opens a form with four kinds: Bug, Feature idea,
  Question, Tool request.
- Subject and details are required; the composer says not to paste tokens.
- "Attach app details" is on by default and shows exactly what it attaches:
  version/build, tool, platform and the server's scheme+host+port. It never
  includes a job path, a username or a credential.
- Sending stores a ticket and shows its id and the reply address. A failure
  keeps the text in the form and says why.

## US-SUP-02 — See what happened to my report

As someone who reported twice, I want to see whether the team has looked at
it, so that I don't file the same thing again.

Acceptance: the Support screen lists my earlier reports with a status
(Sent / In review / Closed) and the date.

## US-SUP-03 — Request a tool

As someone who uses GitLab CI, I want the "Need another tool?" link to record
my request, so that requests can be counted instead of living in a mail box.

Acceptance: the link opens the Support form with Tool request selected and a
prefilled subject.

## US-SUP-04 — Answer from the owner's side

As the owner, I want each ticket in one place with the report and its
diagnostics, so that I can triage without asking the user for their version.

Acceptance: `GET /api/admin/support/tickets` (super admin only) lists every
ticket and `PATCH …/:id` moves it to triaged or closed; the report email
carries the same content. A normal account sees a 404, not the admin API.

## Out of scope

Attaching a crash-report event id, an in-app FAQ, a store rating prompt, and a
reply thread inside the app (that needs ticket messages and notifications).