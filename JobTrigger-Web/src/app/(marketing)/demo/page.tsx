import { DemoView } from "@/features/marketing/demo/demo-view";
import { pageMetadata } from "@/features/marketing/page-metadata";

export const metadata = pageMetadata({
  title: "Portal demo",
  description:
    "A read-only preview of the JobTrigger setup portal with sample servers. No account needed.",
  path: "/demo",
});

// Static on purpose: no cookies, no session, no backend call.
export default function DemoPage() {
  return <DemoView />;
}
