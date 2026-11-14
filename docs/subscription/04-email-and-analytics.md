# Email and analytics — integration plan

**Date:** 2026-11-12 · **Status:** plan, waiting for approval (CLAUDE.md §9).
Decides P20-01 and P20-02 in
[`tasks/phase-20-subscriptions.md`](../../tasks/phase-20-subscriptions.md).
The backend deployment and store release are **on hold** (owner,
2026-11-12), so everything here targets **local development** first.

## 1. What the DevOps lab already has

The owner's local stack (`~/Other/02-DevOps-Lab/custom-devops-stack`) was
read end to end. Relevant pieces:

| In the lab | Useful for JobTrigger? |
|---|---|
| Prometheus + Grafana + cAdvisor + Loki/Promtail (`observability/`) | **Ops** metrics and logs, not product analytics. Usable later for backend metrics (§5). |
| General Postgres 16 (`postgres/`, port 5433) | Yes — reused as Umami's database. |
| MongoDB 7 (`mongodb/`) | Not needed: JobTrigger uses Atlas (Phase 17). |
| StackPilot alerts (Discord) | Not an email service. |
| **Product analytics** | Missing → **added: Umami** (`analytics/`, port 3004). |
| **Email** | Missing → **added: Mailpit** (`mailpit/`, SMTP 1025, inbox 8025). |
| **Crash reporting** | Missing → proposed next: GlitchTip (§6). |

Both new services follow that workspace's rules: one folder each,
`.env.example` with generated secrets, `127.0.0.1` only, memory limits,
health checks, `devops-network`, `scripts/stack.sh`, `make scan-images`,
README and roadmap entries.

```bash
# On the Mac, in custom-devops-stack/
make bootstrap                          # creates analytics/.env with generated secrets
make up S="postgres analytics mailpit"  # Umami http://localhost:3004 · inbox http://localhost:8025
```

## 2. Decisions

| Decision | Choice | Why |
|---|---|---|
| Analytics tool (P20-01) | **Umami**, self-hosted | Light (≈512 MB cap, no extra DB), cookie-free, custom events with data, a plain HTTP API, so **no new SDK** in the app or website. PostHog and Plausible need ClickHouse, too heavy for the lab Mac. |
| How events are sent | **Server-side / direct HTTP**, never a browser tracker script | The website's strict nonce CSP (`web-architecture.md`) stays unchanged; nothing third-party runs in the browser. |
| Email in development (P20-02) | **Mailpit** over SMTP | Real SMTP code path, nothing delivered, every message visible. |
| Email in production | **Deferred** until the backend deploys | Only the SMTP settings change (SES, Resend, Postmark…). |
| Email library | `nodemailer` — **new backend dependency, needs approval** | The standard SMTP client for Node. No provider SDK, so the provider can change without code. |
| Crash reporting | GlitchTip later (§6) | Separate decision; not needed while there are no real users. |

## 3. Email

### 3.1 Backend

| File | What |
|---|---|
| `lib/mailer.js` | `sendMail({ to, subject, text, html })` over nodemailer SMTP. Transport injected, so tests use nodemailer's `jsonTransport` (no network). When `SMTP_HOST` is unset, mail is **disabled**: logged as `mail.disabled`, never thrown. |
| `emails/passwordReset.js` | Plain-text and simple HTML bodies. No tracking pixels or remote images. |
| `config/env.js` | Optional `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM`. `invalidConfig()` refuses a half-set SMTP config. Names added to `.env.example` (no values). |

Local `.env` (owner fills in; not read by the agent):
`SMTP_HOST=localhost`, `SMTP_PORT=1025`, `SMTP_SECURE=false`,
`MAIL_FROM="JobTrigger <no-reply@jobtrigger.local>"`.

### 3.2 First use: password reset (US-AUTH-08, promoted from `backlog.md`)

Follows the story's own rules: single-use 15-minute tokens, no account
enumeration, `tokenVersion` bump on reset.

- `POST /api/auth/password-reset/request { email }` → always `202` with the
  same body, whether or not the account exists. Rate-limited per IP and
  per email (reuse `middleware/rateLimit.js`).
- Token: 32 random bytes, sent once in the email; only its SHA-256 is
  stored in `PasswordResetToken { userId, tokenHash, expiresAt, usedAt }`
  with a TTL index. A new request replaces older tokens.
- Email link: one link, to the website's `/reset-password?token=…`
  (`RESET_PASSWORD_URL`; `http://localhost:3000/reset-password` when
  unset; required and `https://` in production when mail is on). No app
  deep link: a password is reset on the web only.
- `POST /api/auth/password-reset/confirm { token, newPassword }` → checks
  hash, expiry and unused, applies the existing password rules, saves,
  bumps `tokenVersion` (signs out every device), deletes the user's tokens.
