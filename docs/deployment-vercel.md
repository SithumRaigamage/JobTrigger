# Website on Vercel — deployment

The website (`JobTrigger-Web`) is a Next.js App Router project. This doc is
the Vercel half of the production setup; the backend is on Render
([`deployment-render.md`](deployment-render.md)). Adding a project and
changing its settings are owner actions (M-13); everything below can be
prepared in the repo, which is what `JobTrigger-Web/vercel.json` does.

## What `vercel.json` sets

| Key | Value | Why |
|---|---|---|
| `framework` | `nextjs` | Skips auto-detection, so a stray config file cannot change the build |
| `installCommand` | `npm ci` | Uses the committed lockfile exactly, as CI does |
| `buildCommand` | `npm run build` | Same command as the local merge gate |
| `regions` | `sin1` (Singapore) | Next to the Render backend (`render.yaml` `region: singapore`). Both are assumptions until the owner confirms where most users are (M-13/M-14) |

Nothing else is set on purpose:

- **No `headers`** — the CSP and the other security headers come from
  `next.config.ts` / `src/security-headers.ts` for every response. Adding
  them here as well would duplicate them.
- **No `redirects`** — the app's routes and `src/proxy.ts` own those.
- **No secrets** — Vercel project settings hold them, never the repo.

`NEXT_DIST_DIR`, `NEXT_STANDALONE`, `E2E_ALL_TOOLS` and `PADDLE_SCRIPT_URL`
are deliberately unset on Vercel: the first is for the local e2e build, the
second makes the Docker image's standalone output (which Vercel does not
use), the third switches the tool manifest for tests only, and the last
overrides Paddle's script address for tests. The support address the site
shows comes from the backend's `GET /api/appinfo`, not from a website
variable.

## One-time project setup (owner, M-13)

1. Vercel → **Add New → Project** → import the GitHub repo.
2. **Root Directory:** `JobTrigger-Web`. (Framework, build and install
   commands come from `vercel.json`.)
3. **Node version:** 24 — the repo's `.nvmrc` and `package.json` `engines`
   ask for it; Vercel reads them.
4. **Settings → Git:** production branch `main` only. Leave preview
   deployments on for PRs if you want them; they will have no backend URL,
   so the portal pages will say setup is unavailable — that is expected.
5. **Environment variables** (Production): see the table below. Set the same
   names in Preview only if you want a working portal there.
6. **Domain:** `jobtrigger.app` (apex) plus `www` redirecting to it, per
   `docs/deployment.md`. Vercel issues the TLS certificate.
7. Deploy, then run the post-deploy checks below.

## Environment variables (names only; values from the provider dashboards)

| Variable | Production value | Notes |
|---|---|---|
| `JOBTRIGGER_BACKEND_URL` | `https://api.jobtrigger.app` | Must be `https://`; the config refuses `http://` outside loopback/container names |
| `SESSION_SECRET` | 32+ random characters | Generate once, store it with the other production secrets. Changing it signs everyone out |
| `SITE_URL` | `https://jobtrigger.app` | Canonical URL for metadata, `robots.txt` and the sitemap |
| `PADDLE_CLIENT_TOKEN` | the live client token | `live_…` for production; `PADDLE_ENV=production` must match |
| `PADDLE_ENV` | `production` | `sandbox` while testing checkout |
| `NEXT_PUBLIC_SENTRY_DSN` | the website GlitchTip DSN | Public by design (write-only key) |
| `NEXT_PUBLIC_SENTRY_ENVIRONMENT` | `production` | Label on reports |
| `NEXT_PUBLIC_SENTRY_RELEASE` | `web@1.0.0` | Keep in step with the release |
| `UMAMI_URL`, `UMAMI_WEBSITE_ID` | the self-hosted Umami URL and site id | Optional; unset means no analytics |

Never put a secret in a `NEXT_PUBLIC_*` variable: Next inlines those into the
browser bundle.

## Before merging anything that deploys

GitHub Actions is off, so the gate is local, from `JobTrigger-Web/`:

```bash
npm run check     # format, lint, typecheck, unit tests, production build
npm run e2e       # Playwright against a production build, desktop + 360 px
```

Both must be clean. The same two commands are what CI runs when it is on.

## Post-deploy checks

From any machine:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://jobtrigger.app/
curl -sS -o /dev/null -w '%{http_code}\n' https://jobtrigger.app/pricing
curl -sS -o /dev/null -w '%{http_code}\n' https://jobtrigger.app/sitemap.xml
curl -sSI https://jobtrigger.app/ | grep -i 'content-security-policy'
```

Expected: `200`, `200`, `200`, and a CSP header. Then, on the phone:

1. Open `https://jobtrigger.app` in Safari.
2. Sign in with an existing account and open **Servers** — the list must
   load from `https://api.jobtrigger.app`.
3. Add a Jenkins server and check it appears in the app after a refresh.

If the portal says setup is unavailable, `JOBTRIGGER_BACKEND_URL` or
`SESSION_SECRET` is missing in the Vercel project.

## Rollback

Vercel keeps every deployment. **Deployments → the last known good one →
Promote to Production** is the rollback; no git operation needed. Record it
in `Releases/v1.0.0/deployment-log.md` with the time and the reason.
