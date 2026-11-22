# Phase 29 — Personal data encrypted at rest (NFR-SEC-08)

Source: owner request 2026-11-22 ("make the security of the database tight:
secrets, tokens and personal information"); owner decision the same day:
option A, encrypt emails too and accept exact-email admin search. Story and
criteria: `docs/user-stories/shared/09-non-functional-security.md`
NFR-SEC-08; design: `docs/design/NFR-SEC-08-pii-at-rest.md`. Branch:
`feat/pii-encryption-at-rest`. Backend and website only; the app needs no
change (same JSON).

- [x] P29-01 Story NFR-SEC-08 (AC1–AC11) and design note.
- [x] P29-02 Backend: `encryptedFields` plugin for personal data (lookup
      hash, query rewrite, `.lean()`/`populate` decryption, plaintext length
      checks, subdocument arrays); `security/blindIndex.js`; models (User,
      StudentVerification, SupportTicket, Team invites, Jenkins URL/username,
      SonarQube URL); admin search exact-email; keyed student claims; bcrypt
      cost 12 with re-hash on login; HS256 pinned; startup audit over every
      encrypted field plus `pii.migration_pending`.
- [x] P29-03 Backend: `npm run encrypt-credentials` backs up (encrypted),
      backfills, converts claims, drops `email_1`; `--dry-run`, `--restore`.
- [x] P29-04 Website: admin search boxes say "Exact account email".
- [x] P29-05 Tests written: `test/pii_at_rest.test.js`,
      `test/password_hardening.test.js`, backfill cases in
      `test/encryption.test.js`; the name-search test changed on purpose.
- [x] P29-06 Full suites on the Mac, 2026-11-22: backend `npm test` 480
      passing, website `npx vitest run` 516 passing. Story criteria
      AC1–AC11 ticked.
- [x] P29-07 Backfill on the Atlas dev cluster, 2026-11-22: dry run 7
      documents (Jenkins 3, SonarQube 1, User 3), real run 7 with an
      encrypted backup in `JobTrigger-Backend/backups/`, re-run 0, old
      `email_1` index dropped.
- [ ] P29-08 Production: the same `npm run encrypt-credentials` run as part
      of the first production deploy (`docs/deployment.md`). A real iPhone
      sign-in against the migrated dev data is not verified yet.

## Evidence (2026-11-22)

Checked without a database: models encrypt on assignment and decrypt on
read and in JSON (emails normalized; hash fields never in JSON); filters on
`email` become `emailHash` (plain, `$eq`, `$in`, inside `$or`); `$regex` and
queries on hash-less encrypted fields throw; updates keep the hash in step;
lean results are decrypted and an unreadable value reads as null; the
support subject length limit still applies; every changed file passes
`node --check`, and the server and migration script load.
