# Archive

Historical material kept for reference only. **Nothing here is run, imported,
or deployed.** No CI job, npm script, or seed process references these files.

## `migrate.js`

The original one-shot import of the legacy SwiftUI app's `users.json` and
`jenkins_credentials.json` into MongoDB. It was a developer-machine script:
the source path was hardcoded to one author's checkout, and the source JSON
held plaintext passwords.

Moved here on 2026-10-22 (NEW-02) because it was dead code that still carried
a hardcoded absolute path and a plaintext-credential import path. It is kept
only so the original migration can be reconstructed if a legacy export ever
needs importing again.

The `npm run migrate` script that pointed at it was removed in the same
change, and `docs/database-migrations.md` now describes it as archived
rather than runnable.

Before running it anywhere, it would need: a configurable source path, a
documented step for hashing the imported passwords, and a re-encryption pass
so the stored credentials use the current `CREDENTIALS_ENCRYPTION_KEY`
(see `JobTrigger-Backend/security/secretCipher.js`).
