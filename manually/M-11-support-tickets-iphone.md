# M-11 — Support tickets on the iPhone (UNVERIFIED)

Phase 25 (P25-01..06). Nothing here has been tapped on a phone.

## Mac

1. Backend running against the dev database, reachable at the Mac's Wi-Fi
   address (`ipconfig getifaddr en0`): `cd JobTrigger-Backend && npm start`.
2. Mail is optional: without `SMTP_HOST` the ticket is stored and
   `mail.disabled` is logged, which is fine for this pass.
3. Install the build: `scripts/run-on-iphone.sh`.

## Phone

4. Sign in, then Profile → **Support**.
5. Choose **Bug**, type a subject and a short detail, leave **Attach app
   details** on, and tap **Send report**.
6. The card says "Report sent", the ticket id, and the account email.
7. Scroll down: **Your reports** lists the ticket as **Sent**.
8. App Info → **Contact support** opens the same screen (it no longer drafts
   an email); the address is offered at the bottom as "Or email …".
9. Tool selection → **Need another tool? Tell us** opens the form with
   **Tool request** selected and "Tool request: " in the subject.
10. Airplane mode: sending shows a network error and the text stays in the
    form.

## Mac, after

11. Check the ticket exists and the diagnostics stop at the host:
    `db.supporttickets.find().sort({createdAt:-1}).limit(1)` in the dev
    database. `serverHost` must look like `https://ci.example.com:8443`, with
    no path or query.
12. As a super admin, `GET /api/admin/support/tickets` lists it and
    `PATCH` moves it to `triaged`; as a normal account both answer 404.