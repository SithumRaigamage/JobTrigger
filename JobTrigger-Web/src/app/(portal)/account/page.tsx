import type { Metadata } from "next";

import { AccountView } from "@/features/account/account-view";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Account" };

export default async function AccountPage() {
  const session = await requireSession();
  return <AccountView email={session.email} />;
}
