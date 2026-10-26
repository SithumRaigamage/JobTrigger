# Phase 17 — Cloud database (MongoDB Atlas)

Goal: run every environment on MongoDB Atlas and retire the local MongoDB
(the `docker-compose.yml` service and the `USE_DOCKER=true` paths). The
backend code keeps Mongoose: only `MONGODB_URI` points somewhere else.

Requested by the owner on 2026-10-26 ("lets use the cloud mongodb for
everything"), plan approved the same day ("go"), on branch
`feat/atlas-database` from `develop`.

**Workflow.** Each task: plan → owner approval → implement → local gate
(`npm test` in `JobTrigger-Backend/`; shell scripts run against the real
target where it is safe) → owner review → one commit, `[P17-0N] …`.
`.env` files are never opened by the agent (`CLAUDE.md` §8); the owner
pastes connection strings.

## Decisions approved with the phase (2026-10-26)

1. **MongoDB Atlas, not Neon.** Neon is PostgreSQL: moving there means
   rewriting the models, controllers and the `encryptedFields` plugin, and
   changing the `_id` contract the app and the website parse. Atlas needs
   no code change (`CLAUDE.md` §7: no backend rewrite without a task).
2. **No local MongoDB from now on.** The Docker service and every
   `USE_DOCKER` path go (P17-04); `setup-dev.sh` only talks to Atlas.
   This replaces the earlier "keep Docker as an offline fallback" answer.
3. **Dev now, prod later.** A free M0 cluster for development today.
   Production waits for the backend host decision, because its region and
   network rule depend on it (P17-05 documents the checklist).
4. **No data to move (revised 2026-10-26).** The owner first chose to copy
   the local data once. A read-only search then found no JobTrigger data on
   the development Mac: no `jobtrigger-mongo` container or volume, no
   `jobtrigger` database in the other project's MongoDB, and the 13 unnamed
   MongoDB volumes all empty (3 system collections each). The owner
   confirmed there was nothing to keep, so Atlas starts fresh and P17-02 is
   dropped.
5. **Tests stay on the in-memory MongoDB** (`mongodb-memory-server`): it
   exists only inside `npm test`, never touches Atlas, and the suite's
   cleanup drops databases.
6. **Seed Atlas dev, keep the AUD-58 guard.** `setup-dev.sh` seeds the dev
   account with `--allow-remote`, refused for a URI that looks like
   production and under `NODE_ENV=production` (P17-04).

## Tasks

- [x] P17-00 Docs: this file and the Phase 17 row in `tasks/README.md`.
- [x] P17-01 `docs/mongodb-cloud-setup.md` rewritten as the Atlas dev
      setup: M0 cluster, a database user limited to `jobtrigger`, the
      network rule, the connection string. Fixes the stale test account
      and the missing `CREDENTIALS_ENCRYPTION_KEY` in the example.
      **Owner action:** create the Atlas project and paste `MONGODB_URI`.
- [-] P17-02 ~~One-time copy of the local data into Atlas.~~ Dropped: there
      was no local JobTrigger data to copy (decision 4).
- [ ] P17-03 Backend: fast `serverSelectionTimeoutMS` and a clear startup
      message when Atlas is unreachable (IP not allowed, bad credentials,
      paused cluster), with tests.
- [ ] P17-04 Remove the local MongoDB: the compose service, `USE_DOCKER`
      in `setup-dev.sh` / `stop-dev.sh`, and every doc
      that describes a local database; the seed guard change of decision 6.
- [ ] P17-05 `docs/deployment.md` "Database": the production checklist
      (paid tier with backups, region, network rule, secret handling,
      restore drill, leaked-password steps).

## Out of scope

- Moving to PostgreSQL / Neon (decision 1).
- Creating the production cluster (decision 3).
- Running the backend tests against Atlas (decision 5).
