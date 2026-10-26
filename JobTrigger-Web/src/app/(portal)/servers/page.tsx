import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { loadServers } from "@/features/servers/load-servers";
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

  return (
    <ServersView
      servers={result.ok ? result.value : []}
      failure={result.ok ? null : result.failure}
    />
  );
}
