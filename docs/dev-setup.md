# Development Setup Guide

## 🚀 Quick Start Scripts

### `setup-dev.sh` — Start Development Environment

The database is **MongoDB Atlas** (Phase 17); there is no local MongoDB.
Set up the dev cluster once with [MongoDB Atlas Setup](./mongodb-cloud-setup.md).

**What it does:**
- ✅ Checks `JobTrigger-Backend/.env` has an Atlas `MONGODB_URI` (it never
  prints it: the string holds the database password)
- ✅ Seeds the Atlas dev database with
  `JobTrigger-Backend/scripts/setup-migrations.js`: AppInfo, a dev user
  (`developer@jobtrigger.app` / `SecurePassword123!`) and sample Jenkins
  credentials (see [Database Migrations](./database-migrations.md)). Safe to
  repeat: an existing user or server is kept.
  - That password is published here, so the seed refuses
    `NODE_ENV=production` and any URI that names production — `prod` in its
    user, cluster, database or `appName` (AUD-58, P17-04). Seed only your dev
    cluster.
  - `SEED_REMOTE=false ./setup-dev.sh` skips seeding.
- ✅ Starts the Node.js backend on `http://127.0.0.1:5001` in watch mode
  (restarts on file changes); `Ctrl+C` stops it

**Run it:**
```bash
./setup-dev.sh
```

**What you'll see** (shortened):
```
🚀 JobTrigger Development Setup
ℹ️  Database: MongoDB Atlas (docs/mongodb-cloud-setup.md)
▶ STEP: Checking the Atlas connection string
✅ MONGODB_URI found in JobTrigger-Backend/.env
▶ STEP: Seeding the Atlas dev database
✅ Development user created: developer@jobtrigger.app
✅ Seeding completed
🚀 Starting Backend (Node.js)
{"level":"info","time":"…","msg":"server.mongo_connected"}
{"level":"info","time":"…","msg":"server.listening","port":5001}
```

---

## 🔄 Full Workflow

### Terminal 1: Backend + Database

```bash
# Seed the Atlas dev database and start the backend
./setup-dev.sh

# Keep this running
# Backend listens on http://127.0.0.1:5001
```

### Terminal 2: Flutter App

```bash
cd JobTrigger-Frontend

# Run on iOS simulator — quote device names that contain spaces
flutter run --dart-define-from-file=config/dev.json -d "iPhone Air"

# Or choose interactively
flutter run
```

### Terminal 2b: Website (Optional)

The Next.js site in `JobTrigger-Web/` (Phase 15). Node 24; see its
[README](../JobTrigger-Web/README.md) for environment variables.

```bash
cd JobTrigger-Web
npm install          # first time
npm run dev          # http://localhost:3000 — backend stays on :5001
npm run check        # before committing: format, lint, types, tests, build
```

### Terminal 3: Seed Data / Testing (Optional)

```bash
# Seed a new test account
curl -X POST http://localhost:5001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"custom@test.dev","password":"password123"}'

# Check backend health
curl http://localhost:5001/api/appinfo
```

---

## 📱 Running on a Physical iPhone

Install over USB with Xcode automatic signing — no TestFlight needed.

### 1. Point the app at your Mac, not `127.0.0.1`

