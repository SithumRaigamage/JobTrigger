import type { Metadata } from "next";
import { connection } from "next/server";

import { SupportView } from "@/features/marketing/support/support-view";
import { getAppInfo } from "@/server/app-info";

export const metadata: Metadata = {
  title: "Support",
  description: "Answers to common JobTrigger setup problems, and how to reach support.",
};

export default async function SupportPage() {
  // Calls the backend: wait for a request (docs/web-architecture.md §5).
  await connection();
  const appInfo = await getAppInfo();
  return <SupportView supportEmail={appInfo?.supportEmail ?? null} />;
}
