# Database Migrations & Schema Management

## 📊 Current MongoDB Collections

### Managed Collections (Defined in Models)

| Collection | Model | Purpose | Documents |
|-----------|-------|---------|-----------|
| `users` | `User.js` | User accounts | Email, hashed password |
| `jenkinscredentials` | `JenkinsCredential.js` | Jenkins server credentials | Per-user Jenkins server auth |
| `appinfos` | `AppInfo.js` | App metadata | Version, URLs, build number |

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

## 🧹 Handling the "test" Table

The "test" collection appears to be created by:
1. **Signup endpoint** creating a test account (`test@jobtrigger.dev`)
2. **In-memory MongoDB** used by test suite

### Clean Up "test" Collection

```bash
# Option 1: Drop from MongoDB Cloud console
# Go to Atlas > Collections > Select "test" > Drop

# Option 2: Drop via MongoDB CLI
mongo --eval "db.tests.drop()"

# Option 3: Drop all test data
mongo --eval "db.dropDatabase()"
```

---

## 🚀 Proper Migration Workflow

### Step 1: Define Schema (Models)

✅ Already done:
- `User.js` — user accounts
- `JenkinsCredential.js` — Jenkins credentials
- `AppInfo.js` — app metadata

### Step 2: Run Migrations in Order

```bash
# 1. Start backend (creates indexes)
npm run dev

# 2. In new terminal: seed app info
node scripts/seedAppInfo.js

# 3. Migrate old data (if migrating from Lab-Trigger-frontend) — see archive
#    script docs/archive/migrate.js for reconstruction steps; not runnable
#    today.

# 4. Verify
curl http://localhost:5001/api/appinfo
curl http://localhost:5001/api/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@jobtrigger.dev","password":"password123"}'
```

### Step 3: Clean Up Old Test Data

```bash
# Delete "test" collection
db.tests.deleteMany({})

# Or drop entire database (for fresh start)
docker compose down -v
```

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
