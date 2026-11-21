# Configuration and environment variables

Every setting JobTrigger reads, where it lives, and what to set for local
development, store sandboxes and production. For the subscription-specific
setup steps see [`subscription/sandbox-testing.md`](subscription/sandbox-testing.md);
for the full scenario list see [`subscription/coverage.md`](subscription/coverage.md).

## Where values live

| Place | In git? | Used by | Holds secrets |
|---|---|---|---|
| `JobTrigger-Backend/.env` | **No** (never read or edited by an agent) | Backend | **Yes** |
| `JobTrigger-Frontend/config/*.json` | `dev`/`staging`/`prod` yes | App build (`--dart-define-from-file`) | No (public SDK keys only) |
| `JobTrigger-Frontend/config/device.json` | **No** | App on a physical device | No |
| `JobTrigger-Frontend/config/billing.json` | **No** | Release build (RevenueCat public keys) | No |
| `JobTrigger-Frontend/config/sentry.json` | **No** | Release build (app DSN) | No (write-only key) |
| `environment.conf` | Yes | Local launchers (`run-on-iphone.sh`, `run-flutter.sh`) | No |
| Hosting environment variables | No | Backend (Render), website (Vercel) | **Yes** |

Rules:

- Never commit `.env`, `.env.local`, `billing.json`, `sentry.json` or
  `device.json`.
- The app only ever gets **public** SDK keys. RevenueCat's secret REST key
  and Paddle's API key stay on the backend.
- `NEXT_PUBLIC_*` values are compiled into the website's browser bundle.
  Nothing secret may use that prefix.
- After changing a Flutter `@riverpod`/model file run
  `dart run build_runner build --delete-conflicting-outputs`; environment
  changes need a rebuild, not codegen.

## Backend (`JobTrigger-Backend/.env`)

### Required — the server refuses to start without them

| Variable | Development | Production | Notes |
|---|---|---|---|
| `MONGODB_URI` | Atlas `jobtrigger-dev` cluster | Atlas `jobtrigger-prod` | Secret. The seed refuses a URI containing `prod`. |
| `JWT_SECRET` | Any long random string | New random value, production only | Signs access/refresh tokens. Changing it signs everyone out. |
| `CREDENTIALS_ENCRYPTION_KEY` | Base64 of 32 random bytes | New key, backed up outside the host | Encrypts stored tool credentials (AES-256-GCM). Losing it makes them unreadable. |

Generate the encryption key:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

### Server and network

| Variable | Default | Development | Production |
|---|---|---|---|
| `NODE_ENV` | development | leave unset | `production` |
| `PORT` | `5001` | `5001` | host-provided or `5001` |
| `HOST` | `0.0.0.0` | `0.0.0.0` (the phone must reach it) | leave default |
| `LOG_LEVEL` | `info` | `debug` when needed | `info` |
| `TRUST_PROXY` | unset | unset | number of proxy hops (Render: `1`, confirm) |
| `CORS_ORIGINS` | empty (no CORS) | unset | unset for the app; add a browser origin only if one calls the API directly |
| `SITE_URL` | `http://localhost:3000` | `http://<Mac-Wi-Fi-IP>:3000` for the phone | `https://jobtrigger.app` |
| `TEAM_PLAN_ENABLED` | `false` | `false` | `false` for 1.0.0 (set in `render.yaml`), `true` from release 1.0.1 (US-SUB-11); every `/api/team` route is a 404 while off |
| `PADDLE_PRICE_TEAM_MONTHLY`, `PADDLE_PRICE_TEAM_YEARLY` | unset | unset | Paddle per-seat prices for the team plan ($6.99/seat/month, $69.90/seat/year) |
| `SUPPORT_EMAIL` | `support@jobtrigger.app` | unset | unset (`support@` + the `SITE_URL` domain), or the real support inbox |
| `MIN_SUPPORTED_APP_VERSION` | unset (no app blocked) | unset | unset for 1.0.0; set to e.g. `1.0.1` and re-run `scripts/seedAppInfo.js` to make older apps show "Update required" (US-PROF-03) |
| `RESET_PASSWORD_URL` | `http://localhost:3000/reset-password` | `http://<Mac-Wi-Fi-IP>:3000/reset-password` | `https://jobtrigger.app/reset-password` |

`TRUST_PROXY` accepts only a whole number (1–99). `SITE_URL` is an origin
(no path); `RESET_PASSWORD_URL` is an http(s) URL without a query string.
Production with `SMTP_HOST` set requires an `https://` reset URL.

### Email (password reset, billing notices)

