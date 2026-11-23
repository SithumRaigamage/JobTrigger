import type { Metadata } from "next";
import { connection } from "next/server";
import { notFound } from "next/navigation";

import { AdminTabs } from "@/features/admin/admin-tabs";
import { STATUS_FILTERS, SupportQueueView } from "@/features/admin/support-view";
import { listSupportTickets, type SupportStatusFilter } from "@/server/support-api";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Support reports" };

const first = (value: string | string[] | undefined) =>
  (Array.isArray(value) ? value[0] : value) ?? "";

export default async function AdminSupportPage({ searchParams }: PageProps<"/admin/support">) {
  await connection();
  const session = await requireSession();
  const params = await searchParams;
  const requested = first(params.status);
  const status: SupportStatusFilter =
    STATUS_FILTERS.find((filter) => filter.id === requested)?.id ?? "open";

  const result = await listSupportTickets(session.accessToken, status);
  // The backend answers a non-admin with its plain 404: show ours, so the
  // page doesn't reveal that an admin area exists (US-SUP-04/07).
  if (!result.ok && (result.failure.kind === "notFound" || result.failure.kind === "auth")) {
    notFound();
  }
  return (
    <>
      <AdminTabs current="support" />
      <SupportQueueView
        items={result.ok ? result.value : []}
        failure={result.ok ? null : result.failure}
        status={status}
      />
    </>
  );
}
