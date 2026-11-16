# Phase 21 — Student Plan (epic STU)

**Approved by the owner, November 2026.** Verified students get Pro free for
one year. Follow `CLAUDE.md`: plan before code, logic in notifiers, analyze
clean, no new tools or dependencies without approval, never read `.env`,
Jenkins frozen (§11).

## Decisions (owner)

- Verified students get Pro free for exactly **365 days from approval**.
- **Not renewable for now.** On expiry the account drops to Free. Keep the code
  ready for yearly renewal later behind one config flag, off
  (`STUDENT_RENEWAL_ENABLED=false`).
- **One student grant per person, ever.** Block reuse of the same university
  email or the same document.
- Verification: **university email one-time code first**; fallback **student ID
  or enrolment letter upload**, approved manually.
- **No third-party verification service** (SheerID etc.) in this phase.
- **Admin approval page on the website only**, behind a super-admin role.
  Nothing admin-related ships in the mobile app.
- Uploads are stored **in MongoDB** (no blob storage, no new tool), max **5 MB**,
  **JPG, PNG or PDF** only.
- Every new application **emails the owner** (details and a link to the admin
  page, never the document itself).

## Implementation notes (from the plan review, 2026-11-16)

These fit inside the decisions above; they are how to build them safely.

1. **Billing comes first.** With `BILLING_ENABLED` off everyone is already Pro,
   so a student grant changes nothing visible. The verify entry, the Pro
   (Student) label and the pricing note show only when billing is available,
   exactly like the other Phase 20 screens. The backend flows still work and
   are fully tested with billing on.
2. **Expiry is computed, not scheduled.** A grant is active when
   `now < expiresAt`, checked whenever entitlements are read. The daily job
   only sends reminders and marks records `expired`; a missed run can never
   leave someone on Pro past their date.
3. **Encrypt documents at rest.** Student IDs are personal data. Store the bytes
   encrypted with the existing `security/secretCipher` (AES-256-GCM, key from
   the environment, field bound in as associated data), like tool secrets.
   Never log them; never return them in list responses.
4. **No upload library.** The backend has no multipart parser and adding one
   needs approval. Send the file as base64 in JSON on the upload route only,
   with a route-specific body limit (about 7 MB, since base64 is a third larger
   than the 5 MB file). Check type by the file's leading bytes, not only the
   name.
5. **Super-admin role.** `User` has no role today. Add `role`
   (`user` | `superAdmin`, default `user`), set only by a local-only script
   (`scripts/grant-role.js`, same guard as `grant-plan.js`), never through any
   API. Every admin route checks it on the server.
6. **One per person, even after account deletion.** Keep a SHA-256 hash of each
   used university email and each document after the account or record is
   deleted, so a deleted-and-recreated account can't claim again. The privacy
   policy says so.
7. **Viewing a document.** The website's server fetches it from the admin route
   with the admin's session and streams it to the admin page with
   `Cache-Control: no-store`. No public URL exists at any point.
8. **Owner email.** Sent to `STUDENT_ADMIN_EMAIL` (config) through the existing
   mailer (Mailpit in development): student name, account email, university
   email, method, submitted time, link to `/admin/students/<id>`. No attachment.
9. **App upload** uses the already-approved `file_picker`. No camera package.
10. **Daily job** uses the backend's existing in-process timer pattern
    (as `lib/errorReporting/outbox.js`), plus a script for running it by hand.
    No scheduler dependency.

## Tasks

### SP-1 Backend: plan and data
- [ ] SP-10 Student entitlement source alongside store/web/grant: plan Pro,
      source `student`, `startsAt`, `expiresAt`.
- [ ] SP-11 Entitlements: an active student grant counts as Pro; a paid
      subscription always wins over it.
- [ ] SP-12 `StudentVerification` model: userId, method (`email`|`document`),
      universityEmail, status (`pending`|`approved`|`rejected`|`expired`),
      encrypted document, document hash, reviewer, timestamps, rejection reason.
- [ ] SP-13 Allowed university domains in a seeded, owner-editable config list
      (start with `ac.lk` and common `.edu`).
- [ ] SP-14 Unique constraints and kept hashes so a university email or document
      can only ever be used once (note 6).
- [ ] SP-15 `role` on `User` and `scripts/grant-role.js` (note 5).
- [ ] SP-16 Tests: grant, computed expiry, one-per-person (including after
      deletion), paid overrides student.

### SP-2 Backend: email code flow
- [ ] SP-20 `POST /api/student/email/start`: domain on the list, send a 6-digit
      code (10-minute expiry, hashed at rest, max 5 attempts, rate limited).
- [ ] SP-21 `POST /api/student/email/confirm`: correct code approves and grants
      365 days at once.
- [ ] SP-22 Owner notification email on every application (note 8).
- [ ] SP-23 Tests, including wrong code, expired code, attempt limit, reused email.

### SP-3 Backend: document flow and admin
- [ ] SP-30 `POST /api/student/document`: base64 JPG/PNG/PDF, max 5 MB checked
      on the server ("File too large, max 5 MB"; type rejected with a message),
      encrypted at rest, status `pending`, owner email sent.
- [ ] SP-31 Admin routes (super-admin only, server-checked, rate limited,
      logged): list pending, search by user, view document (note 7), approve
      (365 days) or reject with a reason.
- [ ] SP-32 Delete document bytes 30 days after a decision (keep the hash).
- [ ] SP-33 Tests: size and type limits, non-admin gets 404, approve and reject.

### SP-4 App (Flutter)
- [ ] SP-40 Subscription screen: "Verify student status" entry (billing on only).
- [ ] SP-41 Flow: university email → code; domain not listed → document upload
      with the 5 MB and type check before sending.
- [ ] SP-42 States: pending review, approved with expiry date, rejected with
      reason and retry; Account shows "Pro (Student)" and the expiry date.
- [ ] SP-43 Logic in notifiers; widget tests for every state; demo mode
      read-only. Privacy manifest and store answers cover the uploaded document.

### SP-5 Website
- [ ] SP-50 The same verify flow on the Account page, with the same client-side
      size and type checks.
- [ ] SP-51 `/admin/students`: pending queue, document viewer, approve and
      reject, search by user. Non-admins get a 404.
- [ ] SP-52 `/pricing`: "Students get Pro free for one year" (billing on only).
- [ ] SP-53 Privacy policy: student verification data, the 30-day deletion and
      the kept hashes.

### SP-6 Reminders and expiry
- [ ] SP-60 Daily job: email and in-app banner 7 days before expiry.
- [ ] SP-61 On expiry: status `expired`, plan back to Free, the locked
      active-credential guard applies as for a lapsed paid plan.
- [ ] SP-62 Tests for the reminder and the downgrade.

## Done when
- All checks green in CI, `flutter analyze` clean, backend, web and widget tests pass.
- Email path and upload path both tested end to end in development with Mailpit.
- Owner checks the admin page and an approval on the iPhone app.
