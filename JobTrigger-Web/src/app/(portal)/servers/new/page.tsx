import type { Metadata } from "next";

import { isToolReleased, releasedTools } from "@/content/release";
import type { Tool } from "@/domain/credentials";
import { AddServerView } from "@/features/servers/add-server-view";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Add a server" };

const isTool = (value: unknown): value is Tool =>
  value === "jenkins" || value === "github" || value === "sonarqube";

export default async function AddServerPage({ searchParams }: PageProps<"/servers/new">) {
  await requireSession();
  const { tool } = await searchParams;
  // Only a tool this release ships can be chosen (release/tools.json); a link
  // to any other lands on the first one that is.
  const chosen = isTool(tool) && isToolReleased(tool) ? tool : (releasedTools()[0] ?? "jenkins");
  return <AddServerView tool={chosen} />;
}
