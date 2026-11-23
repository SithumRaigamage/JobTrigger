# Phase 31 — Richer support reports and screenshots

Approved 2026-11-23 for **1.1**. Sources:
`docs/user-stories/shared/11-support.md` (US-SUP-05…07),
`docs/design/phase-31-support-extended.md`. Phase 25 delivered trackable
tickets; this phase adds the context and pictures the owner kept having to ask
for. All three projects change. No new Flutter package; `file_picker` is
already approved for local files.

Rules for every task: layered per `CLAUDE.md` §4, no business logic in widgets,
secrets stay out of the repository, and the full suites on all three projects
run before a PR (not only the tests for what changed).

- [x] P31-01 **Story and design.** US-SUP-05…07 and
      `docs/design/phase-31-support-extended.md` in place before code; this
      task file and `tasks/README.md` track the work.
- [x] P31-02 **Backend storage and validation.** `SupportTicket` gains
      `areas` (array), `impact` (enum) and encrypted `screenshots` (data, mime,
      size, hash, `deleteAt`). `POST /api/support/tickets` accepts the three
      new fields plus up to 3 base64 JPG/PNG files (5 MB each), validates
      magic bytes, returns 413/415 for bad files, and keeps the text scrubber
      and rate limit. Tests: valid, unknown values, too many/oversized/wrong
      type, encryption at rest, no bytes in the caller's own list.
- [x] P31-03 **Backend owner routes and retention.** `GET
      /api/admin/support/tickets/:id` (detail with screenshot metadata) and
      `GET /api/admin/support/tickets/:id/screenshots/:index` (binary,
      `no-store`); super-admin only, normal account 404. A daily job after
      `lib/studentJobs.js` clears screenshot bytes 30 days after creation and
      records the deletion. Owner email adds the new options and a screenshot
      count/admin link, never image attachments. Tests: role checks, byte
      round-trip, headers, cleanup, email content.
- [x] P31-04 **App form.** Domain enums and `SupportTicket` fields, DTO/repository
      (base64 upload with the existing Dio client), notifier and
      `SupportScreen`: seven category chips, optional multi-select areas,
      required impact, screenshot pick/preview/remove with the blur warning
      and size/type limits. Tests: field payload, selection, picker limits,
      remove, success/failure, and unchanged diagnostics behaviour.
      Verified: focused support tests 11/11; full suite 1,998 passed / 29
      skipped; `flutter analyze` and format clean.
- [x] P31-05 **Website signed-in form.** `/support` files the same rich ticket
      through a Server Action after reading the Next.js docs named in
      `JobTrigger-Web/AGENTS.md`. Signed-out visitors keep the existing FAQ and
      email fallback (P25-05). Tests: action validation, upload limits,
      success/failure UI, page smoke.
      Verified: `npm run check` clean; e2e 214 passed (incl. new support spec).
- [x] P31-06 **Website owner review.** `/admin/support` queue and
      `/admin/support/[id]` detail with thumbnails, full-image route and the
      existing status control. Tests: super-admin gate, filters, detail,
      image response, normal-account 404, e2e smoke.
      Verified: `support-view`/`admin-support` unit tests; e2e "reaches the
      owner console" + normal-account 404, both desktop and mobile.
- [ ] P31-07 **Docs and full verification.** Update `docs/api-reference.md`,
      `docs/data-models.md`, release notes when 1.1 is cut, sync-tools and the
      checklist. Run `flutter analyze`, full `flutter test`, backend `npm
      test`, website `npm run check` and `npm run e2e`, `sync-tools --check`
      and a gitleaks scan; tick each story criterion against real code.
      Done: API/data-model docs, all four full suites (Flutter 1,998/29;
      backend 529; web check clean; web e2e 214), `sync-tools --check` clean,
      gitleaks clean on both staged and unstaged diffs, all US-SUP-05…07
      criteria ticked. **Remaining:** add the 1.1 release-notes entry when the
      release branch is cut (release management, not code). Full-history
      gitleaks still reports 42 pre-existing fixture keys (not in this diff);
      the whole-repo count rose from the documented 21 with the owner's
      `ec8c1bd promotions` commit — needs a separate owner decision.
- [ ] P31-08 **iPhone pass (MANUAL, owner).** Install with
      `scripts/run-on-iphone.sh`, file a ticket with screenshots from Profile →
      Support, check the previews and blur warning, and confirm the owner can
      see it on the website. Record under `manually/`.

Not in this phase: camera capture (new `image_picker` dependency), a reply
thread, an in-app FAQ, a store rating prompt, and a GlitchTip event id on a
ticket.
