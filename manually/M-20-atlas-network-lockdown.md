# M-20 — Lock down MongoDB Atlas network access

> Added by the pre-release audit (2026-11-20). Back to the [index](README.md).

**Source:** `docs/deployment.md` (Database, step 6), `docs/deployment-render.md`
("Network access to MongoDB Atlas", RD-04), workplan D2.
**Why only you:** the Atlas projects are in your account.

The dev cluster's Network Access is currently open to everyone
(`0.0.0.0/0`) for iPhone-hotspot development. That was never needed:
**the iPhone never connects to Atlas — only the backend on the Mac does**,
so only the Mac's public IP needs to be allowed.

**Dev project (now):**
1. Atlas → the dev project → Security → **Network Access**.
2. **Delete** the `0.0.0.0/0` entry.
3. **Add IP Address → Add Current IP Address**, tick **"This entry is
   temporary"** and pick 1 week. Do this from the Mac, on the network you
   develop on. On the iPhone hotspot the Mac's public IP is the carrier's
   and changes; when the backend logs `Server selection timed out`, repeat
   step 3 (old temporary entries expire on their own).

**Production project `jobtrigger-prod` (before launch, separate project):**
1. Never add `0.0.0.0/0` and never add a developer IP.
2. Allow only the backend host's egress: on Render, the service's
   **Connect → Outbound** IP ranges for its region (shared with other Render
   customers — acceptable to start), or better Render's dedicated outbound
   IPs / a static-IP proxy (exclusive to you).
3. Database user `jobtrigger-prod-app` with `readWrite` on the JobTrigger
   database only, a long random password, and no Atlas UI access.

**Evidence:** the Network Access list shows no `0.0.0.0/0` in either project;
the production list contains only the host's ranges.
