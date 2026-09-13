# Development Setup Guide

## 🚀 Quick Start Scripts

### `setup-dev.sh` — Start Development Environment

**What it does:**
- ✅ Checks MongoDB connection (Cloud or Docker)
- ✅ Seeds test account (`test@jobtrigger.dev` / `password123`)
- ✅ Starts Node.js backend on `http://127.0.0.1:5001`
- ✅ Keeps backend running in watch mode (auto-restart on file changes)

**Run it:**
```bash
./setup-dev.sh
```

**With Docker (local MongoDB):**
```bash
USE_DOCKER=true ./setup-dev.sh
```

**What you'll see:**
```
🚀 JobTrigger Development Setup
================================
☁️  Using MongoDB Cloud (Atlas)
✅ MongoDB Cloud connection string found in .env
🌱 Seeding test account...
✅ Test account ready (test@jobtrigger.dev / password123)
🎉 All set! Starting backend...
================================
[dotenv] injecting env (3) from .env
Server running on http://127.0.0.1:5001
Connected to MongoDB
```

---

### `stop-dev.sh` — Stop Development Environment

**What it does:**
- ✅ Stops MongoDB Docker container (if using Docker)
- ✅ Tells you to stop backend manually (`Ctrl+C`)
- ✅ Shows you data persistence options

**Run it:**
```bash
./stop-dev.sh
```

**What you'll see:**
```
🛑 Stopping JobTrigger Development Services
=========================================
☁️  Using MongoDB Cloud (Atlas) — no container to stop
ℹ️  Backend (npm run dev) must be stopped manually
Press Ctrl+C in the backend terminal to stop it

🎉 Done!
```

---

## 🔄 Full Workflow

### Terminal 1: Backend + Database

```bash
# Start everything (MongoDB Cloud)
./setup-dev.sh

# Or with local Docker MongoDB
USE_DOCKER=true ./setup-dev.sh

# Keep this running
# Backend listens on http://127.0.0.1:5001
```

### Terminal 2: Flutter App

```bash
cd job_trigger

# Run on iOS simulator
flutter run -d "iPhone Air"

# Or choose interactively
flutter run
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

## 📋 Environment Variables

**`JobTrigger-Backend/.env`** controls backend behavior:

```env
# MongoDB connection (MongoDB Cloud)
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/jobtrigger

# Or local Docker MongoDB
# MONGODB_URI=mongodb://localhost:27017/jobtrigger

# Server port
PORT=5001

# JWT secret for auth tokens
JWT_SECRET=supersecretjwtkey_123456
```

> ⚠️ Never commit `.env` to git — credentials stay private

---

## 🛑 Stopping Services

**To stop:**

```bash
# In the backend terminal
Ctrl+C

# Then run
./stop-dev.sh
```

**To restart:**
```bash
./setup-dev.sh
```

---

## 🐳 Docker vs MongoDB Cloud

| Feature | Docker | MongoDB Cloud |
|---------|--------|---|
| Setup | `USE_DOCKER=true ./setup-dev.sh` | Add connection string to `.env` |
| Internet needed | No | Yes |
| Data persistence | Only if volume configured | Yes (always) |
| Best for | Offline dev | Team collaboration |

**Switch between them:**
```bash
# Use Docker
USE_DOCKER=true ./setup-dev.sh

# Use Cloud (default)
./setup-dev.sh
```

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
     -d '{"email":"test@jobtrigger.dev","password":"password123"}'
   ```
   Should return user + token ✅

3. **App running:**
   - See login screen on iOS simulator ✅
   - "Remember me" checkbox visible ✅
   - Can login with test credentials ✅

---

## 🆘 Troubleshooting

**"Could not connect to MongoDB"**
- Verify `MONGODB_URI` in `.env`
- For MongoDB Cloud: check IP allowlist
- For Docker: run `USE_DOCKER=true ./setup-dev.sh`

**"Server won't start"**
- Check port 5001 is free: `lsof -i :5001`
- Kill any existing process: `kill -9 <PID>`
- Try again: `./setup-dev.sh`

**"Test account won't seed"**
- Backend must be running first
- Wait 3 seconds after backend starts
- Check logs for seed response

**"Flutter app won't connect to backend"**
- Ensure backend URL in `JobTrigger-Frontend/config/dev.json` is `http://127.0.0.1:5001`
- Backend must be running
- Check phone/simulator can reach localhost

---

## 📚 Related Docs

- [MongoDB Cloud Setup](./mongodb-cloud-setup.md) — Detailed Atlas configuration
- [API Reference](./api-reference.md) — Backend + Jenkins endpoints
- [Architecture](./architecture.md) — System design
