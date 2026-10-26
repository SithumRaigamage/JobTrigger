# Website architecture — `JobTrigger-Web/`

Conventions for the Next.js website in epic WEB
([`user-stories/web/17-website.md`](user-stories/web/17-website.md)),
approved 2026-10-26 (P15-00). The Flutter documents
([`architecture.md`](architecture.md), [`state-management.md`](state-management.md))
don't apply here. The workflow rules in `CLAUDE.md` §8–9 do: plan first,
approval gates, conventional commits, no `.env` access.

## 1. What it is

Two parts in one Next.js app:

1. **Marketing** — public pages (home, features, integrations, security,
   privacy, support, changelog).
2. **Setup portal** — signed-in pages where a user adds Jenkins, GitHub
   and SonarQube details on a laptop, so the phone app picks them up from
   the backend.

The website talks only to `JobTrigger-Backend`. It never calls Jenkins,
GitHub or SonarQube.

## 2. The rule everything else follows

**The browser never holds a full secret or a JobTrigger token.** The
backend's credential list endpoints return secrets decrypted in full,
because the app needs them. So:

- Every backend call is made by the Next.js server (server components,
  server actions, route handlers) — a backend-for-frontend (BFF). Browser
  JavaScript never calls the backend, so the backend needs no CORS entry
  for the site.
- The access and refresh tokens live in an encrypted `iron-session`
  cookie: `HttpOnly`, `Secure`, `SameSite=Lax`. Never `localStorage`,
  never readable by JS.
- Secrets are masked on the server (`••••` + last 4 characters) before any
  data reaches a component. The full value never appears in HTML, the RSC
  payload, or a server-action response.
- The backend still receives `x-auth-token: <token>`, exactly like the app
  (not `Authorization: Bearer` — see [`api-reference.md`](api-reference.md)).

## 3. Stack (locked — don't substitute without discussion)

| Concern | Choice | Notes |
|---|---|---|
| Framework | Next.js 16, App Router | Server components by default |
| Language | TypeScript, `strict: true` | No `any` without a comment saying why |
| Styling | Tailwind CSS v4 | Tokens in `src/app/globals.css` (§6) |
| Validation | `zod` | Form input and every backend response |
| Session | `iron-session` | Encrypted cookie, server only |
| Unit tests | Vitest + Testing Library | Mandatory for `src/server/` and `src/domain/` |
| End-to-end | Playwright | Against a fake backend, never a real one |
| Lint / format | ESLint (`eslint-config-next`), Prettier + `prettier-plugin-tailwindcss` | |
| Runtime | Node 24, npm | Same as the backend; pinned in `.nvmrc` and `engines` |
| Hosting | Vercel first, Docker (`output: "standalone"`) later | P15-22, P15-23 |

No second HTTP client (use the built-in `fetch`), no client-side data
library (React Query, SWR), no state library (Redux, Zustand), no UI kit,
no MDX. Flag a task that seems to need one.

## 4. Folder structure

```text
JobTrigger-Web/
  src/
    app/                   Routes only — thin. Compose views, nothing else.
      (marketing)/         Public pages, top header layout
      (portal)/            Signed-in pages, sidebar layout, auth guard
      globals.css          Tailwind import + design tokens
    features/              One folder per area
      marketing/           Page sections (hero, timeline, tool cards …)
      auth/                Sign-in / sign-up forms + actions
      servers/             List, add, edit, delete, set default
      account/             Change password, sign out everywhere, delete
    components/            Shared UI: Button, StatusBadge, DisabledAction …
    domain/                Plain TS: entities, Result<T, AppFailure>, copy
    server/                `import "server-only"` — backend client, session,
                           refresh, masking, config. The ONLY backend caller.
    content/               feature-status.ts (US-WEB-22), changelog entries
    proxy.ts               Per-request CSP nonce + no-store (headers only)
    security-headers.ts    Header builders shared with next.config.ts
  tests/e2e/               Playwright specs + fake backend
```

Feature-first, as in the app: everything for "servers" lives under
`features/servers/`, not in flat `components/` or `actions/` folders.
`components/` is only for pieces used by two or more features.

## 5. Layers and rules

```text
app/ (routes) → features/ (views + server actions) → server/ (backend)
                         ↘ domain/ (types, failures) ↙
```

- **`server/` is the only backend caller.** Every file starts with
  `import "server-only"`, so importing it from a client component fails
  the build.
- **Components never call `fetch`** and never inspect HTTP status codes.
  They receive `Result` values and render `AppFailure` copy.
- **Server components by default.** Add `"use client"` only for
  interactivity (forms with live validation, menus, the idle timer), and
  pass client components only masked, already-shaped data.
