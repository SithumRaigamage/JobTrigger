# Epic: WEB-DEMO — Student review demo profiles

Five clearly-labelled fictional student applications for the local development
and e2e environments, so the super admin's review queue is populated and the
approval journey can be shown and tested without hand-creating accounts.
Built in Phase 32 (`tasks/phase-32-student-demo-profiles.md`) as a dev/QA aid
for release 1.1. The real student flow and its rules are unchanged; see
[`../billing/23-student-plan.md`](../billing/23-student-plan.md).

**Owner decisions, 2026-11-23:** website-only per-profile "development ideas"
panel; the five applications live both in the local database (seeded by a
guarded backend script) and in the website's e2e fake backend. No API, schema
or Flutter change; the app already reads the same admin list and is not
modified for this story.

---

### US-DEMO-01 — Five realistic applications in the local review queue

**Priority:** Must · **Source:** owner request 2026-11-23 ("real like data",
about five people) · **Dependencies:** Phase 21 SP-7

As the super admin reviewing student applications locally
I want five realistic, clearly-fictional applications in the queue
So that I can see and try every review state without preparing data by hand

**Acceptance Criteria**
- [x] Scenario: five fixed personas — a backend local-only script seeds
  Nimali Silva (university email verified, pending), Kasun Perera (student ID
  document, pending), Anushka Fernando (email, approved), Tharindu
  Wickramasinghe (document, rejected with a reason) and Maya Chandrasekaran
  (email, ended). Every account email starts with `demo-`; every other
  personal field is fictional. Each has a course, year of study and university
  in the website's demo profile data.
  Test: `JobTrigger-Backend/test/demo_students.test.js` seed contents,
  idempotency and state reset.
- [x] Scenario: the seed is safe — it refuses `NODE_ENV=production`, a
  database whose URI names production, and a non-local database without
  `--allow-remote`, using the existing `scripts/localOnly.js` guard. Re-running
  it restores the five records to their starting state, including their email
  claims and grant sources. It never reads a `.env` file itself.
  Test: `JobTrigger-Backend/test/demo_students.test.js` guard and re-run.
- [x] Scenario: the website queue shows them — `/admin/students` lists the
  five under the correct Pending / Approved / Rejected / Ended filters and
  under All, and the exact-email search finds each one. The same five are
  seeded in `tests/e2e/fake-backend.mjs`, including email-method applications
  (which that fake backend previously never listed).
  Tests: `JobTrigger-Web/src/features/admin/students-view.test.tsx`,
  `JobTrigger-Web/tests/e2e/student.spec.ts`.

**Security & Privacy Notes** — the personas are fictional and the script is
local-only; no real personal data is added. The five `demo-*` accounts are dev
credentials, not production accounts. The website's profile map contains only
fictional text.

**Impact** — Backend: yes (dev seed script + test, no API/schema change).
Web: yes (e2e seed, demo profile panel, tests). App: not needed — seeded rows
appear automatically through the existing admin API; no code change.

---

### US-DEMO-02 — Profile-wise development ideas on the website

**Priority:** Must · **Source:** owner question 2026-11-23 ("profile wise what
are some developments can we do") · **Dependencies:** US-DEMO-01

As the super admin looking at one demo application
I want to see that person's study profile and a few concrete ideas for what we
could develop for that kind of student
So that I can judge which follow-up features are worth building

**Acceptance Criteria**
- [x] Scenario: the detail page shows a "Demo profile" card for a seeded
  account, with the fictional name, course, year of study, university and
  2–3 profile-specific ideas. It is labelled as demo data and is not shown for
  any other account. The ideas are suggestions only; none is implemented or
  implied to be shipped.
  Tests: `JobTrigger-Web/src/features/admin/students-view.test.tsx` (card for a
  demo email, absent for a normal one), `tests/e2e/student.spec.ts` (the card
  on a seeded application).
- [x] Scenario: no contract change — the ideas come from a static, typed map
  in `src/features/admin/demo-profiles.ts` keyed by account email; nothing is
  added to `AdminStudent`, the backend API, the database or the app. The
  existing detail fields, document viewer and decision forms render exactly
  as before.
  Tests: `npm run check`, existing `students-view.test.tsx` and
  `admin-students-api.test.ts` unchanged in behaviour.

**Security & Privacy Notes** — the map ships in the website bundle but holds
only fictional text and fixed demo keys; no personal data, secrets or
credentials.

**Impact** — Backend: not needed. Web: yes. App: not needed.

---

### US-DEMO-03 — Decisions still work end to end

**Priority:** Must · **Source:** owner requirement 2026-11-23 ·
**Dependencies:** US-DEMO-01, US-STU-01…03

As the super admin
I want to approve or reject a seeded application for real
So that the demo data proves the review flow, not just a static page

**Acceptance Criteria**
- [x] Scenario: approving a seeded pending application — website
  Server Action → backend admin route → 365-day grant and a claim for that
  university email or document; the row moves to Approved with reviewer and
  dates. The seeded approved/expired records already hold consistent claims
  and grant sources, so they do not block other approvals.
  Tests: `JobTrigger-Backend/test/demo_students.test.js` (consistency),
  `JobTrigger-Web/tests/e2e/student.spec.ts` (approve a seeded pending demo).
- [x] Scenario: rejecting a seeded pending application needs a reason, stores
  it and moves the row to Rejected; the forms are absent for decided rows.
  Test: `JobTrigger-Web/tests/e2e/student.spec.ts` (reject a seeded pending
  demo).
- [x] Scenario: the full suites stay green — Flutter `analyze`/`test`,
  backend `npm test`, website `npm run check` and `npm run e2e`. No existing
  test is deleted or weakened.
  Evidence: recorded in `tasks/phase-32-student-demo-profiles.md` when run.

**Security & Privacy Notes** — approval/rejection permission stays with the
same super-admin routes and session checks; the seed adds no new privileged
endpoint.

**Impact** — Backend: yes (seed consistency). Web: yes (e2e). App: not needed.

---

## Design note

- **Data flow:** no new route. The website reads the five through the existing
  `listStudents` / `getStudentApplication` calls and decides through the
  existing Server Actions; the app sees the same rows through the same backend.
- **Website rendering:** `StudentsView` and `StudentDetailView` remain Server
  Components; the only client component is the unchanged `ReviewForms`. A pure
  `demo-profiles.ts` helper maps a fixed `demo-*` account email to fictional
  profile text and ideas. A small "Demo" chip marks such rows in the queue.
- **Seed script:** `JobTrigger-Backend/scripts/seed-demo-students.js` follows
  `ensure-test-accounts.js` for the guard and lifecycle, but deliberately does
  not call `dotenv.config()`: the documented development environment is
  exported by the shell, so the script never opens a `.env` file. It calls
  `requireLocalDatabase`, `connectDatabase`, upserts by fixed account email and
  disconnects. Document bytes use the existing encrypted field path; grant
  sources use the existing `lib/student.js` helper with explicit dates so the
  expired persona is really expired.
- **Release:** dev/QA only. 1.0.0 stays frozen; this work is on the 1.1 line.

## Tests needed

| Criterion | Test |
|---|---|
| US-DEMO-01 | backend seed test; website view test; e2e five-row/filter test |
| US-DEMO-02 | website view test for the demo card and its absence |
| US-DEMO-03 | backend seed consistency; e2e approve + reject; all three full suites |
