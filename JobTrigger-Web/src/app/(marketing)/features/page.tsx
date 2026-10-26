import { pageMetadata } from "@/features/marketing/page-metadata";
import { FeaturesView } from "@/features/marketing/features/features-view";

export const metadata = pageMetadata({
  title: "Features",
  description:
    "Trigger Jenkins jobs with any parameter, follow live logs, see why builds fail, and get notified when they finish.",
  path: "/features",
});

export default function FeaturesPage() {
  return <FeaturesView />;
}
