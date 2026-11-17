# M-13 — Website go-live

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** P15-22, P15-24 (`tasks/phase-15-website.md`), PE-03
(`tasks/phase-emergency.md`).
**Why only you:** it needs your Vercel account, and the store links don't
exist until the stores are live ([M-08](M-08-app-store-connect.md)/[M-09](M-09-play-console.md)/[M-11](M-11-public-release.md)).

1. Mac: connect the Vercel project and its environment variables
   (`docs/deployment.md`, "Website"). Marketing can go live first; the portal
   waits for the public `https://` backend ([M-14](M-14-production-backend.md)).
2. Fill `site-details.ts` (company name, privacy and security emails, reply
   days, backup retention, last-updated date) — `launch-readiness.test.ts`
   lists what's missing.
3. Once the listings are live, set `storeLinks` in `site-links.ts` and add the
   QR code (a pre-built SVG, or a QR library — needs your approval).

**Evidence:** the live site.
