import type { PaddleConfig } from "@/billing/paddle-config";
import type { Subscription } from "@/domain/subscription";

/** What the billing page offers this user right now (P20-83). */
export type BillingMode =
  /** Billing is off, web checkout isn't set up, or the plan couldn't be read. */
  | "unavailable"
  /** Free: buy Pro with Paddle. */
  | "upgrade"
  /** Pro from the website: Paddle's customer portal. */
  | "manage"
  /** Pro from a store: managed there; the website sells nothing on top. */
  | "store"
  /** Pro by promotion or grant: nothing to buy or manage. */
  | "other";

export function billingMode(
  subscription: Subscription | null,
  paddle: PaddleConfig | null,
): BillingMode {
  if (!subscription || !subscription.billingEnabled || !paddle) return "unavailable";
  if (subscription.plan === "free") return "upgrade";
  if (subscription.source === "web") return "manage";
  if (subscription.source === "appStore" || subscription.source === "playStore") return "store";
  return "other";
}
