import type { Metadata } from "next";

import { getPaddleConfig } from "@/billing/paddle-config";
import { BillingView } from "@/features/billing/billing-view";
import { requireSession } from "@/server/guard";
import { getSubscription } from "@/server/subscription-api";
import { getTeam } from "@/server/team-api";

export const metadata: Metadata = { title: "Billing" };

export default async function BillingPage() {
  const session = await requireSession();
  // Best effort, like the account page: an unreadable plan just means the
  // page says buying here isn't available.
  const [result, teamResult] = await Promise.all([
    getSubscription(session.accessToken),
    getTeam(session.accessToken),
  ]);
  // US-SUB-11: the team section, only for an owner while teams are on.
  const team = teamResult.ok && teamResult.value.available ? teamResult.value.team : null;
  return (
    <BillingView
      subscription={result.ok ? result.value : null}
      paddle={getPaddleConfig()}
      team={team}
    />
  );
}