- Web: `/forgot-password` and `/reset-password` pages (server actions,
  zod, no-store, no-referrer). App: the login screen's "Forgot password?
  Reset it on the web" opens `<WEBSITE_BASE_URL>/forgot-password` in the
  browser; nothing else in the app.
- Later (Phase 20 billing): trial-ending and billing-issue notices reuse
  the mailer.

### 3.3 Testing on the iPhone

Mac: start Mailpit (`make up S=mailpit` in the lab), the backend (with
`SMTP_HOST=localhost`, `SMTP_PORT=1025`) and the website
(`npm run dev -- -H 0.0.0.0` in `JobTrigger-Web/`, so the phone can reach
it), then `scripts/run-on-iphone.sh`. Phone: Login → **Forgot password?
Reset it on the web** → Safari opens the website → enter the email →
**Send reset link**. Mac: open http://localhost:8025 and the email; open
its link (on the Mac, or on the phone after replacing `localhost` with the
Mac's address), choose a new password. Back in the app, log in with it.

## 4. Analytics

### 4.1 Event catalogue (website and backend; the app sends none)

| Event | Where | Data (no personal data) |
|---|---|---|
| `app_open` | app | `platform` |
| `tool_selected` | app | `tool` |
| `server_added` | app, web | `tool`, `source` (`app`/`web`) |
| `build_triggered` | app | `tool`, `withParameters` |
| `limit_hit` | app, web | `limit` (e.g. `maxCredentialsTotal`) |
| `paywall_view` | app | `reason` |
| `purchase_started` / `purchase_completed` / `purchase_cancelled` | app | `product` (monthly/yearly) |
| `trial_started`, `subscription_renewed`, `subscription_expired`, `refund` | backend (webhook) | `product`, `store` |
| `restore` | app | `result` |
| `pricing_view`, `signup` | web | — |
| `password_reset_requested` | backend | — |

**Never sent:** emails, user ids, server URLs, job or repo names, tokens,
IP-derived location beyond what Umami does by default. Events are
anonymous and not linked to the account.

### 4.2 App

None (owner decision 2026-11-12). The app-only rows in the catalogue
above (`app_open`, `tool_selected`, `build_triggered`, paywall and
purchase events) are not sent. Purchase outcomes are still counted on the
backend from the store webhooks.

### 4.3 Website

- `src/server/analytics.ts` (`server-only`): `track()` posts to Umami from
  server actions and server components. No tracker script, no CSP change.
- Env: `UMAMI_URL`, `UMAMI_WEBSITE_ID`; unset → no-op.

### 4.4 Backend

- `lib/analytics.js`: same `track()` for webhook and auth events, no-op
  when unconfigured.

### 4.5 Privacy

- Privacy policy (website) and App Store "App Privacy" / Play "Data
  safety": product interaction, not linked to identity, not used for
  tracking. Re-check `PrivacyInfo.xcprivacy`.

## 5. Ops metrics (later, optional)

The lab's Prometheus can scrape the backend: add `prom-client` (another
dependency, separate approval) for `/metrics` (request counts, latency,
mail sends), and a scrape job for `host.docker.internal:5001`. Logs reach
Loki only once the backend runs in a container. Not needed until the
backend deploys.

## 6. Crash reporting (next, separate approval)

GlitchTip (open-source, Sentry-compatible) as a lab service reusing
`postgres/`, with `sentry_flutter` in the app and `@sentry/nextjs` on the
website. Not built now: it adds two dependencies and another always-on
service; it matters once there are testers.

## 7. Backend configuration (P20-72, P20-73, P20-78)

All optional. Missing values switch the feature off; a half-set or
malformed value stops the server at startup (`config/env.js`,
`invalidConfig`). Add the **names** to `JobTrigger-Backend/.env.example`
by hand (agents don't open env files, CLAUDE.md §8).

| Variable | Development (lab) | Meaning |
|---|---|---|
| `SMTP_HOST` | `localhost` | Mail is off when unset (`mail.disabled` is logged) |
| `SMTP_PORT` | `1025` | Default 587 |
| `SMTP_SECURE` | `false` | `true` for implicit TLS (port 465) |
| `SMTP_USER`, `SMTP_PASS` | unset | Set both or neither |
| `MAIL_FROM` | `JobTrigger <no-reply@jobtrigger.local>` | Sender |
| `RESET_PASSWORD_URL` | `http://localhost:3000/reset-password` once the web page exists | Web link base; unset means the email has only the app link |
| `UMAMI_URL` | `http://localhost:3004` | Analytics off when unset |
| `UMAMI_WEBSITE_ID` | from Umami → Settings → Websites | Website "JobTrigger backend" |
| `PASSWORD_RESET_RATE_LIMIT`, `PASSWORD_RESET_EMAIL_RATE_LIMIT`, `PASSWORD_RESET_CONFIRM_RATE_LIMIT` | defaults 5 / 3 / 10 | Limiter overrides |

## 8. Tasks

Added to Phase 20 as P20-70 … P20-79.
