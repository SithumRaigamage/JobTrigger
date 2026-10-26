# JobTrigger-Web

The JobTrigger website: public marketing pages and the signed-in setup
portal (epic WEB, Phase 15). Next.js 16 (App Router) + TypeScript +
Tailwind CSS v4.

Read [`docs/web-architecture.md`](../docs/web-architecture.md) before
changing code — it holds the stack, folder layout, layering rules and the
"no secret ever reaches the browser" rule. Tasks:
[`tasks/phase-15-website.md`](../tasks/phase-15-website.md). Designs:
[`UI-UX/Web/`](../UI-UX/Web/README.md).

## Setup

Requires Node 24 (`.nvmrc`) and npm.

```bash
cd JobTrigger-Web
npm install
npx playwright install chromium   # once, for npm run e2e
npm run dev                       # http://localhost:3000
```

The portal talks to a locally running `JobTrigger-Backend` (see
[`docs/dev-setup.md`](../docs/dev-setup.md)). Marketing pages need nothing
else.

## Environment variables

Read and validated only in `src/server/config.ts`, on first use.

| Variable                 | Required       | Example (local)         | Notes                                                                                                                    |
| ------------------------ | -------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `JOBTRIGGER_BACKEND_URL` | For the portal | `http://127.0.0.1:5001` | `https://` in production, except loopback and container service names (`http://backend:5001`)                            |
| `SESSION_SECRET`         | For the portal | 32+ random characters   | Encrypts the session cookie. Generate with `node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"` |
| `SITE_URL`               | No             | `http://localhost:3000` | Canonical URL for link previews and the sitemap                                                                          |

Set them in your shell or your hosting provider's settings. Nothing
secret is ever `NEXT_PUBLIC_*`.

## Scripts

| Script                            | What it does                                                                               |
| --------------------------------- | ------------------------------------------------------------------------------------------ |
| `npm run dev`                     | Dev server on port 3000                                                                    |
| `npm run dev:portal`              | Dev server with the portal on, against the local backend (`docs/dev-setup.md`)             |
| `npm run build` / `npm start`     | Production build / serve it                                                                |
| `npm run lint`                    | ESLint                                                                                     |
| `npm run typecheck`               | `next typegen` + `tsc --noEmit`                                                            |
| `npm run format` / `format:check` | Prettier (with Tailwind class sorting)                                                     |
| `npm test` / `test:watch`         | Vitest unit tests (`src/**/*.test.ts(x)`)                                                  |
| `npm run e2e`                     | Playwright on a production build (port 3100), desktop and 360 px                           |
| `npm run check`                   | format check → lint → typecheck → test → build. **The merge gate** (GitHub Actions is off) |

## Deploying

Vercel and Docker: see [`docs/deployment.md`](../docs/deployment.md) "Website". Without the two portal variables the site serves its marketing pages and the portal says it's unavailable.

## Notes

- `AGENTS.md` is written by `next dev` (it points coding agents at the
  docs bundled in `node_modules/next/dist/docs/`); keep it committed.
- `unrs-resolver`'s postinstall is left unapproved under npm's
  `allow-scripts`: it only downloads a fallback native binary, and the
  platform binary already installs as an optional dependency.
