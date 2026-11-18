# Database Migrations & Schema Management

## 📊 Current MongoDB Collections

### Managed Collections (Defined in Models)

| Collection | Model | Purpose | Documents |
|-----------|-------|---------|-----------|
| `users` | `User.js` | User accounts | Email, hashed password |
| `jenkinscredentials` | `JenkinsCredential.js` | Jenkins server credentials | Per-user Jenkins server auth |
| `githubcredentials` | `GitHubCredential.js` | GitHub Actions connections | Per-user repositories and encrypted token |
| `sonarqubecredentials` | `SonarQubeCredential.js` | SonarQube connections | Per-user server and encrypted token |
| `appinfos` | `AppInfo.js` | App metadata | Version, URLs, build number |
| `subscriptions` | `Subscription.js` | Billing entitlement state | Per-user subscription status |
| `billingevents` | `BillingEvent.js` | Billing webhook idempotency | Provider event ids with TTL |
| `supporttickets` | `SupportTicket.js` | User support requests | Redacted report and triage state |
| `devicetokens` | `DeviceToken.js` | Push registration | Per-user platform and token |
| `studentclaims` | `StudentClaim.js` | Student-plan claims | Per-user verification claim |
| `studentverifications` | `StudentVerification.js` | Student verification | Verification status and expiry |
| `passwordresettokens` | `PasswordResetToken.js` | Password reset | Hashed, single-use reset tokens |

Mongoose derives collection names from model names (lowercase plural) unless a
schema explicitly overrides them. `credentialTargets.js` is a schema helper,
not a persisted model/collection.

### Indexes & Constraints

```
users:
  - _id (primary)
  - email (unique)

jenkinscredentials:
  - _id (primary)
  - userId (foreign key → users)
  - jenkinsURL + userId (relationship)

appinfos:
  - _id (primary)
  - timestamps (auto-added)

subscriptions:
  - userId (unique)

billingevents:
  - eventId (unique)
  - expiresAt (TTL)

passwordresettokens:
  - tokenHash (unique)
  - expiresAt (TTL)

devicetokens:
  - token (unique)
  - userId + platform
```

---

## 🔧 Migration Scripts

### `docs/archive/migrate.js` (archived)

The one-shot import of the legacy SwiftUI app's `users.json` and
`jenkins_credentials.json` into MongoDB. It was a developer-machine script:
the source path was hardcoded to one author's checkout, and the source JSON
held plaintext passwords.

It is **archived, not runnable**. There is no npm script and no CI job for
it; it is kept only so the original migration can be reconstructed if a
legacy export ever needs importing again. See `docs/archive/README.md` for
what it would need before it could run (a configurable source path, a
password-hashing step, and a re-encryption pass against the current
`CREDENTIALS_ENCRYPTION_KEY`).

### `scripts/encrypt-credentials.js` (AUD-03)

Encrypts tool secrets (Jenkins `password` and `paramToken`, GitHub and
SonarQube `token`) that were stored before encryption at rest, and
re-encrypts ones written with an older key after a rotation. It's
idempotent, so re-running it is safe.

```bash
cd JobTrigger-Backend
npm run encrypt-credentials -- --dry-run   # how many rows would change
npm run encrypt-credentials                # encrypt them
```

Run it once per environment after deploying the encryption release, with
the same `CREDENTIALS_ENCRYPTION_*` settings as the server. Until it runs,
the server still reads the old plaintext rows, so there's no downtime
window. Back up the three credential collections first: rows encrypted
with a key you then lose can't be recovered.

### `scripts/seedAppInfo.js`
**Purpose:** Seed AppInfo collection with metadata

**When to run:**
```bash
node scripts/seedAppInfo.js
```

---

## 🧹 Test data

The automated backend suite uses an isolated in-memory MongoDB. It does not
create collections in Atlas. For development data, use the dev-only seed and
reset procedures below; never run a broad database drop against production.

---

## 🚀 Proper Migration Workflow

### Step 1: Define Schema (Models)

✅ Already done:
- `User.js` — user accounts
- `JenkinsCredential.js` — Jenkins credentials
- `AppInfo.js` — app metadata

### Step 2: Start and seed the development database

```bash
./setup-dev.sh
```

The script uses the Atlas dev cluster, creates indexes through the models,
and safely seeds AppInfo, a development account, and sample Jenkins
credentials. See [Development Setup](./dev-setup.md) and
[MongoDB Atlas Setup](./mongodb-cloud-setup.md). Legacy SwiftUI imports are
archived and are not part of this workflow.

### Step 3: Reset development data

Use the Atlas dev-cluster reset steps in [Full Data Reset](#-full-data-reset-development-only).
There is no local MongoDB container or `docker compose down -v` reset.

---

## 📝 Schema Evolution (Future)

If you need to add fields to a collection:

### Before Deployment

1. **Update Model** (e.g., `User.js`):
```javascript
const userSchema = new mongoose.Schema({
  email: String,
  password: String,
  newField: { type: String, default: null }  // ← NEW FIELD
});
```

2. **Create Migration Script** (`scripts/add-newfield.js`):
```javascript
const User = require('../models/User');

async function addNewField() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    // Add default value to all existing docs
    await User.updateMany({}, { newField: 'default_value' });
    
    console.log('✅ Migration complete');
    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  }
}
```

3. **Run Migration**:
```bash
node scripts/add-newfield.js
```

4. **Deploy Code**:
- Push updated model to backend

---

## 🔄 Full Data Reset (Development Only)

The database is the Atlas **dev** cluster (Phase 17); there is no local
MongoDB to throw away. Never do this on production.

1. Stop the backend (`Ctrl+C` in its terminal).
2. In Atlas: **Database → Browse Collections** on the `jobtrigger-dev`
   cluster → hover the `jobtrigger` database → **Drop database** → type its
   name to confirm.
3. Reseed and start again:

   ```bash
   ./setup-dev.sh   # dev account, sample Jenkins servers, app info
   ```

Saved Jenkins/GitHub/SonarQube secrets are gone after a reset; anything you
add again is encrypted with the current `CREDENTIALS_ENCRYPTION_KEY`.

---

## ✅ Migration Checklist

Before deploying new schema changes:

- [ ] Update model(s) in `models/`
- [ ] Create migration script in `scripts/`
- [ ] Test migration locally: `node scripts/your-migration.js`
- [ ] Verify data integrity
- [ ] Document breaking changes
- [ ] Test with old data (if applicable)
- [ ] Run against staging MongoDB first
- [ ] Only then deploy to production

---

## 📚 MongoDB Best Practices

| Do | Don't |
|----|-------|
| Use Mongoose models | Raw mongo commands in code |
| Create indexes via schema | Manual index creation |
| Version migrations | Hide migration history |
| Test against real data | Only test with fresh DB |
| Document schema changes | Change schema without tracking |

---

## 🆘 Troubleshooting

**"Duplicate key error"**
- Means a unique index exists and you're inserting duplicates
- Solution: Check existing data before inserting

**"No collections found"**
- MongoDB hasn't created any yet
- Solution: Run backend (`npm run dev`) to create indexes, then insert data

**"Collection stuck in migration"**
- A migration script crashed mid-way
- Solution: Manually fix the data or re-run migration

---

## 📖 Related Docs

- [Dev Setup](./dev-setup.md) — How to run backend
- [API Reference](./api-reference.md) — Endpoints that interact with DB
- [Architecture](./architecture.md) — Data flow diagram
