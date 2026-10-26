import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";

import { failureMessage } from "@/domain/app-failure";
import { EditServerView } from "@/features/servers/edit-server-view";
import { loadServers } from "@/features/servers/load-servers";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Edit server" };

export default async function EditServerPage({ params }: PageProps<"/servers/[tool]/[id]">) {
  const session = await requireSession();
  const { tool, id } = await params;
  const result = await loadServers(session.accessToken);
  if (!result.ok && result.failure.kind === "auth") redirect("/sign-in?notice=expired");

  const credential = result.ok
    ? result.value.find((server) => server.tool === tool && server.id === decodeURIComponent(id))
    : undefined;
  if (!credential) {
    // US-WEB-15 "Not found": e.g. deleted in the app meanwhile.
    return (
      <div role="alert" className="flex flex-col items-start gap-3">
        <h1 className="text-h3">Server not found</h1>
        <p className="text-muted">
          {failureMessage(result.ok ? { kind: "notFound" } : result.failure)}
        </p>
        <Link href="/servers" className="font-semibold">
          Back to my servers →
        </Link>
      </div>
    );
  }
  return <EditServerView credential={credential} />;
}
