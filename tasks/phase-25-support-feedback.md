# Phase 25 — Support and issue tickets

Approved 2026-11-18. Before this phase, "support" was a `mailto:` row in App
Info and on tool selection: no record, no status, no triage and no
diagnostics. Tickets are the smallest change that closes that gap without a
new package or a second auth system.

Rules for every task: layered per `CLAUDE.md` §4, no new packages, and the
whole `flutter test` suite (not only the new tests) plus `npm test` in the
backend before PR. Anything only checkable on the owner's phone stays
**UNVERIFIED** and is recorded in `manually/`.

- [x] P25-01 **Ticket storage.** `models/SupportTicket.js`: owner, category
      (`bug` | `feature` | `question` | `tool_request`), subject (≤120),
      message (≤4000), reply email, diagnostics (version/build, tool,
      platform, `serverHost` = scheme+host+port only) and status (`open` |
      `triaged` | `closed`). Deleted with the account.
- [x] P25-02 **File and read reports.** `POST /api/support/tickets` (auth,
      5 per user per hour) and `GET /api/support/tickets` for the caller's
      own. Subject and message are validated, control characters stripped,
      and the text passes the same scrubber as crash reports, so a pasted
      token is stored as `[redacted]`. A sent `serverHost` keeps only scheme,
      host and port. `emails/supportTicket.js` notifies the owner best-effort:
      a mail failure is logged and the ticket is still created.
- [x] P25-03 **Owner triage.** `GET /api/admin/support/tickets` and
      `PATCH …/:id` behind `requireSuperAdmin`; a normal account gets 404.
- [x] P25-04 **In-app Support screen.** `lib/presentation/features/support/`
      (form, sent state, "Your reports"), reached from Profile and App Info;
      the tool-selection link opens it as a tool request. Diagnostics are
      shown in the switch's subtitle, not attached silently.
- [x] P25-05 **Website.** `/support` now says where a report goes (in the app)
      and keeps the email as the fallback; no anonymous public form.
- [x] P25-06 **Docs and tests.** API and data-model entries, the user story,
      backend `test/support_tickets.test.js`, and app tests for diagnostics,
      the form (success, validation, failure), the prefilled tool request and
      all three entry points. iPhone pass: `manually/M-11`.

Not in this phase: a GlitchTip event id on a ticket, an in-app FAQ, a store
rating prompt, or a reply thread inside the app.