| Variable | Default | Development (Mailpit) | Production |
|---|---|---|---|
| `SMTP_HOST` | unset = mail off | `localhost` | provider host |
| `SMTP_PORT` | `587` | `1025` | provider port |
| `SMTP_SECURE` | `false` | `false` | `true` for implicit TLS |
| `SMTP_USER` | unset | unset | provider user |
| `SMTP_PASS` | unset | unset | provider password |
| `MAIL_FROM` | `JobTrigger <no-reply@jobtrigger.local>` | leave default | verified sender |

`SMTP_USER` and `SMTP_PASS` must be set together. Setting any SMTP value
without `SMTP_HOST` is refused at startup.

### Rate limits (per window, per IP or user)

| Variable | Default | Window |
|---|---|---|
| `LOGIN_RATE_LIMIT` | 10 | 15 min, failed logins per IP |
| `LOGIN_EMAIL_RATE_LIMIT` | 10 | 15 min, failed logins per account |
| `SIGNUP_RATE_LIMIT` | 5 | 60 min |
| `REFRESH_RATE_LIMIT` | 30 | 15 min, per user |
| `PASSWORD_RESET_RATE_LIMIT` | 5 | 15 min |
| `PASSWORD_RESET_EMAIL_RATE_LIMIT` | 3 | 60 min, per address |
| `PASSWORD_RESET_CONFIRM_RATE_LIMIT` | 10 | 15 min |
| `SUBSCRIPTION_REFRESH_RATE_LIMIT` | 10 | 10 min, per user |
| `CREDENTIAL_SECRET_RATE_LIMIT` | 30 | 10 min, per user |
| `BILLING_WEBHOOK_RATE_LIMIT` | 120 | 1 min |
| `STUDENT_EMAIL_START_RATE_LIMIT` | 5 | 60 min |
| `STUDENT_EMAIL_CONFIRM_RATE_LIMIT` | 15 | 15 min |
| `STUDENT_DOCUMENT_RATE_LIMIT` | 5 | 60 min |
| `ADMIN_RATE_LIMIT` | 120 | 1 min |
| `SUPPORT_TICKET_RATE_LIMIT` | 5 | 60 min |

### Billing

| Variable | Default | Local sandbox | Store sandbox / production |
|---|---|---|---|
| `BILLING_ENABLED` | `false` (everyone Pro) | `true` | `true` |
| `SANDBOX_BILLING` | `false` | `true` | **must be unset or `false`** |
| `REVENUECAT_SECRET_API_KEY` | unset | not needed | `sk_…` REST key |
| `REVENUECAT_WEBHOOK_AUTH` | unset | not needed | Shared secret RevenueCat sends as `Authorization` |
| `PADDLE_API_KEY` | unset | not needed | `pdl_sdbx_…` or `pdl_live_…` |
| `PADDLE_WEBHOOK_SECRET` | unset | not needed | Paddle notification destination secret |
| `PADDLE_PRICE_MONTHLY` | unset | not needed | Paddle `pri_…` for $9.99/month |
| `PADDLE_PRICE_YEARLY` | unset | not needed | Paddle `pri_…` for $29.99/year |
| `PADDLE_ENV` | `sandbox` | not needed | `sandbox` or `production`; must match the API key |

Rules enforced at startup (`config/env.js`):

- `BILLING_ENABLED=true` needs at least one source: RevenueCat, Paddle or the
  development sandbox. A half-set Paddle (some but not all four required
  values: API key, webhook secret and both price ids) is refused, as is
  `PADDLE_ENV` other than `sandbox`/`production`.
- `SANDBOX_BILLING=true` with `NODE_ENV=production` stops the server. The
  routes also answer 404 unless the flag is on.
- `BILLING_ENABLED` and `SANDBOX_BILLING` accept only `true`/`false`.

Backend endpoints the providers call:

| Provider | URL | Auth |
|---|---|---|
| RevenueCat | `https://<backend>/api/billing/revenuecat` | `Authorization: <REVENUECAT_WEBHOOK_AUTH>` |
| Paddle | `https://<backend>/api/billing/paddle/webhook` | Paddle signature, verified with `PADDLE_WEBHOOK_SECRET` |

### Other integrations

