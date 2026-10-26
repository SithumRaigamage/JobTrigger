import type { Metadata } from "next";

import type { Tool } from "@/domain/credentials";
import { AddServerView } from "@/features/servers/add-server-view";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Add a server" };

const isTool = (value: unknown): value is Tool =>
  value === "jenkins" || value === "github" || value === "sonarqube";

export default async function AddServerPage({ searchParams }: PageProps<"/servers/new">) {
  await requireSession();
  const { tool } = await searchParams;
  return <AddServerView tool={isTool(tool) ? tool : "jenkins"} />;
}
