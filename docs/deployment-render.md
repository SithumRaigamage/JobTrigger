# Backend on Render — deployment plan

Proposed 2026-11-16 (owner chose Render). **Owner asked for the blueprint on
2026-11-21; connecting the workspace, creating the services and entering the
secret values are still owner actions (M-14).** It covers the backend
(`JobTrigger-Backend`). The website stays on Vercel (`deployment.md`,
"Vercel (P15-22)", and [`deployment-vercel.md`](deployment-vercel.md)).
Deploying the backend unblocks the portal going live (P15-22), subscriptions
(P20-05) and the production database steps (PE-30/31).

Render facts below were checked on 2026-11-16 against Render's docs and pricing
pages and recent write-ups. Prices change; confirm on render.com/pricing before
paying. Lines marked **(check)** could not be confirmed.

## Decisions

| Item | Choice | Why |
|---|---|---|
| Service type | Web Service from the existing `JobTrigger-Backend/Dockerfile` | Same image CI already scans (Trivy). No build differences between lab and production |
| Instance | **Starter** (about $7/month, 512 MB, always on) for production | Free instances spin down after 15 minutes idle and take about a minute to wake. The app's sign-in and credential calls would hang for a minute after every quiet spell |
| Staging | Free instance is acceptable | A cold start is fine for testing |
| Region | **Singapore** **(check that it's offered on your workspace)** | Closest Render region to Sri Lanka, and the Atlas production cluster goes in the same region (`deployment.md`, Database, step 4) |
| Domain | `api.jobtrigger.app` (matches `JobTrigger-Frontend/config/prod.json`) | Render issues the TLS certificate |
| Health check | `/healthz` | Already 503 until MongoDB is connected (AUD-17), so Render won't route to a broken instance |
| Deploys | From a release branch (`main`), not `develop` | `develop` moves daily. Turn auto-deploy on for `main` only, after CI passes **(check Render's "deploy after checks" setting)** |

## Network access to MongoDB Atlas

Render sends outbound traffic from a fixed set of IP addresses per region,
shown on the service's **Connect → Outbound** tab. Those addresses are
**shared by every Render service in that region**, so allowlisting them in
Atlas still admits other Render customers' services, leaving the database
password as the main barrier. Options, best first:

1. **Render dedicated outbound IPs** (paid add-on, exclusive to your workspace).
   Allowlist only those in Atlas.
2. A static-IP proxy such as QuotaGuard (Render documents it).
3. Render's shared regional IPs in the Atlas allowlist. Acceptable to start,
   but record it as a known gap.

Never `0.0.0.0/0` (`deployment.md`, Database, step 6).

## Environment variables (all as Render **secret** env vars, never in the repo)

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `MONGODB_URI` | Atlas `jobtrigger-prod` cluster, user `jobtrigger-prod-app` |
| `JWT_SECRET` | New random value, production only |
| `CREDENTIALS_ENCRYPTION_KEY` / `_KEY_ID` | New key, id `k1`. Keep a copy outside Render with the backups (`deployment.md`, step 8) |
| `TRUST_PROXY` | `1` **(check: confirm Render puts exactly one proxy in front by logging the client IP on a test request)** |
| `SITE_URL` | `https://jobtrigger.app` |
| `RESET_PASSWORD_URL` | `https://jobtrigger.app/reset-password` (required in production when mail is on) |
| `SMTP_*`, `MAIL_FROM` | A real mail provider (Mailpit is the lab only) |
| `CORS_ORIGINS` | Empty: the app sends no `Origin`, and the website calls the backend from its server |
| `SENTRY_DSN`, `SENTRY_ENVIRONMENT` | The production GlitchTip backend DSN, `production` (see below) |
| `BILLING_ENABLED` | `true` for 1.0.0 (owner decision 2026-11-18); requires the RevenueCat and/or Paddle values below |
| `REVENUECAT_SECRET_API_KEY` | RevenueCat secret REST key (`sk_…`) |
| `REVENUECAT_WEBHOOK_AUTH` | Random shared secret; the same value in RevenueCat's webhook `Authorization` |
| `PADDLE_API_KEY`, `PADDLE_WEBHOOK_SECRET` | Paddle live API key and notification secret |
| `PADDLE_PRICE_MONTHLY`, `PADDLE_PRICE_YEARLY` | Paddle `pri_…` ids for $9.99/month and $29.99/year |
| `PADDLE_ENV` | `production` |
| `SANDBOX_BILLING` | **Do not set.** The server refuses to start with it in production |
| `PORT` | Leave unset unless Render requires it; the image listens on 5001 **(check that Render detects the port, or set it to 5001)** |

## Crash reports in production

The lab GlitchTip runs on a Mac and isn't reachable from Render. Choose one:
- **GlitchTip on Render:** one Starter web service (all-in-one mode, as in the
  lab) plus a small Render Postgres. Roughly doubles the monthly cost.
- **Hosted GlitchTip** (app.glitchtip.com) on its free or small plan. Same SDKs;
  only the DSN changes.
- **Defer:** leave `SENTRY_DSN` empty at first. The backend sends nothing.

Recommendation: hosted GlitchTip to start, since it costs least effort. Name
it in the privacy policy's crash-reports section either way.

## Steps

- [ ] RD-01 Owner: Render workspace (Hobby), connect the GitHub repo.
- [ ] RD-02 Owner: Atlas `jobtrigger-prod` project and cluster in the same
      region, per `deployment.md` "Before launch" steps 1–9.
- [ ] RD-03 Create the web service: Docker, root `JobTrigger-Backend`,
      Starter, region, health check `/healthz`, env vars above.
      Optionally a `render.yaml` blueprint in the repo with **no secrets**
      in it (every secret `sync: false`).
- [ ] RD-04 Atlas network access (option 1, 2 or 3 above).
- [ ] RD-05 First deploy; `/healthz` returns 200.
- [ ] RD-06 PE-30/31: confirm the key, then run
      `npm run encrypt-credentials -- --dry-run` and the real run against
      production (Render Shell or a one-off job **(check which your plan
      offers)**). On a brand-new database it reports 0.
- [ ] RD-07 `node scripts/seedAppInfo.js` with `SITE_URL` set (PE-01).
- [ ] RD-08 Custom domain `api.jobtrigger.app` and its DNS record; TLS issued.
- [ ] RD-09 Vercel: `JOBTRIGGER_BACKEND_URL=https://api.jobtrigger.app`,
      connect the project, deploy the website (P15-22).
- [ ] RD-10 Check from the iPhone with a release build pointing at
      `config/prod.json`: sign up, add a Jenkins server on the website, see
      it in the app.
- [ ] RD-11 Atlas alerts and a restore drill (`deployment.md`).

## Rough monthly cost

Backend Starter about $7, plus the Atlas production tier with backups, plus
the crash-reporting choice above, plus a domain. Check each on the providers'
own pricing pages before committing.
