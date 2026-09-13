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

### `scripts/migrate.js`
**Purpose:** Migrate data from old SwiftUI app JSON to MongoDB

**What it does:**
1. Loads `users.json` and `jenkins_credentials.json` from Lab-Trigger-frontend Resources
2. Creates User records in `users` collection
3. Links JenkinsCredential records to users

**When to run:**
```bash
cd lab-trigger-backend
node scripts/migrate.js
```

**Issues:**
- ⚠️ Hardcoded path to old frontend resources
- ⚠️ Only runs on demand, not automated
- ✅ Idempotent (won't duplicate existing records)

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

# 3. Migrate old data (if migrating from Lab-Trigger-frontend)
node scripts/migrate.js

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

```bash
# 1. Stop everything
./stop-dev.sh

# 2. Wipe MongoDB (Cloud: manual via Atlas UI, Docker: auto on down -v)
docker compose down -v

# 3. Start fresh
USE_DOCKER=true ./setup-dev.sh

# 4. Run migrations in order
cd lab-trigger-backend
node scripts/seedAppInfo.js    # Add app metadata
npm run dev                      # Keep running

# 5. (In new terminal) Seed test account
curl -X POST http://localhost:5001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@jobtrigger.dev","password":"password123"}'
```

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