- **No business logic in components.** A condition that decides *what*
  happens goes in a server action or `server/`; components decide *how* it
  looks.
- **Every state-changing action is a server action** (or a `POST` route
  handler), validated with `zod` on the server, protected by the
  `SameSite` cookie plus Next's server-action origin check. No mutations
  via `GET`.
- **Signed-in responses send `Cache-Control: no-store`** (see "Security
  headers").

### Errors

`server/` maps every backend outcome to a `Result<T, AppFailure>`; it
never throws a raw `fetch` error upward. `AppFailure` is a TypeScript
discriminated union mirroring the backend-relevant subset of the app's
sealed class (`JobTrigger-Frontend/lib/core/error/app_failure.dart`), with
the same names and the same copy, so a problem reads the same on both:

| `AppFailure` | When | Copy (verbatim from the app) |
|---|---|---|
| `NetworkFailure` | Backend unreachable, timeout | "Can't reach the server. Check your connection and try again." |
| `AuthFailure` | 401 (after the refresh attempt in "Session and refresh") | "Your credentials were rejected. Please check them and try again." |
| `NotFoundFailure` | 404 (e.g. a server deleted from the phone) | "That couldn't be found — it may have been removed." |
| `RejectedRequestFailure` | 400 with the backend's `{ message }` ("Invalid credentials", "User already exists", "Current password is incorrect") | The backend's message (safe since AUD-06/AUD-65) |
| `ServerFailure` (429) | Backend rate limiter | "Too many attempts. Please wait a few minutes and try again." |
| `ServerFailure` | Other 4xx/5xx, carries `x-request-id` | "Something went wrong on the server (HTTP *n*). Reference: *id*" |
| `UnexpectedResponseFailure` | Response fails `zod` parsing | "The server sent a response the app didn't understand. …" |
| `UnknownFailure` | Anything else | "Something unexpected happened. Please try again." |

`RateLimitFailure` (GitHub-only in the app) and the Jenkins-only kinds
(`PermissionFailure`, `JobDisabledFailure`) aren't mirrored: the website
never calls GitHub or Jenkins. A wrong password is a backend `400
"Invalid credentials"`, so it surfaces as `RejectedRequestFailure`, as in
the app.

The copy lives in `domain/app-failure.ts` as one `failureMessage()`
function; components never write their own error strings. A `zod` parse
failure is an `UnexpectedResponseFailure`, never a crash, and its details
go to server logs only (NFR-SEC-04).

### Session and refresh

- The access token lasts 15 minutes, the refresh token 30 days (AUD-26).
- On a backend 401, `server/` calls `POST /api/auth/refresh` once, saves
  the new pair in the session, and replays the request. A refresh 401
  clears the session and redirects to `/sign-in`; any other refresh
  failure keeps the session (NFR-SEC-07), as in the app.
- Idle timeout (US-WEB-20): the session stores a last-activity time;
  after 30 minutes the next request redirects to `/sign-in`.

### Security headers (P15-03, WEB-B1–B3)

One strict policy on every page (owner decision 2026-10-26):

- **CSP with a per-request nonce** (`src/proxy.ts`): `script-src 'self'
  'nonce-…' 'strict-dynamic'`, `style-src 'self' 'nonce-…'`, no
  `'unsafe-inline'`, `frame-ancestors 'none'`, `form-action 'self'`,
  `object-src 'none'`, `upgrade-insecure-requests` in production.
  `'unsafe-eval'` in `next dev` only.
- **Static headers on every response** (`next.config.ts`): HSTS two years
  with `includeSubDomains` (no `preload` — a separate domain decision),
  `nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`,
  `Permissions-Policy`, `Cross-Origin-Opener-Policy`; no `X-Powered-By`.
- **`no-store`** explicitly on `/sign-in`, `/sign-up`, `/servers`,
  `/account` (`NO_STORE_PATH_PREFIXES` in `src/security-headers.ts`; add
  new portal paths there).
- The header builders live in `src/security-headers.ts`, outside
  `server/`, because `next.config.ts` can't import `server-only`.
- **No inline `style` attributes, so no `next/image`.** It always adds
  `style="color:transparent"`, which the CSP blocks (found in P15-06a).
  Use `components/static-image.tsx` with a static import from
  `src/assets/`; it keeps the intrinsic size, so layout doesn't shift. The
  same applies to any `style={…}` prop: use Tailwind classes.

**Why every page renders per request, and `cacheComponents` is off.** The
App Router emits inline scripts on every page, so a CSP without
`'unsafe-inline'` needs a nonce, and a nonce must be new per response.
Measured on 2026-10-26 (production build, Chromium):

| Setup | CSP violations | Page hydrates |
|---|---|---|
| Experimental SRI, `script-src 'self'`, static | 13 | no |
| Nonce, `cacheComponents` on, static | 21 | no |
| Nonce, `cacheComponents` on, dynamic part in `<Suspense>` | 10 | no |
| **Nonce, `cacheComponents` off, root layout awaits `connection()`** | **0** | **yes** |

Consequences: no static pages or ISR, and Next sends `Cache-Control:
private, no-store` on every page — correct, since a cached page would
replay its nonce. Don't re-enable `cacheComponents` or add `'unsafe-inline'`
without revisiting this table; `tests/e2e/security-headers.spec.ts` fails
on any CSP violation.

**WEB-B3 (no secrets in URLs or logs).** Secrets travel only in
server-action bodies, never query strings or route params; `server/`
never logs request bodies, tokens or backend responses; error pages show
`AppFailure` copy only. Enforced by tests from P15-13 on.

## 6. Styling

- Design tokens from [`UI-UX/Web/README.md`](../UI-UX/Web/README.md#design-tokens)
  are CSS variables in `globals.css`, exposed to Tailwind via `@theme`.
  Light and dark both set the same variable names.
- **No raw hex values or arbitrary colour classes** (`bg-[#2563EB]`) in
  components — only token names (`bg-accent`, `text-status-running`).
- Inter and JetBrains Mono via `next/font` (self-hosted at build time, no
  request to Google at runtime — keeps WEB-B2's CSP strict).
- Status is never shown by colour alone (badges always carry their label).
- Every page works from 360 px wide (WEB-B4) and meets WCAG 2.1 AA
  (WEB-B5).

## 7. Feature status (US-WEB-22)

`src/content/feature-status.ts` is a typed list: each feature has an id
and a status of `live`, `beta`, `soon` or `planned`, seeded from the
epic's "Feature availability" table. No page hard-codes "Coming soon";
it renders `<StatusBadge feature="…" />` or `<DisabledAction feature="…">`.
Flipping one status and redeploying updates every page. A feature becomes
`live` only when its stories are done in `tasks/README.md`.

The pre-launch designs (`*Soon.dc.html`, screens 18–25) and the v4
designs show the same pages at different statuses — they're one set of
components driven by this list, not two copies of each page.

## 8. Configuration

Read and validated with `zod` in `src/server/config.ts` only; the app
fails at startup if anything is missing. Nothing secret is ever
`NEXT_PUBLIC_*`.

| Variable | Used for |
|---|---|
| `JOBTRIGGER_BACKEND_URL` | Backend base URL (`http://127.0.0.1:5001` locally); must be `https://` in production |
| `SESSION_SECRET` | `iron-session` encryption key, 32+ characters |
| `SITE_URL` | Canonical URL for link previews and the sitemap (US-WEB-07); defaults to `http://localhost:3000` |

All three are read at runtime on the server. `SITE_URL` is deliberately
not `NEXT_PUBLIC_*`: those are inlined at build time, which would tie one
Docker image (P15-23) to one environment. Validation runs on first use,
not at import, so `next build` works without the portal's secrets.

Per `CLAUDE.md` §8, these are documented here and in
`JobTrigger-Web/README.md`, not in an example env file.

## 9. Naming

| Kind | Pattern | Example |
|---|---|---|
| Route component | `SomePage` (default export of `page.tsx`) | `ServersPage` |
| Composed component | `SomeView` | `ServerListView` |
| Small shared component | Plain noun | `StatusBadge`, `Button` |
| Server action | `verbNounAction` | `addJenkinsServerAction` |
| Server module | `kebab-case.ts` | `server/backend-client.ts` |
| Files | `kebab-case.tsx` | `server-list-view.tsx` |

## 10. Checks (the merge gate)

GitHub Actions is off by the owner's choice, so local checks gate merges:

```bash
cd JobTrigger-Web
npm run check   # prettier --check, eslint, tsc --noEmit, vitest run, next build
npm run e2e     # Playwright, for tasks touching portal flows
```

A task is done when `npm run check` is clean, its tests exist and pass,
and its pages match their `UI-UX/Web/screens/` render at 1440 px and
360 px.

**Playwright: never wait for `networkidle`.** Next's router never
finishes reading its `<Link>` prefetch responses, so the network never
looks idle and the wait times out (measured in P15-05; the server answers
those requests in ~2 ms). Wait for the thing the test checks instead:
`document.fonts.ready`, a visible element, or `expect.poll`.
