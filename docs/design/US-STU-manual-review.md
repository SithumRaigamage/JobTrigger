# US-STU-01…03 — manual review of every student application (design)

Owner decisions of 2026-11-22. Stories:
[`docs/user-stories/billing/23-student-plan.md`](../user-stories/billing/23-student-plan.md).

## Backend (`JobTrigger-Backend`)

**Model.** `StudentVerification` gains `emailVerifiedAt` (Date, null).
`pending` now has two meanings for the email method:

| method | `emailVerifiedAt` | meaning |
|---|---|---|
| email | null | a code was asked for; not an application yet |
| email | set | verified, waiting for review |
| document | — | waiting for review (unchanged) |

No migration is needed: before this change an email application was never
left `pending` after confirming, so old pending email rows are all "waiting
for a code".

**`POST /api/student/email/confirm`.** The checks on the code are unchanged
(10 minutes, salted hash, 5 tries, atomic count). On the right code it sets
`emailVerifiedAt`, clears the code fields and keeps `status: 'pending'`.
Before that it refuses with 409 `email_used` when the email is claimed
(`StudentClaim`), or another account has a verified-pending or granted
application for it. It sends the owner notice (the application now exists)
and returns the public view with `emailVerified: true`. No grant.

**`GET /api/student`.** A pending email row without `emailVerifiedAt` is
reported as `{ status: 'none' }`. The public view gains `emailVerified`.

**`applicationBlock`.** A verified email row that is waiting counts as
`under_review` (message: "Your student application is already waiting for
review.").

**Admin routes.**
- `GET /access` (declared before `/:id`): `{ role: 'superAdmin' }` behind the
  existing `auth → adminLimiter → requireSuperAdmin` chain, so anyone else
  gets the same plain 404. This is how the app decides to show the row;
  `role` is still on no account route.
- `GET /` lists both methods. `pending` (and `all`) leave out email rows
  without `emailVerifiedAt`. Sorted newest first (`createdAt: -1`), 50 per
  page. Items gain `emailVerifiedAt`, `reviewedBy` and `reviewedByEmail`
  (looked up with the account emails, `null` if the reviewer was deleted).
- `approve` works for both methods. Email: requires `emailVerifiedAt` (else
  409), claims `emailHash(universityEmail)` (renewal rules as before), the
  same atomic `pending → approved` update, then `grantStudentYear`. On a lost
  race it releases the claim it just made. Documents unchanged.
- `reject` works for both methods; it schedules the 30-day document
  deletion only for documents. An unverified email row is 409.
- `get` and `document` unchanged (document stays document-only, 404 for
  email rows).

## Website (`JobTrigger-Web`)

- `src/server/admin-students-api.ts`: the zod item gains `emailVerifiedAt`,
  `reviewedByEmail` (nullable, defaulting to null so an older backend still
  parses).
- `students-view.tsx`: each row shows the name or university email, the
  method, status, submitted date and "decided <date> by <reviewer>". The
  detail rows add method, university email and reviewer. `ReviewForms`
  shows for any pending application.
- `student-card.tsx` / the app copy: "Pending review" says "Your university
  email is verified…" for the email method; the rejection title becomes
  "We couldn't approve your application" for email.
- `student-api.ts` (user side) accepts `emailVerified`.

## App (`JobTrigger-Frontend`)

New feature, three layers (CLAUDE.md §4):

- `lib/domain/admin_review/` — `AdminStudentApplication` (plain Dart),
  `AdminStudentDocument { mime, bytes }`, `AdminStatusFilter`, and the
  `AdminReviewRepository` interface: `hasAccess()`, `list(filter)`,
  `get(id)`, `document(id)` (null = deleted, 410), `approve(id)`,
  `reject(id, reason)`.
- `lib/data/` — `AdminStudentDto` (freezed) and `AdminReviewRepositoryImpl`
  on the backend `Dio` (`dioBackendProvider`). The document is fetched with
  `ResponseType.bytes`; failures map through `AppFailure.fromStudentException`
  so 409/400 sentences reach the screen as `StudentRequestFailure`. Demo
  mode gives a repository whose `hasAccess` is false and that never calls
  anything.
- `lib/presentation/features/admin_review/`
  - `adminAccessProvider` (`@riverpod Future<bool>`): false when signed out
    or in demo mode, otherwise `hasAccess()`; failure → false. Watched by
    Profile and by the route guard.
  - `AdminApplicationsNotifier` (family by filter): the list, refresh.
  - `AdminApplicationNotifier` (family by id): the detail and the document
    (`AsyncValue<AdminStudentDocument?>` held in memory), `approve()`,
    `reject(reason)` with a `busy`/`failure` state; on success it replaces
    the item and invalidates the lists.
  - `AdminApplicationsScreen` (route `/profile/student-applications`):
    filter chips Pending/Approved/Rejected/Ended/All, rows, pull to refresh.
  - `AdminApplicationScreen` (`/profile/student-applications/detail`, extra =
    id): details card, the document, and Approve/Reject buttons that open
    confirmation dialogs (reject has a reason field).
  - The document: images use `Image.memory` (`gaplessPlayback`, no cache
    package); PDFs go through `PdfPageRenderer`, a `MethodChannel`
    (`jobtrigger/pdf`) that draws each page to PNG bytes in memory —
    iOS with PDFKit (`PDFDocument(data:)`), Android with `PdfRenderer` over
    an anonymous `memfd` (API 30+; older Android shows "Open this PDF on the
    website"). Nothing is written to disk; no new package (CLAUDE.md §3).
- Profile: a "Student applications" row inside the account card when
  `adminAccessProvider` is true (independent of billing).
- Router: the two routes redirect Home when access is false.

## Tests

See the story's table. Each criterion gets at least one test; the
native PDF drawing is checked on the iPhone (unverified in CI).