`config/dev.json` uses `http://127.0.0.1:5001`, which on a phone means the
phone itself. Find your Mac's Wi‑Fi IP and create a machine-local config
(don't commit it — the IP is specific to your network):

```bash
ipconfig getifaddr en0   # e.g. 192.168.1.24
```

```json
// JobTrigger-Frontend/config/device.json
{
  "ENVIRONMENT": "dev",
  "BACKEND_BASE_URL": "http://<your-mac-ip>:5001"
}
```

Phone and Mac must be on the same Wi‑Fi. The backend's `app.listen(PORT)`
already binds all interfaces, so no backend change is needed. If login
stops working later, your Mac's IP probably changed — re-check it.

### 2. Prepare the iPhone (once)

- Connect by cable and tap **Trust This Computer**.
- Enable **Settings → Privacy & Security → Developer Mode** (iOS 16+; the
  phone restarts).

### 3. Check signing in Xcode (once)

```bash
open JobTrigger-Frontend/ios/Runner.xcworkspace
```

- **Xcode → Settings → Accounts**: sign in with the Apple ID for team
  `QRCA2Z2HYQ`.
- **Signing & Capabilities**: both **Runner** and **PinnedJobsWidget**
  targets should show that team with no errors.
- A free (personal) Apple ID likely can't sign the **App Groups**
  capability (`group.Sraig.Lab-Trigger-frontend`, used by the home-screen
  widget). Use the paid team, or temporarily drop the widget target/App
  Group to test the rest of the app.

### 4. Run it

Start the backend (Terminal 1 above), then:

```bash
cd JobTrigger-Frontend
flutter devices   # the iPhone should be listed

# Debug — hot reload, needs the Mac attached
flutter run --dart-define-from-file=config/device.json -d "<iPhone name>"

# Profile — keeps working from the home screen after unplugging
flutter run --profile --dart-define-from-file=config/device.json -d "<iPhone name>"
```

Recent iOS versions won't open a debug build from the home screen once it's
detached from the Mac, so use `--profile` for standalone testing.

**Don't use `--release` here:** `AppConfig.fromEnvironment` (AUD-43)
deliberately throws at launch unless the build names a non-dev environment
and an `https://` backend. A LAN `http` backend only works in debug/profile.

### 5. First launch on the phone

- **"Untrusted Developer"**: Settings → General → VPN & Device Management →
  your developer profile → **Trust**.
- **Local network prompt**: tap **Allow**, or the app can't reach your Mac's
  backend or a LAN Jenkins server.

Plain `http` works without ATS exceptions in `Info.plist` because `dio`
uses `dart:io` sockets, which ATS doesn't apply to.

### Beyond local testing

Once the backend is deployed on `https`, update `config/prod.json` and go
through TestFlight (`flutter build ipa --release --dart-define-from-file=config/prod.json`)
— see [deployment.md](deployment.md).

---

## 📋 Environment Variables

**`JobTrigger-Backend/.env`** controls backend behavior:

```env
# MongoDB Atlas dev cluster (docs/mongodb-cloud-setup.md)
MONGODB_URI=mongodb+srv://USER:PASSWORD@CLUSTER.mongodb.net/jobtrigger

# Server port
PORT=5001

# JWT secret for auth tokens
JWT_SECRET=supersecretjwtkey_123456

# Required (AUD-03): encrypts stored Jenkins/GitHub/SonarQube secrets.
# Base64 of 32 random bytes; generate with:
#   node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
# Keep it stable: rows encrypted with it can't be read without it.
CREDENTIALS_ENCRYPTION_KEY=<generated value>

# Optional: browser origins allowed by CORS, comma-separated. Leave unset
# for the mobile app, which sends no Origin and needs no CORS.
# CORS_ORIGINS=https://admin.example.com

# Optional (AUD-05): failed logins per IP per 15 min (default 10), and
# signups per IP per hour (default 5). Behind a reverse proxy or load
# balancer, TRUST_PROXY is the number of proxy hops (e.g. 1), so limits
# apply to the client's IP rather than the proxy's. Only a whole number
# (1-99) is accepted; anything else stops the server at startup (AUD-44).
# LOGIN_RATE_LIMIT=10
# Failed logins per account per 15 min, from any address (AUD-55).
# LOGIN_EMAIL_RATE_LIMIT=10
# SIGNUP_RATE_LIMIT=5
# TRUST_PROXY=1
```

`JWT_SECRET`, `MONGODB_URI`, and `CREDENTIALS_ENCRYPTION_KEY` are
required: without any of them, the server
prints `Missing required configuration: …` and exits instead of starting
(AUD-25).

> ⚠️ Never commit `.env` to git — credentials stay private

---

## 🛑 Stopping Services

Press `Ctrl+C` in the backend terminal. The Atlas cluster keeps running in
the cloud; there is nothing local to stop. Start again with
`./setup-dev.sh`.

---

## ✅ Verify Everything Works

1. **Backend running:**
   ```bash
   curl http://localhost:5001/api/appinfo
   ```
   Should return app info JSON ✅

2. **Database seeded:**
   ```bash
   curl -X POST http://localhost:5001/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"developer@jobtrigger.app","password":"SecurePassword123!"}'
   ```
   Should return user + token ✅

3. **App running:**
   - See login screen on iOS simulator ✅
   - "Remember me" checkbox visible ✅
   - Can login with the dev credentials above ✅

---

## 🆘 Troubleshooting

**"Could not connect to MongoDB"** (`server.mongo_connect_failed`)
- The log line's `hint` says what to check: the Atlas database user, the IP
  allow list, DNS, or a paused cluster
- Full table: [MongoDB Atlas Setup](./mongodb-cloud-setup.md#7-troubleshooting)

**"Server won't start"**
- Check port 5001 is free: `lsof -i :5001`
- Kill any existing process: `kill -9 <PID>`
- Try again: `./setup-dev.sh`

**"Seeding refused"**
- `names production`: the URI has `prod` in its user, cluster, database or
  `appName`. Point `MONGODB_URI` at the dev cluster
- `NODE_ENV=production` is set in your shell: unset it

**"Flutter app won't connect to backend"**
- Ensure backend URL in `JobTrigger-Frontend/config/dev.json` is `http://127.0.0.1:5001`
- Backend must be running
- Check phone/simulator can reach localhost

---

## 📚 Related Docs

- [MongoDB Cloud Setup](./mongodb-cloud-setup.md) — Detailed Atlas configuration
- [API Reference](./api-reference.md) — Backend + Jenkins endpoints
- [Architecture](./architecture.md) — System design
