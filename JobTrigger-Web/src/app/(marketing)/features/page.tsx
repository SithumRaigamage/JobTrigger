import type { Metadata } from "next";

import { FeaturesView } from "@/features/marketing/features/features-view";

export const metadata: Metadata = {
  title: "Features",
  description:
    "Trigger Jenkins jobs with any parameter, follow live logs, see why builds fail, and get notified when they finish.",
};

export default function FeaturesPage() {
  return <FeaturesView />;
}
