import type { Metadata } from "next";

import { JoinView } from "@/features/team/join-view";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Join a team" };

/**
 * US-SUB-11 AC14: the invite link. Under /account, so it needs sign-in
 * (and returns here after it), is never cached and never indexed — the link
 * carries the invite token.
 */
export default async function JoinTeamPage({
  searchParams,
}: {
  searchParams: Promise<{ token?: string | string[] }>;
}) {
  const session = await requireSession();
  const { token } = await searchParams;
  return <JoinView email={session.email} token={typeof token === "string" ? token : null} />;
}
