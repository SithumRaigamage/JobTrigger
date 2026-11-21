import type { Metadata } from "next";

import { TeamView, type ShareableServer } from "@/features/team/team-view";
import { listJenkins } from "@/server/credentials-api";
import { requireSession } from "@/server/guard";
import { getTeam } from "@/server/team-api";

export const metadata: Metadata = { title: "Team" };

/** US-SUB-11 AC12. */
export default async function TeamPage() {
  const session = await requireSession();
  const result = await getTeam(session.accessToken);
  // An unreachable backend reads like "teams off": nothing on this page can
  // work without it, and the copy says to come back.
  const state = result.ok ? result.value : { available: false as const };
  let servers: ShareableServer[] = [];
  if (state.available && state.team?.role === "owner") {
    const jenkins = await listJenkins(session.accessToken);
    servers = jenkins.ok
      ? jenkins.value.map((s) => ({ id: s.id, serverName: s.name, jenkinsURL: s.url }))
      : [];
  }
  return <TeamView state={state} servers={servers} />;
}
