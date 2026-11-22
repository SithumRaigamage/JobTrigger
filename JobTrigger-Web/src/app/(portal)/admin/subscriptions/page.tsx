import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { connection } from "next/server";

import { AdminTabs } from "@/features/admin/admin-tabs";
import { PLAN_FILTERS, SubscriptionsView } from "@/features/admin/subscriptions-view";
import type { AdminPlanFilter } from "@/domain/admin-subscription";
import { listAdminSubscriptions } from "@/server/admin-subscriptions-api";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Subscriptions" };

const first = (value: string | string[] | undefined) =>
  (Array.isArray(value) ? value[0] : value) ?? "";

export default async function AdminSubscriptionsPage({
  searchParams,
}: PageProps<"/admin/subscriptions">) {
  await connection();
  const session = await requireSession();
  const params = await searchParams;
  const requested = first(params.plan);
  const plan: AdminPlanFilter = PLAN_FILTERS.find((filter) => filter.id === requested)?.id ?? "all";
  const q = first(params.q).trim().slice(0, 100);

  const result = await listAdminSubscriptions(session.accessToken, { plan, q });
  // A non-admin gets the backend's plain 404: show ours, so the page never
  // reveals that an admin area exists.
  if (!result.ok && (result.failure.kind === "notFound" || result.failure.kind === "auth")) {
    notFound();
  }
  return (
    <>
      <AdminTabs current="subscriptions" />
      <SubscriptionsView
        items={result.ok ? result.value.items : []}
        codes={result.ok ? result.value.codes : []}
        failure={result.ok ? null : result.failure}
        plan={plan}
        q={q}
        notice={first(params.notice)}
      />
    </>
  );
}
