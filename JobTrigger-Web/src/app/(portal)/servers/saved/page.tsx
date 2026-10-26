import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { credentialName } from "@/domain/tools";
import { loadServers } from "@/features/servers/load-servers";
import { SavedView } from "@/features/servers/saved-view";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Saved" };

/** After saving: finds the new server by id (only ids travel in the URL). */
export default async function SavedPage({ searchParams }: PageProps<"/servers/saved">) {
  const session = await requireSession();
  const { tool, id } = await searchParams;
  const result = await loadServers(session.accessToken);
  if (!result.ok && result.failure.kind === "auth") redirect("/sign-in?notice=expired");

  const servers = result.ok ? result.value : [];
  const saved = servers.find((server) => server.tool === tool && server.id === id);
  if (!saved) redirect("/servers");

  return (
    <SavedView
      name={credentialName(saved)}
      others={servers.filter((server) => server !== saved).map(credentialName)}
    />
  );
}