| Variable | Default | Notes |
|---|---|---|
| `STUDENT_ADMIN_EMAIL` | unset | Where student applications are announced; validated as an email |
| `STUDENT_RENEWAL_ENABLED` | `false` | Yearly renewal of the student grant |
| `STUDENT_JOBS_ENABLED` | `true` | Set `false` to stop the renewal job timer (tests do) |
| `UMAMI_URL` | unset = analytics off | Self-hosted Umami base URL |
| `UMAMI_WEBSITE_ID` | unset | Website id in Umami |
| `FCM_SERVICE_ACCOUNT` | unset = push off | Firebase service-account JSON on one line; malformed means no push |
| `SENTRY_DSN` | unset = crash reports off | Backend GlitchTip/Sentry DSN |
| `SENTRY_ENVIRONMENT` | `production`/`development` from `NODE_ENV` | Label on events |
| `SENTRY_RELEASE` | backend package version | Label on events |
| `CREDENTIALS_ENCRYPTION_KEY_ID` | `k1` | Stored with each encrypted value |
| `CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS` | unset | `k1:<old key>,k2:<older key>` during rotation |

### Backend template

A new environment needs at least this (fill the secrets from your secret
store, never from chat or git):

```env
NODE_ENV=production
PORT=5001
MONGODB_URI=mongodb+srv://<user>:<password>@<cluster>/jobtrigger
JWT_SECRET=<random>
CREDENTIALS_ENCRYPTION_KEY=<base64 32 bytes>
CREDENTIALS_ENCRYPTION_KEY_ID=k1
SITE_URL=https://jobtrigger.app
RESET_PASSWORD_URL=https://jobtrigger.app/reset-password
SMTP_HOST=<provider>
SMTP_PORT=587
SMTP_SECURE=true
SMTP_USER=<provider user>
SMTP_PASS=<provider password>
MAIL_FROM=JobTrigger <no-reply@jobtrigger.app>
TRUST_PROXY=1

BILLING_ENABLED=true
REVENUECAT_SECRET_API_KEY=<secret>
REVENUECAT_WEBHOOK_AUTH=<random shared secret>
PADDLE_API_KEY=<paddle api key>
PADDLE_WEBHOOK_SECRET=<paddle secret>
PADDLE_PRICE_MONTHLY=pri_...
PADDLE_PRICE_YEARLY=pri_...
PADDLE_ENV=production
```

For the **local sandbox** you do not edit `.env` at all. `setup-dev.sh`
exports these values by default:

```bash
PORT=5001 BILLING_ENABLED=true SANDBOX_BILLING=true
```

Start it with `./setup-dev.sh`, or run the backend directly with the same
flags:

```bash
cd JobTrigger-Backend
PORT=5001 BILLING_ENABLED=true SANDBOX_BILLING=true npm run dev
```

The device launchers read the committed `environment.conf`, whose local
defaults are `MODE=profile`, `USE_IP=1` and `SANDBOX_BILLING=1` (the app's
sandbox flag). Override any of them for one run, e.g.
`MODE=debug scripts/run-on-iphone.sh` for hot reload. Debug builds cannot be
opened from the iPhone home screen; use `MODE=install` for a standalone app.

## App build configuration (`JobTrigger-Frontend/config/`)

Passed with `--dart-define-from-file` and read only by
`core/config/app_config.dart`.

| Key | Committed files | Local device | Meaning |
|---|---|---|---|
| `ENVIRONMENT` | `dev`, `staging`, `prod` | `dev` | Must be `prod` for a release build |
| `BACKEND_BASE_URL` | per environment | written by the launcher | `http://` only outside release |
| `WEBSITE_BASE_URL` | per environment | written by the launcher | Password-reset links |
| `SENTRY_DSN` | not committed | `SENTRY_DSN_APP=…` | App crash reports; off when absent |
| `REVENUECAT_IOS_KEY` | `billing.json` (git-ignored) | `REVENUECAT_IOS_KEY=appl_…` | Public iOS SDK key |
| `REVENUECAT_ANDROID_KEY` | `billing.json` | `REVENUECAT_ANDROID_KEY=goog_…` | Public Android SDK key |
| `BILLING_PREVIEW` | dev only | launcher adds it | Static offers; purchases intentionally fail |
| `SANDBOX_BILLING` | dev only, `1` via `environment.conf` | `SANDBOX_BILLING=1` | Local sandbox store; impossible in release |

`AppConfig` ignores `BILLING_PREVIEW` and `SANDBOX_BILLING` in release
builds, and `build-release.sh` refuses a release without the key for the
target platform (unless `--allow-missing` is passed for an unsigned test
build).

RevenueCat setup values that must match the app:

| Value | JobTrigger |
|---|---|
| iOS bundle id | `Sraig.Lab-Trigger-frontend` (Xcode) |
| Android application id | `com.sraig.jobtrigger` |
| Entitlement | `pro` |
| Product ids | `jobtrigger_pro_monthly`, `jobtrigger_pro_yearly` |
| Prices | $9.99/month, $29.99/year, 7-day yearly trial |
| Webhook | `<backend>/api/billing/revenuecat` |

