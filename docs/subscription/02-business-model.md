# Subscription business model

**Date:** 2026-11-12 · **Status:** proposal — every number and limit here
is a recommendation for the owner to accept or change at P20-00
([`tasks/phase-20-subscriptions.md`](../../tasks/phase-20-subscriptions.md)).
Builds on [`docs/market/competitive-analysis.md`](../market/competitive-analysis.md) §7.3.

## 1. Model in one line

**Free to start, Pro to run your whole CI estate.** A genuinely useful
free tier (one tool, one server) that competes with the free single-tool
apps, and a Pro subscription that unlocks what only JobTrigger does:
several tools, several servers, sync, and the power features.

Why freemium and not paid-only or one-time:

| Option | Verdict |
|---|---|
| Paid-only | Rejected. The market anchors at free (Jenkins View, JenBoard, GitHub Mobile). A paid-only app gets no installs to convert. |
| One-time purchase | Rejected. The backend, database and portal are ongoing costs; a one-time price doesn't cover a user who stays for years. |
| Free with ads | Rejected. Ads in a DevOps tool that holds production credentials undermine trust (Servebot is the cautionary example). |
| **Freemium subscription** | **Recommended.** Free covers the single-tool use case; Pro charges for the differentiator. |

## 2. Tiers

### Free — "One server, fully usable"

Everything needed to run one CI tool from your phone, so the free tier
earns good reviews instead of resentment.

- One CI tool at a time (Jenkins, GitHub Actions or SonarQube).
- **One** saved server/account in total.
- Full core features for that tool: browse, search, trigger with
  parameters, live status, cancel, logs, history, stages, tests.
- Foreground build status while the app is open.
- Web setup portal, within the same one-server limit (it's onboarding,
  and onboarding should convert, not block).
- Biometric app lock (a security feature — never paywalled).

### Pro — "Your whole CI estate"

- **All tools** at once (Jenkins + GitHub Actions + SonarQube, and every
  tool added later).
- **Unlimited** servers and accounts (soft cap of 25 per tool for abuse
  protection).
- Background build notifications (watch builds while the app is closed).
- Home-screen widget and unlimited pinned jobs (Free: 3 pinned).
- Build trends and the Jenkins extended views (nodes, queue, views).
- Sync across devices is free; Pro just has more to sync.
- Priority email support.

### Team — later (Phase 21+, not in this plan)

Shared servers for a team, roles, central billing. It needs an
*organisation* that owns credentials instead of a user, which is a data
model change (see [`03-technical-design.md`](03-technical-design.md) §10).
Validate demand first: count "team" requests through the existing
"Tell us" support link.

## 3. Entitlements matrix (the source for code)

This table becomes `plans.js` on the backend and `Entitlements` in the
app. Names in `code` are the keys both sides use.

| Entitlement | key | Free | Pro | Enforced where |
|---|---|---|---|---|
| Saved servers, all tools combined | `maxCredentialsTotal` | 1 | no limit | **Backend** (credential create) |
| Saved servers per tool (abuse cap) | `maxCredentialsPerTool` | 1 | 25 | **Backend** (credential create) |
| Tools usable at once | `multiTool` | false | true | **Backend** (create) + app (tool switch) |
| Background notifications | `backgroundWatch` | false | true | App |
| Home-screen widget | `homeWidget` | false | true | App |
| Pinned jobs | `maxPinnedJobs` | 3 | unlimited | App |
| Build trends, nodes, queue, views | `insights` | false | true | App |
| Core trigger / logs / history / stages / tests | — | ✓ | ✓ | never gated |
| Biometric lock, sign out everywhere, delete account | — | ✓ | ✓ | never gated |

Rule: **security and account controls are never paid features**, and
nothing the user already saved is ever deleted by a downgrade.

## 4. Pricing (recommendation)

| Plan | Price (USD tier) | Notes |
|---|---|---|
| Pro monthly | **$3.99** | Above the $0–$2 anchor, justified by multi-tool + sync. |
| Pro yearly | **$29.99** (~37% off) | Default-selected on the paywall; better retention. |
| Free trial | **7 days**, yearly plan only | Long enough to set up a second tool; short enough to decide. |
| Launch offer | Yearly at $19.99 for the first 3 months after launch | Optional; an intro offer in both stores. |

- Both stores convert the USD tier to local prices, including **LKR** for
  Sri Lanka, automatically. Review the local prices in App Store Connect
  and Play Console before launch; the auto-converted LKR price may be
  worth lowering for the home market.
- Keep two products only at launch (monthly, yearly). Fewer choices
  convert better and are simpler to test.
- Validate the price after ~200 paywall views (P20-31): if trial starts
  are under ~3% of paywall views, test a lower yearly price before
  anything else.

## 5. Where people pay

| Channel | Phase | Provider | Fee | Why |
|---|---|---|---|---|
| iOS in-app | 20 (launch) | App Store, via RevenueCat | 15% with the Small Business Program (enrol!) | Apple requires in-app purchase for digital features unlocked in the app. |
| Android in-app | 20 (launch) | Google Play, via RevenueCat | 15% on auto-renewing subscriptions | Same rule on Play. |
| Website checkout | 21 (later) | A merchant of record (Polar, Paddle or Lemon Squeezy) | ~5% + fees, varies | Laptop-first users; no store cut. |

**Sri Lanka note.** As far as I could find, Stripe doesn't let a business
based in Sri Lanka open its own account, which rules out plain Stripe
Billing for the website. A merchant of record avoids that and also
handles sales tax/VAT worldwide; Polar's docs list Sri Lanka for payouts.
Confirm the current country lists with the provider before Phase 21, and
confirm App Store / Play payouts to a Sri Lankan bank account when setting
up the store agreements. Get local tax advice on the income itself.

**RevenueCat** sits between the app and both stores: one SDK, receipt
validation, a single "is this user Pro?" answer, and webhooks to our
backend. Free until $2,500 monthly tracked revenue, so it costs nothing
until the app is earning. Alternative: StoreKit 2 + Play Billing with our
own server-side receipt validation — no vendor, but weeks more work and
more ways to get billing wrong.

## 6. Unit economics (illustrative)

| Item | Monthly cost |
|---|---|
| Apple Developer Program ($99/yr) | ~$8 |
| Google Play ($25 once) | ~$0 |
| Backend hosting (small container) | ~$5–10 (check the chosen host) |
| MongoDB Atlas | $0 on the free cluster; budget for a paid one once real users arrive |
| RevenueCat | $0 under $2,500 MTR |
| Website (Vercel hobby/pro) | $0–20 |
| **Fixed total** | **~$15–40** |

Net per Pro user after the 15% store fee: ~$3.39/month (monthly) or
~$2.12/month (yearly at $29.99). **Break-even is roughly 6–20 paying
users**, so the risk is distribution, not cost.

## 7. Metrics to watch

Defined now so P20-30 instruments them from day one:

- Paywall views → trial starts → paid conversion (trial-to-paid %).
- Monthly recurring revenue (MRR) and active subscribers (RevenueCat).
- Churn and refund rate per plan.
- Free users hitting a limit (which limit triggered the paywall).
- Tool mix of Pro users (validates which integration to build next —
  GitLab CI vs CircleCI).

## 8. Decisions for the owner (P20-00)

1. Accept the Free/Pro split in §2–3, or move items between them.
2. Prices and trial length (§4).
3. RevenueCat vs. building native billing (§5).
4. Analytics/crash tool (unblocks G3 in the workspace analysis).
5. Email provider for password reset and billing notices (G2, G5).
6. Whether the web portal stays free within limits (recommended) or is
   Pro-only.
