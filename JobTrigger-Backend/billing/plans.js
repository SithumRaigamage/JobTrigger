/**
 * P20-10: the plans as data — the entitlements matrix of
 * docs/subscription/02-business-model.md §3, approved by the owner at
 * P20-00 (2026-11-12). One place to change a limit. `null` = unlimited.
 *
 * Clients read `limits` and `features`, never the plan name, so a limit
 * can change here without an app release.
 */
const PLANS = Object.freeze({
  free: Object.freeze({
    limits: Object.freeze({ maxCredentialsTotal: 1, maxCredentialsPerTool: 1, maxPinnedJobs: 3 }),
    features: Object.freeze({
      multiTool: false,
      backgroundWatch: false,
      homeWidget: false,
      insights: false,
    }),
  }),
  pro: Object.freeze({
    limits: Object.freeze({ maxCredentialsTotal: null, maxCredentialsPerTool: 25, maxPinnedJobs: null }),
    features: Object.freeze({
      multiTool: true,
      backgroundWatch: true,
      homeWidget: true,
      insights: true,
    }),
  }),
});

/** RevenueCat's entitlement identifier for Pro. */
const PRO_ENTITLEMENT = 'pro';

module.exports = { PLANS, PRO_ENTITLEMENT };
