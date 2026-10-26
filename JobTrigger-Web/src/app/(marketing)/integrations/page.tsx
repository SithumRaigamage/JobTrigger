import { connection } from "next/server";

import { pageMetadata } from "@/features/marketing/page-metadata";
import { IntegrationsView } from "@/features/marketing/integrations/integrations-view";
import { getAppInfo } from "@/server/app-info";

export const metadata = pageMetadata({
  title: "Integrations",
  description:
    "Jenkins, GitHub Actions and SonarQube in JobTrigger: what works today, and what's coming.",
  path: "/integrations",
});

export default async function IntegrationsPage() {
  // Pages render alongside the root layout, so its connection() doesn't stop
  // `next build` running this body; wait for a request before calling the
  // backend (docs/web-architecture.md §5).
  await connection();
  const appInfo = await getAppInfo();
  return <IntegrationsView supportEmail={appInfo?.supportEmail ?? null} />;
}
