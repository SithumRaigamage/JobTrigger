import type { Metadata } from "next";
import { connection } from "next/server";
import { notFound } from "next/navigation";

import { SupportDetailView } from "@/features/admin/support-view";
import { requireSession } from "@/server/guard";
import { getSupportTicket, isTicketId } from "@/server/support-api";

export const metadata: Metadata = { title: "Support report" };

export default async function AdminSupportDetailPage({ params }: PageProps<"/admin/support/[id]">) {
  await connection();
  const session = await requireSession();
  const { id } = await params;
  if (!isTicketId(id)) notFound();

  const result = await getSupportTicket(session.accessToken, id);
  if (!result.ok) notFound();
  return <SupportDetailView item={result.value} />;
}
