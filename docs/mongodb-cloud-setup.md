# MongoDB Atlas setup (development)

The backend stores its data in **MongoDB Atlas**, MongoDB's cloud service.
There is no local MongoDB (Phase 17, decided 2026-10-26): no Docker
container, no `USE_DOCKER`. The backend code is unchanged; only
`MONGODB_URI` in `JobTrigger-Backend/.env` points at Atlas.

This guide sets up the **development** database once, in about 15
minutes. Production is a separate project, set up when the backend host
is chosen (`docs/deployment.md`, "Database").

| | Development (this guide) | Production (later) |
| --- | --- | --- |
| Atlas project | `jobtrigger-dev` | `jobtrigger-prod` |
| Cluster tier | Free **M0** (512 MB, shared, **no backups**) | Paid, with backups |
| Data | Your own test data | Real users |

Backend tests never use Atlas: `npm test` runs on a throwaway in-memory
MongoDB that exists only for that run.

## 1. Create the project and the cluster

1. Sign in at [cloud.mongodb.com](https://cloud.mongodb.com) (create a
   free account if needed).
2. **New Project** → name it `jobtrigger-dev` → **Create Project**.
3. **Create** a cluster → choose **M0 (Free)**.
   - **Name:** `jobtrigger-dev`
   - **Provider and region:** any provider; pick the region **closest to
     you**, since every request your backend makes travels there.
   - Untick **Preload sample dataset**.
4. **Create Deployment**. Atlas then offers a quick-start dialog for a user
   and an IP address. Close it: steps 2 and 3 below set both up with
   tighter permissions than the defaults.

## 2. Create the database user

The backend gets its own user that can read and write the `jobtrigger`
database **and nothing else**, so a leaked password can't touch other
databases or cluster settings.

1. **Security → Database Access → Add New Database User**.
2. **Authentication Method:** Password.
3. **Username:** `jobtrigger-dev-app`.
4. **Password:** **Autogenerate Secure Password**, then **Copy** it
   somewhere safe for step 4 (a password manager, not a file in this repo).
5. **Database User Privileges → Add Specific Privilege:**
   - Role: `readWrite`
   - Database: `jobtrigger`
   - Collection: leave empty (all collections)
6. **Add User**.

> Don't pick the built-in **Atlas admin** or **Read and write to any
> database** roles: both reach every database on the cluster.

## 3. Allow your computer to connect

Atlas refuses every connection until its address is on the list.

1. **Security → Network Access → Add IP Address**.
2. **Add Current IP Address** → add a comment such as `my laptop` →
   **Confirm**.

Your home or office IP can change. If the backend suddenly can't reach
Atlas (section 7), add the new one here. Don't use **Allow Access from
Anywhere** (`0.0.0.0/0`) for development: it leaves only the password
between the internet and the database.

## 4. Build the connection string

1. **Database → Clusters → Connect** on `jobtrigger-dev` → **Drivers** →
   **Node.js**.
2. Copy the string. It looks like:

   ```text
   mongodb+srv://jobtrigger-dev-app:<db_password>@jobtrigger-dev.abcde.mongodb.net/?retryWrites=true&w=majority&appName=jobtrigger-dev
   ```

3. Replace `<db_password>` with the password from step 2. If it contains
   any of `@ : / ? # [ ] %`, URL-encode those characters (`@` → `%40`,
   `:` → `%3A`, `/` → `%2F`, `%` → `%25`, and so on).
4. Add the database name after the host, before the `?`:

   ```text
   mongodb+srv://jobtrigger-dev-app:PASSWORD@jobtrigger-dev.abcde.mongodb.net/jobtrigger?retryWrites=true&w=majority&appName=jobtrigger-dev
   ```

   The backend and its scripts select `jobtrigger` themselves, so this is
   for tools such as `mongosh`; it does no harm either way.

## 5. Put it in `.env`

Open `JobTrigger-Backend/.env` yourself and set:

```env
MONGODB_URI=mongodb+srv://jobtrigger-dev-app:PASSWORD@jobtrigger-dev.abcde.mongodb.net/jobtrigger?retryWrites=true&w=majority&appName=jobtrigger-dev
```

Leave every other line as it is. In particular **keep
`CREDENTIALS_ENCRYPTION_KEY` stable** from now on: every Jenkins, GitHub and
SonarQube secret saved in Atlas is encrypted with it, and a new key would
make all of them unreadable (`docs/deployment.md`, "Backend secrets at
rest"). `.env` is git-ignored; never commit it or paste it into a chat,
issue or PR.

## 6. Check the connection

```bash
cd JobTrigger-Backend
npm run dev
```

Success is these two log lines (one JSON object per line):

```text
{"level":"info","time":"…","msg":"server.mongo_connected"}
{"level":"info","time":"…","msg":"server.listening","port":5001}
```

and `curl http://127.0.0.1:5001/healthz` answers `{"status":"ok"}`.

Then stop it (`Ctrl+C`) and run `./setup-dev.sh` from the repository root:
it seeds the dev account and sample servers into Atlas and starts the
backend again ([Dev Setup](./dev-setup.md)).

## 7. Troubleshooting

The backend stops with a `"msg":"server.mongo_connect_failed"` line on
stderr; its `error` field carries the reason:

| Message contains | Cause | Fix |
| --- | --- | --- |
| `Server selection timed out` / `ReplicaSetNoPrimary` | Your IP isn't on the Network Access list, or a network blocks port 27017 | Step 3 again; try another network |
| `bad auth` / `Authentication failed` | Wrong username or password, or a special character not URL-encoded. A common slip: using the **cluster** name (`jobtrigger-dev`, also in the host) instead of the **database user** (`jobtrigger-dev-app`) | Match the user to **Database Access** exactly; step 4.3; or reset the password (step 2, **Edit**) and wait for "Deploying your changes" to finish |
| `querySrv ENOTFOUND` / `ETIMEOUT` | Your DNS can't resolve the `mongodb+srv` address | Check the cluster name; try another network or DNS (some routers block SRV lookups) |
| `not authorized on jobtrigger` | The user's privilege isn't `readWrite` on `jobtrigger` | Step 2.5 |

Free M0 clusters are **paused after a long period of inactivity**. If
Atlas shows the cluster as paused, press **Resume** and wait a minute.

## If the password leaks

1. **Database Access → `jobtrigger-dev-app` → Edit → Edit Password →
   Autogenerate**, then **Update User**. The old password stops working
   immediately.
2. Put the new password in `.env` (steps 4–5) and restart the backend.
3. Check **Project → Activity Feed** for connections you don't recognise.
