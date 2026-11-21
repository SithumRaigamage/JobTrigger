# M-23 — Team plan: Paddle prices and a sandbox purchase (US-SUB-11, 1.1)

> Added 2026-11-20 with Phase 28. Back to the [index](README.md).

**Source:** P28-04 (`tasks/phase-28-team-plan.md`), US-SUB-11.
**Why only you:** the Paddle account, its products and the staging secrets
are yours.

1. Paddle (sandbox first): on the JobTrigger Pro product add two per-seat
   prices — **$6.99 per month** and **$69.90 per year** — with quantity
   allowed from 2 to 100.
2. In staging's secret manager set `PADDLE_PRICE_TEAM_MONTHLY`,
   `PADDLE_PRICE_TEAM_YEARLY` (the two price ids) and `TEAM_PLAN_ENABLED=true`.
3. On the website (Mac browser): Account → Team → create a team, invite a
   second account, then Billing → Team → buy 3 seats with Paddle's sandbox
   card. Accept the invite from the second account's email.
4. On the iPhone (`scripts/run-on-iphone.sh`), signed in as the second
   account: Profile → Subscription says "Pro through <team>"; Settings →
   Team servers lists the server you shared → **Use**.
5. Unshare it on the website and pull to refresh on the phone: it disappears
   and your own server is active again.

**Evidence:** the team's seats show 3 after the webhook, and the member's
plan reads "Pro through <team>".
