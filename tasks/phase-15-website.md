# Phase 15 — Website (epic WEB)

Goal: build the JobTrigger website in a new `JobTrigger-Web/` Next.js
project — the public marketing pages and the signed-in setup portal from
epic WEB ([`docs/user-stories/web/17-website.md`](../docs/user-stories/web/17-website.md)),
to the designs approved on 2026-10-24 in [`UI-UX/Web/`](../UI-UX/Web/README.md).
The site launches with the pre-launch ("coming soon") pages, driven by the
feature-status list (US-WEB-22).

Promoted by the owner on 2026-10-26 ("Approved Next.js and make the
project JobTrigger-Web/ … Create a task phase for the website … Decide
the website's code conventions"), on branch `feat/website`. Conventions:
[`docs/web-architecture.md`](../docs/web-architecture.md).

**Workflow (owner request 2026-10-26, "step by step and approval gate on
plan and design").** Each task: a short plan + design note naming its
approved screen → owner approval → implement → `npm run check` (and
`npm run e2e` for portal flows) → owner review → one commit, pushed.

**Definition of Done.** `npm run check` clean (Prettier, ESLint, `tsc`,
Vitest, `next build`), tests exist for new `server/` and `domain/` code,
and every page matches its `UI-UX/Web/screens/` render at 1440 px and
works at 360 px. GitHub Actions is off (owner's choice), so these local
runs are the merge gate.

## Decisions approved with the phase (2026-10-26)

1. **Next.js 16 (App Router) + TypeScript**, in `JobTrigger-Web/`, added
   to `CLAUDE.md` §3 as a Website row.
2. **Tailwind CSS v4**, with the `UI-UX/Web` tokens as CSS variables.
3. **`zod`** for validation and **`iron-session`** for the encrypted
   session cookie.
4. **Vercel first, Docker later.** The portal needs the backend at a
   public `https://` URL to go live on Vercel; no backend deployment
   exists yet (`config/prod.json` is a placeholder). That blocks P15-22's
   portal launch, not development — locally the site runs against the
   local backend.
5. **One set of pages, two looks.** The v4 designs (finished product)
   and the pre-launch designs (screens 18–25) are one set of components
   whose badges and disabled actions read `feature-status.ts`.

## Tasks

### Foundation

- [x] P15-00 Docs: `CLAUDE.md` §3 Website row, this phase file, the
      Phase 15 row in `tasks/README.md`, `docs/web-architecture.md`.
- [x] P15-01 Scaffold `JobTrigger-Web/`: Next.js 16, TypeScript strict,
      Tailwind v4, ESLint, Prettier, Vitest, Playwright, `.nvmrc`,
      `npm run check` / `npm run e2e`, `src/server/config.ts`, README;
      `docs/dev-setup.md` gains a "Website" terminal.
- [x] P15-02 Design tokens (light/dark), Inter + JetBrains Mono via
      `next/font`, root layout, base primitives (`Button`, `Card`,
      `Container`).
- [x] P15-03 Security baseline (WEB-B1–B3): HSTS, strict CSP,
      `frame-ancestors 'none'`, `no-store` on portal routes, no secrets in
      logs or URLs.
- [x] P15-04 Feature-status list `src/content/feature-status.ts`
      (US-WEB-22) seeded from the epic's availability table, plus
      `StatusBadge` and `DisabledAction`, with unit tests.
- [x] P15-05 Marketing header and footer (designs 15, 16, pre-launch
      24, 25).

### Marketing

- [x] P15-06 Home (designs 01 / 18; US-WEB-01, 02). Built in four commits
      (06a hero + tool strip, 06b timeline, 06c setup band + trust,
      06d download).
- [x] P15-07 Features (designs 02 / 19; US-WEB-03).
- [x] P15-08 Integrations (designs 03 / 20; US-WEB-04).
- [x] P15-09 Security (design 04; US-WEB-05).
- [x] P15-10 Privacy policy, terms, support (designs 05, 06; US-WEB-06).
      Placeholders stay bracketed until the owner supplies them.
- [x] P15-11 Changelog (designs 07 / 21; US-WEB-08).
- [x] P15-12 Link previews and search (US-WEB-07): metadata, Open Graph
      images, `sitemap.xml`, `robots.txt` (portal disallowed).

### Setup portal

- [x] P15-13 Server layer: `backend-client.ts` (`x-auth-token`,
      `x-request-id`), `AppFailure` + `failureMessage()` mirroring the
      app, `zod` response schemas, `iron-session` session, refresh-once
      on 401, secret masking. Unit tests for every branch.
- [x] P15-14 Sign in and sign up (designs 08, 09; US-WEB-10).
- [x] P15-15 Portal shell: sidebar (design 17), auth guard, sign out,
      30-minute idle timeout (US-WEB-20).
- [x] P15-16 My servers, secrets masked (design 10; US-WEB-11).
- [x] P15-17 Add a Jenkins server, GitHub account or SonarQube server,
      with "How do I get this?" help and the "Now open the app" page
      (designs 11 / 22, 13 / 23; US-WEB-12, 13, 14, 16, 17).
- [x] P15-18 Edit and delete a server (design 12; US-WEB-15).
- [x] P15-19 Choose the default server (US-WEB-18).
- [x] P15-20 Account: change password, sign out everywhere, delete
      account (design 14; US-WEB-20, 21).

### Close-out

- [x] P15-21 Accessibility and responsive pass (WEB-B4, B5) and
      Playwright end-to-end specs for sign-in → add server → saved.
- [x] P15-22 (prepared; **owner action**: connect the Vercel project) Vercel deployment: project setup, environment variables,
      `docs/deployment.md` "Website" section. Marketing can go live
      first; the portal is **blocked** until the backend has a public
      `https://` URL.
- [x] P15-23 Docker image (`output: "standalone"`) to run next to the
      backend, documented in `docs/deployment.md`; mark the phase done in
      `tasks/README.md`.
- [ ] P15-24 Store links and QR code on Home's download section: set
      `storeLinks` in `site-links.ts` and add a QR code (a pre-built SVG,
      or a QR library — needs approval). **Blocked** on the store listings
      in `release-checklist.md`. `store-links.test.ts` fails if
      `app-stores` goes `live` before the URLs are set.

## Out of scope

- **US-WEB-19 Test connection.** Needs a new backend endpoint (backend
  track); the button ships disabled via its `soon` status.
- **Notify-me email signup.** Stays in `backlog.md` (decided 2026-10-24).
- **Masked-list and per-session revoke backend endpoints.** Flagged for
  the backend track (NFR-SEC-05); the site masks in its server layer and
  uses `logout-all` until then.

## Outcome (2026-10-26)

P15-00…P15-23 built on `feat/website`, one commit per task (P15-06 in
four), each through the local gate (`npm run check` + `npm run e2e`).
Done on owner instruction ("proceed with all, do not stop at checks, I
will do a final review"), so the per-task approval stops of the workflow
note above were folded into that final review.

Still open — owner actions, not development:

- **Vercel**: connect the project (P15-22, `docs/deployment.md` "Website").
- **Backend deployment** at an `https://` URL, then set
  `JOBTRIGGER_BACKEND_URL` + `SESSION_SECRET` to open the portal.
- **Placeholders** in `src/content/site-details.ts` (company name,
  security/privacy emails, reply days, backup retention, legal date) and
  legal review of the privacy policy and the drafted terms.
- **P15-24** store links and QR code, once the app is listed.

## Decisions confirmed by the owner (2026-10-26)

Taken during the unattended run, then put to the owner one by one; all
kept as built:

1. One strict nonce CSP on every page; `cacheComponents` off, no page
   caching (P15-03).
2. Plain http to the backend only for loopback and single-label container
   service names; every other host needs https (P15-13, P15-23).
3. The drafted Terms of use stays, marked for legal review (P15-10).
4. The setup band's kicker is `#EFF6FF` (the design's `#DBEAFE` fails AA)
   (P15-06c).
5. `github-actions` (beta) and `github-runs` (soon) stay separate (P15-08).
6. A blank token on edit is left out of the update; the site never reads
   the saved secret (P15-18; US-WEB-15 updated to match).
7. Error wording is the app's, not the mock-ups' (P15-00, P15-14+).
8. Kept differences from the mock-ups: the confirm-password field, the
   compact phone sidebar, the sign-up "coming soon" line, and the header
   not sticky on phones.
