import type { Metadata } from "next";

import { getPaddleConfig } from "@/billing/paddle-config";
import { BillingView } from "@/features/billing/billing-view";
import { requireSession } from "@/server/guard";
import { getSubscription } from "@/server/subscription-api";

export const metadata: Metadata = { title: "Billing" };

export default async function BillingPage() {
  const session = await requireSession();
  // Best effort, like the account page: an unreadable plan just means the
  // page says buying here isn't available.
  const result = await getSubscription(session.accessToken);
  return <BillingView subscription={result.ok ? result.value : null} paddle={getPaddleConfig()} />;
}
