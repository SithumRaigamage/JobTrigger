import type { Metadata } from "next";
import { connection } from "next/server";
import { notFound } from "next/navigation";

import { StudentsView, STATUS_FILTERS } from "@/features/admin/students-view";
import { listStudents, type AdminStatusFilter } from "@/server/admin-students-api";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Student applications" };

const first = (value: string | string[] | undefined) =>
  (Array.isArray(value) ? value[0] : value) ?? "";

export default async function AdminStudentsPage({ searchParams }: PageProps<"/admin/students">) {
  await connection();
  const session = await requireSession();
  const params = await searchParams;
  const requested = first(params.status);
  const status: AdminStatusFilter =
    STATUS_FILTERS.find((filter) => filter.id === requested)?.id ?? "pending";
  const q = first(params.q).trim().slice(0, 100);

  const result = await listStudents(session.accessToken, { status, q });
  // The backend answers a non-admin with its plain 404: show ours, so the
  // page doesn't reveal that an admin area exists (SP-51).
  if (!result.ok && (result.failure.kind === "notFound" || result.failure.kind === "auth")) {
    notFound();
  }
  return (
    <StudentsView
      items={result.ok ? result.value : []}
      failure={result.ok ? null : result.failure}
      status={status}
      q={q}
      notice={first(params.notice)}
    />
  );
}
