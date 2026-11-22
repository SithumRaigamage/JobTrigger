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
  /** US-PROMO-01: the redeemed code, for a promo source. */
  productId?: string | null;
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
    /** US-PROMO-01: a redeemed promo or voucher code. */
    promo?: AdminBillingSource | null;
  };
  createdAt: string | null;
};

/**
 * US-PROMO-05: one configured code and how much of it is used. `redemptions`
 * is null for a checkout discount, whose redemptions Paddle counts.
 */
export type AdminPromoCode = {
  code: string;
  kind: "pro" | "checkout";
  days: number | null;
  redemptions: number | null;
  maxRedemptions: number | null;
  remaining: number | null;
  expiresAt: string | null;
  expired: boolean;
};

/** One page of the console: the accounts, and every code configured. */
export type AdminSubscriptionsPage = {
  items: AdminSubscription[];
  codes: AdminPromoCode[];
};

/** The console's plan filter. */
export type AdminPlanFilter = "all" | "pro" | "free";
