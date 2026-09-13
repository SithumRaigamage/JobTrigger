# MongoDB Cloud (Atlas) Setup Guide

## 🌐 Using MongoDB Atlas Instead of Docker

### Step 1: Create a MongoDB Atlas Account

1. Go to [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. Sign up (free tier available)
3. Create a new project
4. Create a new cluster (free M0 tier is enough for development)

### Step 2: Get Your Connection String

1. In Atlas, go to **Databases** → Click **Connect** on your cluster
2. Choose **"Drivers"** → **Node.js**
3. Copy the connection string: `mongodb+srv://username:password@cluster.mongodb.net/jobtrigger`
4. Replace `username` and `password` with your Atlas credentials
5. The database name should be `jobtrigger`

### Step 3: Configure Your Backend

Update `lab-trigger-backend/.env`:

```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/jobtrigger
PORT=5001
JWT_SECRET=supersecretjwtkey_123456
```

> **⚠️ Security:** Never commit `.env` to git. It's in `.gitignore` for a reason.

### Step 4: Run Setup Script

**For MongoDB Cloud (default):**
```bash
./setup-dev.sh
```

This will:
- ✅ Verify your MongoDB Cloud connection string
- ✅ Seed the test account
- ✅ Start the backend

**For Docker (local MongoDB):**
```bash
USE_DOCKER=true ./setup-dev.sh
```

This will:
- ✅ Start MongoDB in Docker
- ✅ Seed the test account
- ✅ Start the backend

### Step 5: Stop Services

```bash
./stop-dev.sh
```

(MongoDB Cloud runs in the cloud, so no container to stop)

---

## 🔄 Workflow with MongoDB Cloud

```bash
# 1. Update lab-trigger-backend/.env with your connection string

# 2. Run setup (no Docker needed!)
./setup-dev.sh

# 3. In another terminal, run Flutter app
cd job_trigger
flutter run -d "iPhone Air"

# 4. Login with test account
# Email: test@jobtrigger.dev
# Password: password123

# 5. When done
./stop-dev.sh
```

---

## 📋 MongoDB Cloud vs Docker

| Aspect | MongoDB Cloud | Docker (Local) |
|--------|---|---|
| Setup time | 5 min (one-time) | 1 min (each session) |
| Internet required | Yes | No |
| Data persistence | Yes (cloud) | Depends on setup |
| Cost | Free tier | Free (local) |
| Good for | Remote work, team sharing | Offline development |

---

## ✅ Verify Connection

Test your connection string:

```bash
cd lab-trigger-backend
npm run dev
```

If you see:
```
Server running on http://127.0.0.1:5001
Connected to MongoDB
```

You're all set! ✅

---

## 🆘 Troubleshooting

**"connect ECONNREFUSED"**
- Check your connection string in `.env`
- Verify IP allowlist in MongoDB Atlas (click "Network Access")
- Make sure your password has no special characters (or URL-encode them)

**"Authentication failed"**
- Double-check username/password in connection string
- Test credentials in MongoDB Atlas website first

**"Unknown error"**
- Check MongoDB Atlas status page
- Try clicking "Connect" again to get fresh connection string
