import { pageMetadata } from "@/features/marketing/page-metadata";
import { PricingView } from "@/features/marketing/pricing/pricing-view";

export const metadata = pageMetadata({
  title: "Pricing",
  description:
    "JobTrigger is free for one server. Pro adds every tool, unlimited servers and the widget.",
  path: "/pricing",
});

export default function PricingPage() {
  return <PricingView />;
}
