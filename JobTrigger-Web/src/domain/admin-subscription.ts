/*
 * One account as the owner's subscription console sees it: the derived
 * plan plus each billing source, so a grant can be told apart from a store
 * or web subscription the customer paid for (admin-subscriptions-api.ts,
 * GET /api/admin/subscriptions).
 */

import type { SubscriptionSource, SubscriptionState } from "./subscription";

/** One source's own state (grant, store, web, student), or null when unused. */
export type AdminBillingSource = {
  plan: "free" | "pro";
  state: SubscriptionState;
  source: SubscriptionSource | null;
  periodEnd: string | null;
  willRenew: boolean;
};

export type AdminSubscription = {
  userId: string;
  email: string;
  /** The plan the backend would enforce right now. */
  plan: "free" | "pro";
  state: SubscriptionState;
  source: SubscriptionSource | null;
  periodEnd: string | null;
  willRenew: boolean;
  sources: {
    store: AdminBillingSource | null;
    web: AdminBillingSource | null;
    grant: AdminBillingSource | null;
    student: AdminBillingSource | null;
  };
  createdAt: string | null;
};

/** The console's plan filter. */
export type AdminPlanFilter = "all" | "pro" | "free";
