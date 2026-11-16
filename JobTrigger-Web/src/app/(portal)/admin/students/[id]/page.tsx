import type { Metadata } from "next";
import { connection } from "next/server";
import { notFound } from "next/navigation";

import { StudentDetailView } from "@/features/admin/students-view";
import { getStudentApplication, isStudentId } from "@/server/admin-students-api";
import { requireSession } from "@/server/guard";

export const metadata: Metadata = { title: "Student application" };

export default async function AdminStudentPage({ params }: PageProps<"/admin/students/[id]">) {
  await connection();
  const session = await requireSession();
  const { id } = await params;
  if (!isStudentId(id)) notFound();

  const result = await getStudentApplication(session.accessToken, id);
  if (!result.ok) notFound();
  return <StudentDetailView item={result.value} />;
}
