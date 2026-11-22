# Epic: STU — Student plan

Verified students get JobTrigger Pro free for 365 days. The plan itself
(entitlement source, email code, document upload, 30-day deletion,
reminders) was built in Phase 21 against tasks SP-1…SP-6
([`tasks/phase-21-student-plan.md`](../../../tasks/phase-21-student-plan.md)).

**Owner decisions, 2026-11-22** (replace the Phase 21 decision "admin
approval page on the website only; nothing admin-related in the mobile
app"):

1. **Every application is approved by hand.** A correct university-email
   code only marks the email as verified; the application stays `pending`
   until a super admin approves it. Only an approval grants the 365 days.
   A rejection always carries a reason the student sees. Document uploads
   are unchanged.
2. **The super admin reviews in the Flutter app** (iOS and Android) as well
   as on the website. The review screen is visible only to an account with
   role `superAdmin`.
3. **History** of every application with dates and reviewer, filterable by
   status, in the app and on the website.

Design: [`docs/design/US-STU-manual-review.md`](../../design/US-STU-manual-review.md).
Tasks: SP-7 in `tasks/phase-21-student-plan.md`.

---

### US-STU-01 — Every student application is reviewed by hand

**Priority:** Must · **Source:** owner decision 2026-11-22, SP-70…SP-73 ·
**Dependencies:** SP-2, SP-3

As the owner
I want every student application, including a verified university email,
to wait for my approval
So that no one gets a free year without a person checking it

**Acceptance Criteria**
- [x] Scenario: correct code → pending, no Pro — Given a student who asked
  for a code, When they enter the right code, Then the answer is
  `status: "pending"` with `emailVerified: true`, no `approvedAt` or
  `expiresAt`, no student source is written and their plan is unchanged.
  Evidence: `JobTrigger-Backend/test/student.test.js` "verifies on the right code, leaves it pending with no Pro, and tells the owner"; `JobTrigger-Backend/test/student_manual_review.test.js` "journey: verify → no Pro → approve → Pro".
- [x] Scenario: owner notice — the owner email is sent when the email is
  verified (the application now needs review), not when a code is asked for.
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "sends the owner notice when the email is verified, not when the code is asked for".
- [x] Scenario: waiting for a code is not an application — Given a code was
  asked for but not confirmed, Then `GET /api/student` reports `none` (the
  user can start again) and the admin list does not show it.
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "a code request is not an application"; `JobTrigger-Backend/test/student.test.js` "counts wrong codes" (status none).
- [x] Scenario: one open application — Given a verified email waiting for
  review, When the user asks for another code or uploads a document, Then
  they get **409** `under_review`.
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "a verified email blocks a second code or a document with under_review"; `JobTrigger-Backend/test/student.test.js` "allows one grant per person".
- [x] Scenario: the email is still one per person — Given another account
  already holds the university email (approved, expired, or verified and
  waiting), When a user confirms a code for it, Then **409** `email_used`.
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "a university email waiting for review on another account is taken", "refuses at confirm when another account verified the same email in between"; `JobTrigger-Backend/test/student.test.js` "refuses at confirm when the email was claimed in between", "still blocks the email after the account is deleted and recreated".
- [x] Scenario: approve an email application — When a super admin approves
  it, Then it becomes `approved`, the email is claimed for good, Pro is
  granted for 365 days from the approval, and the reviewer and time are
  stored.
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "approving an email application grants 365 days, claims the email and records the reviewer".
- [x] Scenario: approve when the email was claimed in between — Then **409**
  `email_used` and the application stays `pending` so it can be rejected
  with a reason.
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "approving when the email was claimed in between is 409 and leaves it pending".
- [x] Scenario: reject an email application — When a super admin rejects it
  with a reason, Then it becomes `rejected` with that reason, nothing is
  claimed, and the student can apply again. A missing or over-500-character
  reason is **400**.
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "rejecting an email application needs a reason, claims nothing, and lets the student try again".
- [x] Scenario: an unverified email application cannot be decided — approve
  or reject on one still waiting for its code is **409**.
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "an email application still waiting for its code cannot be approved or rejected".
- [x] Scenario: the student sees it — app and website show "Pending review"
  with email wording for a verified email, and the rejection reason with
  "Try again" for a rejected one (document wording unchanged).
  Evidence: `JobTrigger-Frontend/test/presentation/features/student/student_verification_screen_test.dart` "US-STU-01: the right code leads to Pending review, not Pro", "US-STU-01: a rejected email application shows the reason and Try again", "a pending document keeps the document wording"; `JobTrigger-Web/src/features/student/student-card.test.tsx` "pending review of a verified university email says so", "a rejected email application shows the reason with Try again".

**Security & Privacy Notes** — the grant happens only on the server, only
from a super-admin route; the client can't make a code grant Pro.

**Impact** — Backend: yes (confirm, approve, reject, list, status).
App: yes (copy for the email pending/rejected states). Web: yes (same copy).

---

### US-STU-02 — Review student applications in the app

**Priority:** Must · **Source:** owner decision 2026-11-22, SP-74…SP-78 ·
**Dependencies:** US-STU-01, SP-15 (role)

As the super admin (`developer@jobtrigger.app`)
I want to review and decide student applications on my phone
So that students don't wait until I'm at a laptop

**Acceptance Criteria**
- [x] Scenario: only a super admin sees it — Given the signed-in account's
  role is `superAdmin`, Then Profile shows a "Student applications" row;
  for any other account the row is absent and the route sends them Home.
  The app learns the role from `GET /api/admin/students/access` (200 for a
  super admin, the plain 404 for everyone else); `role` stays out of every
  account route.
  Evidence: `JobTrigger-Frontend/test/presentation/features/admin_review/admin_entry_test.dart` (Profile row, routes); `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_notifier_test.dart` "adminAccessProvider"; `JobTrigger-Backend/test/student_manual_review.test.js` "answers a super admin with the role and everyone else with the plain 404", "keeps role off the account routes".
- [x] Scenario: the row does not depend on billing — it shows for a super
  admin whether or not billing is on for the build.
  Evidence: `JobTrigger-Frontend/test/presentation/features/admin_review/admin_entry_test.dart` "a super admin sees \"Student applications\", with billing off", "a super admin reaches the screen with billing off".
- [x] Scenario: pending list — Then pending applications of both methods are
  listed newest first, each with name (or university email), account email,
  method and submitted date.
  Evidence: `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_screen_test.dart` "shows pending applications of both methods in the order given"; `JobTrigger-Backend/test/student_manual_review.test.js` "lists pending email and document applications together, newest first".
- [x] Scenario: detail — When I open one, Then I see name, account email,
  university email, method, submitted date, status and (once decided) who
  decided it and when, the end date or the rejection reason.
  Evidence: `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_screen_test.dart` "shows every detail of an email application", "approve asks first…" (Pro until, decided by), "a decided application has no decision buttons" (reason, decided by).
- [ ] Scenario: the document — For a document application, the image is
  shown, or a PDF's pages are drawn; it is fetched with my session from
  `GET /api/admin/students/:id/document`, kept in memory only and never
  written to disk; an image leaves the in-memory image cache when the screen
  closes. A deleted document says so (410).
  Open: the image path, the 410 note, the memory-only fetch and the cache
  eviction are tested (`admin_review_screen_test.dart` "a document application
  shows the image from memory", "the image leaves the in-memory cache when the
  screen closes"; `admin_review_notifier_test.dart` "adminDocumentProvider").
  The PDF drawing (iOS PDFKit, Android `PdfRenderer` over `memfd`) compiles
  in both builds but has only run against a fake renderer in tests; it needs
  the iPhone check (SP-7M).
- [x] Scenario: approve with confirmation — When I tap "Approve" and confirm
  in a dialog, Then the application is approved and the screen shows it;
  cancelling the dialog sends nothing.
  Evidence: `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_screen_test.dart` "approve asks first; Cancel sends nothing, Approve does".
- [x] Scenario: reject with a reason and confirmation — When I tap "Reject",
  Then I must enter a reason (1–500 characters) before "Reject" is enabled,
  and confirm; the student then sees that reason.
  Evidence: `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_screen_test.dart` "reject needs a reason before it can be confirmed", "cancelling the reject dialog sends nothing"; `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_notifier_test.dart` "reject sends the trimmed reason…".
- [x] Scenario: errors — a 409 shows the backend's sentence (already decided,
  email or document used); a network failure shows `NetworkFailure`'s copy
  with "Try again"; nothing is decided twice.
  Evidence: `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_screen_test.dart` "a refused decision shows the backend's sentence and stays pending", "a failure shows the message and Try again"; `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_notifier_test.dart` "never decides twice".
- [x] Scenario: demo mode — the row never shows and no admin call is made.
  Evidence: `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_notifier_test.dart` "demo mode: never an admin"; `JobTrigger-Frontend/test/data/repositories/admin_review_repository_impl_test.dart` "demo mode is never an admin and sends nothing".

**Security & Privacy Notes** — the server checks the role on every call;
hiding the row is convenience only. The document bytes live in a notifier's
memory and go when the screen closes (images are also evicted from the
in-memory image cache). The document is never logged. Blocking screenshots
is not in scope.

**Impact** — Backend: yes (`/access`, email items in the list). App: yes
(new `admin_review` feature). Web: not needed for this story.

---

### US-STU-03 — History of student applications

**Priority:** Should · **Source:** owner decision 2026-11-22, SP-79 ·
**Dependencies:** US-STU-02

As the super admin
I want a list of every application with its dates and reviewer
So that I can see what was decided, when and by whom

**Acceptance Criteria**
- [x] Scenario: filter — `GET /api/admin/students?status=` accepts
  `pending`, `approved`, `rejected`, `expired` and `all`, both methods,
  newest first; each item has `submittedAt`, `emailVerifiedAt`,
  `reviewedAt`, `reviewedByEmail`, `approvedAt`, `expiresAt`.
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "filters history by status for both methods, with dates and the reviewer", "searches by exact account email only" (NFR-SEC-08: encrypted data allows exact-email search only).
- [x] Scenario: app — the "Student applications" screen has the filters
  Pending, Approved, Rejected, Ended and All; each row shows status,
  submitted date and, once decided, "by <reviewer>" and the decision date.
  Evidence: `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_screen_test.dart` "the filters load history with who decided it and when"; `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_notifier_test.dart` "the list loads per filter".
- [x] Scenario: website — `/admin/students` shows the same filters for both
  methods; each row shows method, status, submitted date and, once decided,
  the reviewer and decision date. The detail page shows the university
  email, method and reviewer, and offers approve/reject for a pending email
  application too.
  Evidence: `JobTrigger-Web/src/features/admin/students-view.test.tsx` "StudentsView history (US-STU-03)", "a pending email application shows the university email and the decision forms", "a decided email application has no document card and no forms"; `src/server/admin-students-api.test.ts` "parses both methods with the review fields…".
- [x] Scenario: a deleted reviewer account shows "(account deleted)".
  Evidence: `JobTrigger-Backend/test/student_manual_review.test.js` "shows a deleted reviewer as null"; web "a decided row says when and by whom"; `JobTrigger-Frontend/test/presentation/features/admin_review/admin_review_notifier_test.dart` "the decision line names the reviewer, or a deleted account".

**Impact** — Backend: yes (list fields). App: yes. Web: yes.

---

## Tests needed

| Criterion | Test |
|---|---|
| US-STU-01 backend | `JobTrigger-Backend/test/student.test.js` (confirm → pending, status none while waiting, under_review, email_used), `test/student_document.test.js` (approve/reject email, 409s), `test/plan_journey.test.js` (journey through approval) |
| US-STU-01 app/web copy | `student_verification_screen_test.dart`, `student-card.test.tsx` |
| US-STU-02 | `admin_review_repository_impl_test.dart`, `admin_review_notifier_test.dart`, `admin_review_screen_test.dart`, `profile_admin_row_test.dart`, `/access` backend test |
| US-STU-03 | backend list test, `admin_review_screen_test.dart` filters, `students-view.test.tsx`, `admin-students-api.test.ts` |
