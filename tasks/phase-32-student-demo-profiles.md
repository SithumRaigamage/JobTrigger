# Phase 32 — Student review demo profiles (epic WEB-DEMO)

Approved 2026-11-23 for **1.1**. Sources:
`docs/user-stories/web/25-student-demo-profiles.md` (US-DEMO-01…03). This is a
dev/QA aid for the student review pages, not a product feature. No API or
schema change and no Flutter code; the app reads the same seeded rows through
the existing admin API. 1.0.0 stays frozen.

Rules for every task: document first, layered per `CLAUDE.md` §4, no new
dependency, no `.env` access, and the full suites on all three projects before
a PR (not only the tests for what changed).

- [x] P32-01 **Story and design.** US-DEMO-01…03 and this task file in place
      before code; `tasks/README.md` and `docs/user-stories/README.md` updated.
- [x] P32-02 **Backend local seed.** `scripts/seed-demo-students.js`: five
      fixed fictional users and applications (two pending, one approved, one
      rejected, one ended) covering both methods, with claims, encrypted
      document bytes and grant sources consistent with their status. Guarded
      by `scripts/localOnly.js`, idempotent, resets the five to a known state.
      The CLI never opens a `.env` file. Test: `test/demo_students.test.js`
      (contents, guard, re-run including stale grant removal).
- [x] P32-03 **Website e2e seed and demo panel.** `tests/e2e/fake-backend.mjs`
      seeds the same five, including email-method applications in the admin
      list; `src/features/admin/demo-profiles.ts` holds the typed fictional
      profiles and ideas; `students-view.tsx` shows a labelled "Demo profile"
      card on detail and a "Demo" chip in the queue. No change to
      `AdminStudent`, the API wrapper or the decision forms.
      Tests: `students-view.test.tsx`, `student.spec.ts`.
- [x] P32-04 **Full verification.** `flutter analyze` and `flutter test` in
      `JobTrigger-Frontend/`, `npm test` in `JobTrigger-Backend/`,
      `npm run check` and `npm run e2e` in `JobTrigger-Web/`, `sync-tools
      --check` and gitleaks on the diff. No existing test deleted or weakened.
      Evidence on the final tree (2026-11-23):
      - Flutter: `analyze` exit 0; `test` 1,998 passed / 29 skipped.
      - Backend: `npm test` 533 passing, including the four new demo-seed tests.
      - Website: `npm run check` clean (format, lint, typecheck, 585 unit
        tests, production build); `npm run e2e` 222 passed.
      - Hygiene: `node scripts/sync-tools.mjs --check` "all copies match";
        `git diff --check` clean; gitleaks on the staged + unstaged +
        untracked diff "no leaks found".
      - The two touched test files only gain new demo blocks; the seed script,
        seed test and profile map are new files. No existing test was deleted
        or weakened.
- [ ] P32-05 **MANUAL (owner).** With the documented development environment
      exported in the shell (the script does not open `.env`), run
      `node JobTrigger-Backend/scripts/seed-demo-students.js --allow-remote`
      on the Mac. Open `http://192.168.1.53:3000/admin/students` as
      `developer@jobtrigger.app`, open a seeded pending application, approve
      it, reject another, and open the app on the iPhone to see the seeded
      rows. Only this step needs a device; report anything unverified.

## Done when
- All four automated tasks ticked with named evidence, P32-05 reported as
  MANUAL, and the three full suites green on the merged result.
