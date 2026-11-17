import { pageMetadata } from "@/features/marketing/page-metadata";
import { PricingView } from "@/features/marketing/pricing/pricing-view";
import { track } from "@/server/analytics";

export const metadata = pageMetadata({
  title: "Pricing",
  description:
    "JobTrigger is free for one server. Pro adds every tool, unlimited servers and the widget.",
  path: "/pricing",
});

// P20-30: `pricing_view` is one event per visit, so the page has to render
// per request — prerendered, it would count builds instead of readers.
export const dynamic = "force-dynamic";

export default function PricingPage() {
  void track("pricing_view");
  return <PricingView />;
}
