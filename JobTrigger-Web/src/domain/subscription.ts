/*
 * What the account page knows about the user's plan: the website's view of
 * GET /api/subscription (docs/api-reference.md), mirroring the app's
 * SubscriptionSnapshot. Display only: the website never decides what a plan
 * allows (the backend enforces it) and never sells (Phase 21).
 */

export type SubscriptionState =
  "none" | "trialing" | "active" | "grace" | "billingIssue" | "cancelled" | "expired";

/** Where it was bought. */
export type SubscriptionSource = "appStore" | "playStore" | "web" | "promo" | "admin";

export type Subscription = {
  plan: "free" | "pro";
  /** False: the backend treats everyone as Pro and the plan section is hidden. */
  billingEnabled: boolean;
  state: SubscriptionState;
  source: SubscriptionSource | null;
  /** ISO date-time the current period ends, if any. */
  periodEnd: string | null;
  willRenew: boolean;
  /** True when Paddle's portal can manage it (a web subscription). */
  manageOnWeb: boolean;
  limits: {
    maxCredentialsTotal: number | null;
    maxCredentialsPerTool: number | null;
    maxPinnedJobs: number | null;
  };
  features: {
    multiTool: boolean;
    backgroundWatch: boolean;
    homeWidget: boolean;
    insights: boolean;
  };
};
