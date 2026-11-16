import type { Metadata } from "next";

import { AccountView } from "@/features/account/account-view";
import { requireSession } from "@/server/guard";
import { getSubscription } from "@/server/subscription-api";

export const metadata: Metadata = { title: "Account" };

export default async function AccountPage() {
  const session = await requireSession();
  // Best effort: the plan card is extra, so an unreachable backend, an old
  // backend with no /api/subscription, or billing being off just leaves it
  // out. The proxy has renewed the token already, as on the servers page.
  const result = await getSubscription(session.accessToken);
  const subscription = result.ok && result.value.billingEnabled ? result.value : null;
  return <AccountView email={session.email} subscription={subscription} />;
}
