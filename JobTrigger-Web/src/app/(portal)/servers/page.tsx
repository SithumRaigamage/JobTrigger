import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { loadServers } from "@/features/servers/load-servers";
import { buildPairCodes } from "@/features/servers/pair-codes";
import { ServersView } from "@/features/servers/servers-view";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "My servers" };

export default async function ServersPage() {
  const session = await requireSession();
  const result = await loadServers(session.accessToken);
  // The proxy renews tokens before rendering, so a 401 now means the session
  // ended (e.g. "sign out of all devices" from the phone).
  if (!result.ok && result.failure.kind === "auth")
    redirect("/sign-in?notice=expired&next=/servers");

  const servers = result.ok ? result.value : [];
  // NR-03: the page builds the pairing codes so the view stays synchronous.
  const pairCodes = await buildPairCodes(servers);

  return (
    <ServersView
      servers={servers}
      failure={result.ok ? null : result.failure}
      pairCodes={pairCodes}
    />
  );
}
