# M-14 — Production backend deploy and keys

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** P20-05 (`tasks/phase-20-subscriptions.md`), PE-30, PE-31
(`tasks/phase-emergency.md`).
**Why only you:** production cloud, the secret manager, the production Atlas
cluster and the encryption keys are yours; release builds also refuse an
`http://` backend, so this unlocks TestFlight and the portal.

1. Deploy the backend at a public `https://` URL with a production Atlas
   cluster (`docs/deployment.md`).
2. Put the production encryption key in the host's secret manager (not a
   file), keep a second key id ready for rotation, and record the rotation
   steps in `docs/deployment.md`.
3. Back up, then run `node scripts/encrypt-credentials.js --dry-run` and then
   without `--dry-run`; confirm the startup audit reports no unreadable key
   ids.

**Evidence:** the live `/healthz` over `https://`.