The **web** Paddle checkout does not need these keys in the app.

## Website (`JobTrigger-Web`)

Read and validated in `src/server/config.ts`; set them in the shell or the
hosting provider.

| Variable | Required | Local | Production |
|---|---|---|---|
| `JOBTRIGGER_BACKEND_URL` | for the portal | `http://127.0.0.1:5001` | `https://api.jobtrigger.app` |
| `SESSION_SECRET` | for the portal | generated by `npm run dev:portal` | 32+ random characters |
| `SITE_URL` | no | `http://localhost:3000` | `https://jobtrigger.app` |
| `PADDLE_CLIENT_TOKEN` | for checkout | `test_…` | `live_…` |
| `PADDLE_ENV` | no | `sandbox` | `production` (must match the token) |
| `UMAMI_URL` | no | e.g. `http://localhost:3004` | Umami base URL |
| `UMAMI_WEBSITE_ID` | no | — | Website id |
| `NEXT_PUBLIC_SENTRY_DSN` | no | — | Website GlitchTip DSN |
| `NEXT_PUBLIC_SENTRY_ENVIRONMENT` | no | — | `production` |
| `NEXT_PUBLIC_SENTRY_RELEASE` | no | — | e.g. `web@1.0.0` |

Without the two portal variables the marketing site still works and the
portal says setup isn't available. Without `PADDLE_CLIENT_TOKEN` the billing
page says web checkout is off.

## Mode summary

| Mode | Backend | App | Website |
|---|---|---|---|
| Normal local dev | `BILLING_ENABLED=false` | `BILLING_PREVIEW=1` | portal via `npm run dev:portal` |
| Local sandbox billing | `BILLING_ENABLED=true SANDBOX_BILLING=true` | `SANDBOX_BILLING=1` | — |
| Apple sandbox | `BILLING_ENABLED=true` + RevenueCat pair | `REVENUECAT_IOS_KEY=appl_…` | — |
| Google sandbox | same | `REVENUECAT_ANDROID_KEY=goog_…` | — |
| Web sandbox checkout | RevenueCat and/or Paddle sandbox | keys optional | `PADDLE_CLIENT_TOKEN=test_…` |
| Production 1.0.0 | all backend values above, `SANDBOX_BILLING` unset | release keys in `billing.json` | `live_` Paddle token, `PADDLE_ENV=production` |

## Startup failures and what they mean

| Message | Fix |
|---|---|
| `Missing required configuration: …` | Set `MONGODB_URI`, `JWT_SECRET`, `CREDENTIALS_ENCRYPTION_KEY` |
| `BILLING_ENABLED=true needs RevenueCat …` | Add RevenueCat, all Paddle values, or `SANDBOX_BILLING=true` for development |
| `SANDBOX_BILLING must never be enabled in production` | Remove it from production |
| `MAIL_FROM must be set to a real sender … in production when SMTP_HOST is set` | Set `MAIL_FROM`, e.g. `JobTrigger <no-reply@jobtrigger.app>`, on a domain the mail provider has verified |
| `JWT_SECRET must be at least 32 characters in production` | Generate a new one: `openssl rand -base64 48` |
| `CORS_ORIGINS must only list https:// public origins in production` | Remove `localhost`, `.local` and LAN origins; leave it unset unless a browser calls the API directly |
| `SITE_URL` / `SENTRY_DSN` / `UMAMI_URL` `must be an https:// URL on a public host in production` | The value still points at the development lab (localhost, `.local`, a LAN IP or a Docker service name); use the production host |
| `Paddle needs all of …` | Set the API key, webhook secret and both price ids, or none |
| `TRUST_PROXY must be the number of proxy hops` | Use `1` behind one proxy, otherwise unset |
| `SMTP_USER and SMTP_PASS must be set together` | Set both or neither |
| `RESET_PASSWORD_URL must be https:// in production` | Use the public website URL |
| `JOBTRIGGER_BACKEND_URL: must be https:// in production` | Website: use the public backend URL |

## What an agent cannot do

- Read or edit `.env`, `.env.local` or any other `.env.*` file.
- Create the store products, RevenueCat project, Paddle products or hosting
  secrets — those need the owner's accounts.
- Put a real secret in the repository, a config JSON or chat.

Give secrets to the app through the git-ignored `config/billing.json` /
`config/sentry.json` or a launcher environment variable, and to the backend
through its host's secret store or `.env` edited by you.
